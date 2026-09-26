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
import 'auth_dialog.dart';
import 'user_profile_dialog.dart';
import '../widgets/book_cover_widget.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isDesktop ? 0 : kToolbarHeight,
        automaticallyImplyLeading: false,
        title: isDesktop
            ? null
            : const Text(
                'Moja Półka Czytelnika',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: isDesktop
            ? null
            : [
                IconButton(
                  icon: provider.isAuthenticated
                      ? CircleAvatar(
                          radius: 13,
                          backgroundColor: const Color(0xFF1E5128),
                          child: Text(
                            provider.currentUser!.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const Icon(Icons.person_outline_rounded),
                  tooltip: provider.isAuthenticated
                      ? 'Panel czytelnika'
                      : 'Zaloguj się',
                  onPressed: () {
                    if (provider.isAuthenticated) {
                      UserProfileDialog.show(context);
                    } else {
                      AuthDialog.show(context);
                    }
                  },
                ),
              ],
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
      floatingActionButton: isDesktop
          ? null
          : provider.isAuthenticated
              ? FloatingActionButton.extended(
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
                )
              : FloatingActionButton.extended(
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Zaloguj się'),
                  backgroundColor: const Color(0xFF1E5128),
                  onPressed: () => AuthDialog.show(context),
                ),
    );
  }

  Widget _buildAccountStatusBanner(
      BuildContext context, CzytellaProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (provider.isAuthenticated) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.green.shade900.withOpacity(0.3)
              : Colors.green.shade50.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.green.shade800 : Colors.green.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                provider.currentUser!.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Zalogowano: ${provider.currentUser!.name} (${provider.currentUser!.city})',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.green.shade300 : Colors.green.shade900,
                ),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.settings_outlined,
                  size: 14, color: theme.colorScheme.primary),
              label: Text(
                'Panel',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary),
              ),
              onPressed: () => UserProfileDialog.show(context),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainer
            : const Color(0xFFFBFBFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_sync_outlined,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Zaloguj się, aby zsynchronizować półkę między urządzeniami.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => AuthDialog.show(context),
            child: const Text('Zaloguj się',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequiredScreen(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainer
                    : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 52,
                  color: isDark
                      ? theme.colorScheme.primary
                      : const Color(0xFF1E5128)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.login_rounded),
              label: const Text('Zaloguj się'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E5128),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => AuthDialog.show(context),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => AuthDialog.show(context),
              child: const Text('Nie masz konta? Zarejestruj się'),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: Moje książki na wymianę/sprzedaż
  Widget _buildMyBooksTab(BuildContext context, CzytellaProvider provider) {
    // Niezalogowany użytkownik widzi ekran zachęcający do logowania
    if (!provider.isAuthenticated) {
      return _buildLoginRequiredScreen(
        context,
        icon: Icons.library_books_outlined,
        title: 'Zaloguj się, aby zobaczyć swoją półkę',
        subtitle:
            'Twoja półka jest powiązana z Twoim kontem czytelnika. Zaloguj się, aby dodawać, edytować i usuwać własne książki.',
      );
    }

    final books = provider.userBooks;

    if (books.isEmpty) {
      return Column(
        children: [
          _buildAccountStatusBanner(context, provider),
          Expanded(
            child: Center(
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
      ),
    ),
  ],
);
  }

  return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _buildAccountStatusBanner(context, provider),
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

        // List of books (grid on desktop, list on mobile)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 650) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 520,
                    mainAxisExtent: 175,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, i) => _buildUserBookCard(
                      context, provider, books[i], isGrid: true),
                );
              } else {
                return Column(
                  children: books
                      .map((userBook) =>
                          _buildUserBookCard(context, provider, userBook))
                      .toList(),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _openEditUserBookModal(
      BuildContext context, CzytellaProvider provider, UserBook ub) async {
    final titleCtrl = TextEditingController(text: ub.book.title);
    final authorCtrl = TextEditingController(text: ub.book.author);
    final priceCtrl = TextEditingController(
      text: ub.price != null ? ub.price!.toStringAsFixed(0) : '20',
    );
    final coverCtrl = TextEditingController(text: ub.book.coverUrl ?? '');

    UserBookType selectedType = ub.type;
    BookCondition selectedCondition = ub.book.condition;
    bool isListed = ub.isListed;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (mCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                Row(
                  children: [
                    const Icon(Icons.edit_note,
                        size: 24, color: Color(0xFF1E5128)),
                    const SizedBox(width: 8),
                    const Text(
                      'Edytuj książkę na półce',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Tytuł książki', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Autor', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),

                // Typ oferty
                const Text('Typ oferty:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Wymiana lub sprzedaż'),
                      selected: selectedType == UserBookType.both,
                      selectedColor: const Color(0xFFD6E8D5),
                      onSelected: (_) => setSheetState(
                          () => selectedType = UserBookType.both),
                    ),
                    ChoiceChip(
                      label: const Text('Tylko sprzedaż'),
                      selected: selectedType == UserBookType.forSale,
                      selectedColor: const Color(0xFFD6E8D5),
                      onSelected: (_) => setSheetState(
                          () => selectedType = UserBookType.forSale),
                    ),
                    ChoiceChip(
                      label: const Text('Tylko wymiana'),
                      selected: selectedType == UserBookType.forExchange,
                      selectedColor: const Color(0xFFD6E8D5),
                      onSelected: (_) => setSheetState(
                          () => selectedType = UserBookType.forExchange),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Cena
                if (selectedType != UserBookType.forExchange) ...[
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cena w złotych (PLN)',
                      suffixText: 'zł',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['10', '15', '20', '25', '30', '50'].map((p) {
                      return ActionChip(
                        label: Text('$p zł'),
                        onPressed: () =>
                            setSheetState(() => priceCtrl.text = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Stan
                const Text('Stan książki:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: BookCondition.values.map((cond) {
                    return ChoiceChip(
                      label: Text(cond.label),
                      selected: selectedCondition == cond,
                      selectedColor: const Color(0xFFD6E8D5),
                      onSelected: (_) =>
                          setSheetState(() => selectedCondition = cond),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Wystawione na giełdzie switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Wystawione na publicznej giełdzie'),
                  subtitle: const Text(
                      'Widoczne dla innych czytelników w Twoim mieście',
                      style: TextStyle(fontSize: 11)),
                  value: isListed,
                  activeColor: const Color(0xFF1E5128),
                  onChanged: (val) => setSheetState(() => isListed = val),
                ),
                const SizedBox(height: 8),

                // Cover URL
                TextField(
                  controller: coverCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Link do okładki (URL, opcjonalnie)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 18),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(mCtx),
                      child: const Text('Anuluj'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5128)),
                      onPressed: () {
                        final priceVal = double.tryParse(priceCtrl.text.trim());
                        final updatedBook = ub.book.copyWith(
                          title: titleCtrl.text.trim().isNotEmpty
                              ? titleCtrl.text.trim()
                              : ub.book.title,
                          author: authorCtrl.text.trim().isNotEmpty
                              ? authorCtrl.text.trim()
                              : ub.book.author,
                          condition: selectedCondition,
                          coverUrl: coverCtrl.text.trim().isNotEmpty
                              ? coverCtrl.text.trim()
                              : ub.book.coverUrl,
                        );

                        final updatedUserBook = ub.copyWith(
                          book: updatedBook,
                          type: selectedType,
                          price: selectedType == UserBookType.forExchange
                              ? null
                              : priceVal,
                          isListed: isListed,
                        );

                        provider.updateUserBook(updatedUserBook);
                        Navigator.pop(mCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Zapisano zmiany w książce!')),
                        );
                      },
                      child: const Text('Zapisz zmiany'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserBookCard(
      BuildContext context, CzytellaProvider provider, UserBook ub,
      {bool isGrid = false}) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1.5,
      margin: isGrid
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: ub.isListed ? Colors.green.shade400 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: provider.isAuthenticated
            ? () => _openEditUserBookModal(context, provider, ub)
            : () => AuthDialog.show(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              BookCoverWidget(
                book: ub.book,
                width: 68,
                height: 100,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                        if (ub.price != null && ub.type != UserBookType.forExchange)
                          Text(
                            '${ub.price!.toStringAsFixed(0)} zł',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E5128),
                            ),
                          ),
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
                    const SizedBox(height: 4),
                    Text(
                      'Stan: ${ub.book.condition.label}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),

                    // Actions row — widoczne tylko dla zalogowanego właściciela
                    if (provider.isAuthenticated)
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
                                    content: Text(
                                        'Opublikowano ogłoszenie w Czytelli!'),
                                  ),
                                );
                              },
                              child: const Text('Wystaw ogłoszenie',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edytuj książkę i cenę',
                            onPressed: () =>
                                _openEditUserBookModal(context, provider, ub),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            tooltip: 'Usuń z półki',
                            onPressed: () async {
                              final del = await showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  title: const Text('Usuń książkę z półki?'),
                                  content: Text(
                                    'Czy na pewno chcesz usunąć "${ub.book.title}" ze swojej półki? Jeśli książka była wystawiona jako ogłoszenie, zostanie także zdjęta z giełdy.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dCtx, false),
                                      child: const Text('Anuluj'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      onPressed: () =>
                                          Navigator.pop(dCtx, true),
                                      child: const Text('Usuń'),
                                    ),
                                  ],
                                ),
                              );
                              if (del == true) {
                                provider.removeUserBook(ub.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Usunięto "${ub.book.title}" z półki.'),
                                    ),
                                  );
                                }
                              }
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
      ),
    );
  }


  // TAB 2: Książki których szukam (Lista życzeń)
  Widget _buildWishlistTab(BuildContext context, CzytellaProvider provider) {
    // Niezalogowany użytkownik widzi ekran zachęcający do logowania
    if (!provider.isAuthenticated) {
      return _buildLoginRequiredScreen(
        context,
        icon: Icons.favorite_outline,
        title: 'Zaloguj się, aby zobaczyć listę życzeń',
        subtitle:
            'Lista życzeń jest powiązana z Twoim kontem. Zaloguj się, aby śledzić szukane tytuły i otrzymywać powiadomienia od Radaru Czytelli.',
      );
    }

    final wishes = provider.wishlist;

    if (wishes.isEmpty) {
      return Column(
        children: [
          _buildAccountStatusBanner(context, provider),
          Expanded(
            child: Center(
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
      ),
    ),
  ],
);
  }

  return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _buildAccountStatusBanner(context, provider),
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

        // List of Wishlist items (grid on desktop, list on mobile)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 650) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 520,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: wishes.length,
                  itemBuilder: (context, i) => _buildWishlistCard(
                      context, provider, wishes[i], isGrid: true),
                );
              } else {
                return Column(
                  children: wishes
                      .map((wish) =>
                          _buildWishlistCard(context, provider, wish))
                      .toList(),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildWishlistCard(
      BuildContext context, CzytellaProvider provider, WishlistBook wish,
      {bool isGrid = false}) {
    final theme = Theme.of(context);
    final matches = provider.getMatchesForWishlist(wish);

    return Card(
      elevation: 1,
      margin: isGrid
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 6),
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
                          if (provider.isAuthenticated)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.grey),
                              tooltip: 'Usuń z listy życzeń',
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
