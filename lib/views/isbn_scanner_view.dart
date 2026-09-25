import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../models/wishlist_book.dart';
import '../models/listing.dart';
import '../providers/czytella_provider.dart';
import '../services/isbn_lookup_service.dart';

enum ScannerTargetMode {
  general,
  myBooks,
  wishlist,
}

class IsbnScannerView extends StatefulWidget {
  final ScannerTargetMode targetMode;

  const IsbnScannerView({
    super.key,
    this.targetMode = ScannerTargetMode.general,
  });

  @override
  State<IsbnScannerView> createState() => _IsbnScannerViewState();
}

class _IsbnScannerViewState extends State<IsbnScannerView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final TextEditingController _isbnTextController = TextEditingController();
  bool _isTorchOn = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _isbnTextController.dispose();
    super.dispose();
  }

  Future<void> _processIsbn(String rawIsbn) async {
    final cleanIsbn = IsbnLookupService.normalizeIsbn(rawIsbn);
    if (cleanIsbn.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final book = await IsbnLookupService.lookupIsbn(cleanIsbn);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (book != null) {
        _showBookResultSheet(book);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie znaleziono książki o podanym numerze ISBN.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Skaner kodów ISBN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
            },
            tooltip: 'Latarka',
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white12,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.targetMode == ScannerTargetMode.wishlist
                        ? 'Zeskanuj kod kreskowy książki, której szukasz'
                        : widget.targetMode == ScannerTargetMode.myBooks
                            ? 'Zeskanuj kod z tylnej okładki książki, którą posiadasz'
                            : 'Skieruj obiektyw na kod kreskowy ISBN z tyłu książki',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Viewfinder Camera Area
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera viewfinder backdrop
                Container(
                  color: Colors.grey.shade900,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 72,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Podgląd kamery / skanera',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Barcode Target Framing Box
                Container(
                  width: 280,
                  height: 170,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isLoading ? Colors.amber : Colors.greenAccent,
                      width: 2.5,
                    ),
                  ),
                ),

                // Animated Laser Line
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Positioned(
                      top: MediaQuery.of(context).size.height * 0.18 +
                          (_animController.value * 140),
                      child: Container(
                        width: 260,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Loading overlay
                if (_isLoading)
                  Container(
                    width: 280,
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.amber),
                        SizedBox(height: 12),
                        Text(
                          'Pobieranie danych książki...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Barcode Testing & Manual Input Controls
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preset Barcode Tapper for Quick Demo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Przykładowe kody ISBN do testu:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Dotknij, aby zeskanować',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: IsbnLookupService.demoIsbns.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = IsbnLookupService.demoIsbns[index];
                      return ActionChip(
                        avatar: const Icon(Icons.qr_code, size: 16),
                        label: Text('${item.title} (${item.author.split(' ').last})'),
                        onPressed: () => _processIsbn(item.isbn),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Manual ISBN input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _isbnTextController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Wpisz ISBN np. 9788375780635',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          prefixIcon: const Icon(Icons.keyboard, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      onPressed: () {
                        if (_isbnTextController.text.trim().isNotEmpty) {
                          _processIsbn(_isbnTextController.text.trim());
                        }
                      },
                      child: const Text('Szukaj'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBookResultSheet(Book book) {
    final provider = context.read<CzytellaProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Book Card Preview
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 75,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.book, size: 36),
                        )
                      : const Icon(Icons.book, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'Pomyślnie zeskanowano!',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ISBN: ${book.isbn}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Choice 1: Add to User Shelf (Tab 1: Moje książki na wymianę/sprzedaż)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.library_books, color: Colors.teal),
              ),
              title: const Text(
                'Dodaj do: Moje książki (Wymiana/Sprzedaż)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Trafi do Twojej półki książek gotowych do wymiany',
                style: TextStyle(fontSize: 11),
              ),
              onTap: () {
                provider.addUserBook(
                  UserBook(
                    id: 'ub_${DateTime.now().millisecondsSinceEpoch}',
                    book: book,
                    type: UserBookType.both,
                    price: 25.0,
                  ),
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dodano "${book.title}" do Twojej półki!'),
                  ),
                );
              },
            ),

            // Action Choice 2: Add to Wishlist (Tab 2: Książki których szukam)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Colors.pink),
              ),
              title: const Text(
                'Dodaj do: Książki których szukam (Lista życzeń)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Czytella powiadomi Cię, gdy ktoś w okolicy wystawi ten tytuł',
                style: TextStyle(fontSize: 11),
              ),
              onTap: () {
                provider.addWishlistBook(
                  WishlistBook(
                    id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                    isbn: book.isbn,
                    title: book.title,
                    author: book.author,
                    coverUrl: book.coverUrl,
                    priority: WishlistPriority.high,
                  ),
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Dodano "${book.title}" do listy książek, których szukasz!'),
                  ),
                );
              },
            ),

            // Action Choice 3: Create public marketplace listing directly
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign, color: Colors.amber),
              ),
              title: const Text(
                'Wystaw od razu jako ogłoszenie',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Opublikuj ofertę dla czytelników w Twoim mieście',
                style: TextStyle(fontSize: 11),
              ),
              onTap: () {
                provider.createDirectListing(
                  book: book,
                  type: ListingType.both,
                  price: 25.0,
                  exchangePreferences: 'Chętnie wymienię na inną ciekawą pozycję',
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Wystawiono ogłoszenie dla "${book.title}"!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
