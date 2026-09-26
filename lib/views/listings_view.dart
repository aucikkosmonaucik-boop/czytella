import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../providers/czytella_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/desktop_footer.dart';
import '../widgets/location_filter_sheet.dart';
import '../widgets/mobile_app_banner.dart';
import 'create_listing_dialog.dart';
import 'auth_dialog.dart';
import 'user_profile_dialog.dart';

class ListingsView extends StatefulWidget {
  final Function(int)? onNavigate;

  const ListingsView({super.key, this.onNavigate});

  @override
  State<ListingsView> createState() => _ListingsViewState();
}

class _ListingsViewState extends State<ListingsView> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _popularCategories = const [
    'Wszystkie',
    'Kryminał',
    'Fantastyka',
    'Literatura piękna',
    'Sci-Fi',
    'Klasyka',
    'Reportaż',
    'Biografia',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CzytellaProvider>().refreshListings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CzytellaProvider>();
    final listings = provider.filteredListings;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    final hasActiveLocationFilter =
        provider.radiusFilterKm != null || provider.selectedCityFilter != null;

    if (isDesktop) {
      return _buildDesktopLayout(context, theme, provider, listings);
    } else {
      return _buildMobileLayout(
          context, theme, provider, listings, hasActiveLocationFilter);
    }
  }

  // ==========================================
  // DESKTOP PC MODERN LAYOUT
  // ==========================================
  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    CzytellaProvider provider,
    List<Listing> listings,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth >= 1150 ? 3 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F0),
      body: CustomScrollView(
        slivers: [
          // Banner for Mobile APK release
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: const MobileAppBanner(),
            ),
          ),

          // Modern Desktop Filter Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar + City picker
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => provider.setSearchQuery(val),
                              decoration: InputDecoration(
                                hintText:
                                    'Szukaj po tytule, autorze, kategorii lub numerze ISBN...',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                prefixIcon: const Icon(Icons.search,
                                    size: 22, color: Color(0xFF1E5128)),
                                suffixIcon: provider.searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          provider.setSearchQuery('');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // City & Radius sheet trigger button
                        InkWell(
                          onTap: () => LocationFilterSheet.show(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.place,
                                    size: 18, color: Colors.green.shade800),
                                const SizedBox(width: 6),
                                Text(
                                  provider.selectedCityFilter ??
                                      'Miasto: ${provider.currentCity}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down,
                                    size: 18, color: Colors.green),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filter row: Type tabs & Radius chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Deal Type: All / Exchange / Sale
                        _buildFilterPill(
                          label: 'Wszystkie (${provider.allListings.length})',
                          isSelected: provider.typeFilter == null,
                          onTap: () => provider.setTypeFilter(null),
                        ),
                        _buildFilterPill(
                          label: '🔄 Na wymianę',
                          isSelected: provider.typeFilter == ListingType.exchange,
                          onTap: () => provider.setTypeFilter(
                            provider.typeFilter == ListingType.exchange
                                ? null
                                : ListingType.exchange,
                          ),
                        ),
                        _buildFilterPill(
                          label: '💰 Na sprzedaż',
                          isSelected: provider.typeFilter == ListingType.sale,
                          onTap: () => provider.setTypeFilter(
                            provider.typeFilter == ListingType.sale
                                ? null
                                : ListingType.sale,
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade300,
                        ),

                        // Radius quick filters
                        FilterChip(
                          avatar: const Icon(Icons.radar, size: 16),
                          label: const Text('W promieniu 5 km'),
                          selected: provider.radiusFilterKm == 5.0,
                          selectedColor: const Color(0xFFD6E8D5),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: provider.radiusFilterKm == 5.0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: provider.radiusFilterKm == 5.0
                                ? const Color(0xFF1E5128)
                                : Colors.grey.shade800,
                          ),
                          onSelected: (selected) {
                            provider.setRadiusFilter(selected ? 5.0 : null);
                          },
                        ),
                        FilterChip(
                          label: const Text('Do 10 km'),
                          selected: provider.radiusFilterKm == 10.0,
                          selectedColor: const Color(0xFFD6E8D5),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: provider.radiusFilterKm == 10.0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: provider.radiusFilterKm == 10.0
                                ? const Color(0xFF1E5128)
                                : Colors.grey.shade800,
                          ),
                          onSelected: (selected) {
                            provider.setRadiusFilter(selected ? 10.0 : null);
                          },
                        ),
                        FilterChip(
                          label: const Text('Do 25 km'),
                          selected: provider.radiusFilterKm == 25.0,
                          selectedColor: const Color(0xFFD6E8D5),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: provider.radiusFilterKm == 25.0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: provider.radiusFilterKm == 25.0
                                ? const Color(0xFF1E5128)
                                : Colors.grey.shade800,
                          ),
                          onSelected: (selected) {
                            provider.setRadiusFilter(selected ? 25.0 : null);
                          },
                        ),

                        // Clear filters button
                        if (provider.radiusFilterKm != null ||
                            provider.typeFilter != null ||
                            provider.selectedCityFilter != null ||
                            provider.categoryFilter != null ||
                            provider.searchQuery.isNotEmpty)
                          ActionChip(
                            avatar: const Icon(Icons.close, size: 14),
                            label: const Text('Wyczyść filtry'),
                            onPressed: () {
                              _searchController.clear();
                              provider.resetFilters();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category chips
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _popularCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final cat = _popularCategories[idx];
                          final isAll = cat == 'Wszystkie';
                          final isSelected = isAll
                              ? provider.categoryFilter == null
                              : provider.categoryFilter == cat;

                          return ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.green.shade100,
                            onSelected: (selected) {
                              if (isAll) {
                                provider.setCategoryFilter(null);
                              } else {
                                provider.setCategoryFilter(selected ? cat : null);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Subheader: Result Count & Active Filters Summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                children: [
                  Text(
                    'Oferty społeczności (${listings.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  if (provider.radiusFilterKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        '📍 Promień: ${provider.radiusFilterKm!.toInt()} km od ${provider.currentCity}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Grid of Listings
          if (listings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context, provider),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 185,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return ListingCard(
                      listing: listings[index],
                      margin: EdgeInsets.zero,
                    );
                  },
                  childCount: listings.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 48),
          ),

          // Desktop Footer
          SliverToBoxAdapter(
            child: DesktopFooter(
              onNavigate: widget.onNavigate,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MOBILE RESPONSIVE LAYOUT
  // ==========================================
  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    CzytellaProvider provider,
    List<Listing> listings,
    bool hasActiveLocationFilter,
  ) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Search & Location indicator
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book,
                        size: 22, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    const Text(
                      'Czytella',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => LocationFilterSheet.show(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on,
                          size: 13, color: Colors.green.shade800),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          'Twoja lokalizacja: ${provider.currentCity}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          size: 16, color: Colors.green),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: hasActiveLocationFilter,
                  child: const Icon(Icons.tune),
                ),
                tooltip: 'Filtry i lokalizacja',
                onPressed: () => LocationFilterSheet.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Odśwież ogłoszenia',
                onPressed: () async {
                  await provider.refreshListings();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Zaktualizowano ogłoszenia z bazy danych Railway.'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
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
                    ? 'Mój profil ()'
                    : 'Zaloguj się / Rejestracja',
                onPressed: () {
                  if (provider.isAuthenticated) {
                    UserProfileDialog.show(
                      context,
                      onNavigateToShelf: () => widget.onNavigate?.call(1),
                      onNavigateToListings: () => widget.onNavigate?.call(0),
                    );
                  } else {
                    AuthDialog.show(context);
                  }
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(115),
              child: Column(
                children: [
                  // Search TextField
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => provider.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Szukaj tytułu, autora, ISBN...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: provider.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    provider.setSearchQuery('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Horizontal Quick Filters Bar
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      children: [
                        // Radius 5 km filter (highlighted preset)
                        FilterChip(
                          avatar: const Icon(Icons.radar, size: 16),
                          label: const Text('W promieniu 5 km'),
                          selected: provider.radiusFilterKm == 5.0,
                          selectedColor: Colors.green.shade100,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: provider.radiusFilterKm == 5.0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: provider.radiusFilterKm == 5.0
                                ? Colors.green.shade900
                                : null,
                          ),
                          onSelected: (selected) {
                            provider.setRadiusFilter(selected ? 5.0 : null);
                          },
                        ),
                        const SizedBox(width: 8),

                        // City quick chip
                        ActionChip(
                          avatar: const Icon(Icons.place, size: 16),
                          label: Text(
                              provider.selectedCityFilter ?? 'Miasto: Wszystkie'),
                          onPressed: () => LocationFilterSheet.show(context),
                        ),
                        const SizedBox(width: 8),

                        // Type: Exchange filter
                        FilterChip(
                          label: const Text('Na wymianę'),
                          selected: provider.typeFilter == ListingType.exchange,
                          onSelected: (selected) {
                            provider.setTypeFilter(
                                selected ? ListingType.exchange : null);
                          },
                        ),
                        const SizedBox(width: 8),

                        // Type: Sale filter
                        FilterChip(
                          label: const Text('Na sprzedaż'),
                          selected: provider.typeFilter == ListingType.sale,
                          onSelected: (selected) {
                            provider.setTypeFilter(
                                selected ? ListingType.sale : null);
                          },
                        ),
                        if (hasActiveLocationFilter ||
                            provider.typeFilter != null ||
                            provider.searchQuery.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.close, size: 14),
                            label: const Text('Resetuj filtry'),
                            onPressed: () {
                              _searchController.clear();
                              provider.resetFilters();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),

          // Mobile APK promo banner
          const SliverToBoxAdapter(
            child: MobileAppBanner(),
          ),

          // Subheader: Result Count & Active Filters summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  Text(
                    'Oferty społeczności (${listings.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  if (provider.radiusFilterKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        '📍 Promień: ${provider.radiusFilterKm!.toInt()} km',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Responsive Listings Grid: 1-col on mobile
          if (listings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context, provider),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return ListingCard(
                    listing: listings[index],
                  );
                },
                childCount: listings.length,
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),

          // Mobile Footer
          SliverToBoxAdapter(
            child: DesktopFooter(
              onNavigate: widget.onNavigate,
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Dodaj ogłoszenie'),
        onPressed: () async {
          final provider = context.read<CzytellaProvider>();
          if (!provider.isAuthenticated) {
            final loggedIn = await AuthDialog.show(context);
            if (loggedIn != true || !context.mounted) {
              return;
            }
          }
          if (!context.mounted) {
            return;
          }
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => const CreateListingDialog(),
          );
        },
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E5128) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E5128) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, CzytellaProvider provider) {
    if (provider.allListings.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  size: 44,
                  color: Color(0xFF1E5128),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Brak aktywnych ogłoszeń',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  'Bądź pierwszą osobą, która doda książkę na wymianę lub sprzedaż! Wystaw książkę w kilka sekund i wymieniaj się z sąsiadami.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5128),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Dodaj pierwsze ogłoszenie',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () async {
                  final provider = context.read<CzytellaProvider>();
                  if (!provider.isAuthenticated) {
                    final loggedIn = await AuthDialog.show(context);
                    if (loggedIn != true || !context.mounted) {
                      return;
                    }
                  }
                  if (!context.mounted) {
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) => const CreateListingDialog(),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_outlined,
                size: 44,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Brak ofert w wybranej lokalizacji',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.radiusFilterKm != null
                  ? 'Nie znaleziono książek w promieniu ${provider.radiusFilterKm!.toInt()} km od ${provider.currentCity}. Zwiększ promień lub zmień miasto, aby zobaczyć więcej ogłoszeń.'
                  : 'Brak książek spełniających wybrane kryteria wyszukiwania.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              children: [
                if (provider.radiusFilterKm != null)
                  FilledButton.tonal(
                    onPressed: () => provider.setRadiusFilter(25.0),
                    child: const Text('Zwiększ promień do 25 km'),
                  ),
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    provider.resetFilters();
                  },
                  child: const Text('Wyczyść wszystkie filtry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
