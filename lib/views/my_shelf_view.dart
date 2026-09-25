import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../models/wishlist_book.dart';
import '../models/listing.dart';
import '../providers/czytella_provider.dart';
import '../services/distance_service.dart';
import 'listing_detail_screen.dart';
import 'add_book_dialog.dart';
import 'isbn_scanner_view.dart';

class MyShelfView extends StatefulWidget {
  final int initialTabIndex;

  const MyShelfView({super.key, this.initialTabIndex = 0});

  @override
  State<MyShelfView> createState() => _MyShelfViewState();
}

class _MyShelfViewState extends State<MyShelfView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CzytellaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Moja Półka Czytelnika',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.swap_horizontal_circle_outlined, size: 20),
              text: 'Wymiana / Sprzedaż (${provider.userBooks.length})',
            ),
            Tab(
              icon: const Icon(Icons.favorite_outline, size: 20),
              text: 'Książki których szukam (${provider.wishlist.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Moje książki na wymianę/sprzedaż
          _buildMyBooksTab(context, provider),

          // Tab 2: Książki których szukam (Lista życzeń)
          _buildWishlistTab(context, provider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(
          _tabController.index == 0
              ? 'Zeskanuj na półkę'
              : 'Zeskanuj do życzeń',
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => IsbnScannerView(
                targetMode: _tabController.index == 0
                    ? ScannerTargetMode.myBooks
                    : ScannerTargetMode.wishlist,
              ),
            ),
          );
        },
      ),
    );
  }

  // TAB 1: Moje książki na wymianę/sprzedaż
  Widget _buildMyBooksTab(BuildContext context, CzytellaProvider provider) {
    final books = provider.userBooks;

    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.library_books,
                    size: 48, color: Colors.blue),
              ),
              const SizedBox(height: 18),
              const Text(
                'Brak książek na wymianę lub sprzedaż',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Dodaj książki, które przeczytałeś i chcesz wymienić na inne lub sprzedać lokalnym czytelnikom.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Zeskanuj kod ISBN aparatem'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const IsbnScannerView(
                        targetMode: ScannerTargetMode.myBooks,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Informational header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade100),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_stories, color: Colors.teal, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Twoje książki widoczne są w Twoim profilu. Możesz je w każdej chwili wystawić jako publiczne ogłoszenie w Czytelli.',
                  style: TextStyle(fontSize: 12, color: Colors.teal.shade900),
                ),
              ),
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) => const AddBookDialog(isWishlist: false),
                  );
                },
                child: const Text('+ Dodaj ręcznie'),
              ),
            ],
          ),
        ),

        // List of books
        ...books.map((userBook) => _buildUserBookCard(context, provider, userBook)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildUserBookCard(
      BuildContext context, CzytellaProvider provider, UserBook ub) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: ub.isListed ? Colors.green.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Container(
              width: 65,
              height: 95,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey.shade200,
              ),
              clipBehavior: Clip.antiAlias,
              child: ub.book.coverUrl != null && ub.book.coverUrl!.isNotEmpty
                  ? Image.network(
                      ub.book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.book),
                    )
                  : const Icon(Icons.book),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ub.type == UserBookType.forExchange
                              ? Colors.indigo.shade50
                              : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ub.type.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ub.type == UserBookType.forExchange
                                ? Colors.indigo.shade800
                                : Colors.teal.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (ub.price != null)
                        Text(
                          '${ub.price!.toStringAsFixed(0)} zł',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const Spacer(),
                      // Listed badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ub.isListed
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: ub.isListed
                                ? Colors.green.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          ub.isListed ? '🟢 W ogłoszeniach' : '⚪ Tylko na półce',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: ub.isListed
                                ? Colors.green.shade800
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ub.book.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ub.book.author,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stan: ${ub.book.condition.label}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),

                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!ub.isListed)
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            provider.publishUserBookAsListing(
                              ub,
                              price: ub.price,
                              type: ub.type == UserBookType.forExchange
                                  ? ListingType.exchange
                                  : ub.type == UserBookType.forSale
                                      ? ListingType.sale
                                      : ListingType.both,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opublikowano ogłoszenie w Czytelli!'),
                              ),
                            );
                          },
                          child: const Text('Wystaw ogłoszenie',
                              style: TextStyle(fontSize: 11)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        onPressed: () {
                          provider.removeUserBook(ub.id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: Książki których szukam (Lista życzeń)
  Widget _buildWishlistTab(BuildContext context, CzytellaProvider provider) {
    final wishes = provider.wishlist;

    if (wishes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_outline,
                    size: 48, color: Colors.redAccent),
              ),
              const SizedBox(height: 18),
              const Text(
                'Twoja lista życzeń jest pusta',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Dodaj książki, na które polujesz. System Czytella automatycznie powiadomi Cię, gdy ktoś w okolicy wystawi ten tytuł!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Dodaj tytuł do listy życzeń'),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) => const AddBookDialog(isWishlist: true),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Wishlist Radar Header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade100),
          ),
          child: Row(
            children: [
              const Icon(Icons.radar, color: Colors.purple, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Radar Czytelli automatycznie sprawdza ogłoszenia w Twoim mieście i informuje o pasujących ofertach.',
                  style: TextStyle(fontSize: 12, color: Colors.purple.shade900),
                ),
              ),
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) => const AddBookDialog(isWishlist: true),
                  );
                },
                child: const Text('+ Dodaj'),
              ),
            ],
          ),
        ),

        // List of Wishlist items
        ...wishes.map((wish) => _buildWishlistCard(context, provider, wish)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildWishlistCard(
      BuildContext context, CzytellaProvider provider, WishlistBook wish) {
    final theme = Theme.of(context);
    final matches = provider.getMatchesForWishlist(wish);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: matches.isNotEmpty
              ? Colors.green.shade400
              : Colors.grey.shade200,
          width: matches.isNotEmpty ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                Container(
                  width: 60,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey.shade200,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: wish.coverUrl != null && wish.coverUrl!.isNotEmpty
                      ? Image.network(
                          wish.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.bookmark),
                        )
                      : const Icon(Icons.bookmark),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildPriorityBadge(wish.priority),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.grey),
                            onPressed: () => provider.removeWishlistBook(wish.id),
                          ),
                        ],
                      ),
                      Text(
                        wish.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        wish.author,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (wish.maxBudget != null)
                        Text(
                          'Maksymalny budżet: do ${wish.maxBudget!.toStringAsFixed(0)} zł',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (wish.notes != null && wish.notes!.isNotEmpty)
                        Text(
                          'Notatka: "${wish.notes}"',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // MATCH RADAR ALERT: If a community offer exists for this book!
            if (matches.isNotEmpty) ...[
              const Divider(height: 18),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Znaleziono ${matches.length} pasującą ofertę!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.green.shade900,
                            ),
                          ),
                          Text(
                            'Użytkownik ${matches.first.sellerName} (${DistanceService.formatDistance(provider.getDistanceFromUser(matches.first))})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) =>
                                ListingDetailScreen(listing: matches.first),
                          ),
                        );
                      },
                      child: const Text('Zobacz',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(WishlistPriority priority) {
    Color color;
    switch (priority) {
      case WishlistPriority.high:
        color = Colors.red.shade700;
        break;
      case WishlistPriority.medium:
        color = Colors.orange.shade800;
        break;
      case WishlistPriority.low:
        color = Colors.blueGrey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Priorytet: ${priority.label}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
