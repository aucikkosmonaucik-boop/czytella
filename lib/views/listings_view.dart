import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../providers/czytella_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/location_filter_sheet.dart';
import 'create_listing_dialog.dart';

class ListingsView extends StatelessWidget {
  const ListingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CzytellaProvider>();
    final listings = provider.filteredListings;

    final hasActiveLocationFilter =
        provider.radiusFilterKm != null || provider.selectedCityFilter != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Search & Location indicator
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book, size: 22, color: Color(0xFF2E7D32)),
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
                      Text(
                        'Twoja lokalizacja: ${provider.currentCity}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
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
                                  onPressed: () => provider.setSearchQuery(''),
                                )
                              : null,
                          border: InputBorder.none,
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
                          label: Text(provider.selectedCityFilter ?? 'Miasto: Wszystkie'),
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
                            onPressed: () => provider.resetFilters(),
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

          // Subheader: Result Count & Active Filters summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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

          // Listings List
          if (listings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context, provider),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return ListingCard(listing: listings[index]);
                },
                childCount: listings.length,
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
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => const CreateListingDialog(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, CzytellaProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_outlined,
                size: 48,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [
                if (provider.radiusFilterKm != null)
                  FilledButton.tonal(
                    onPressed: () => provider.setRadiusFilter(25.0),
                    child: const Text('Zwiększ promień do 25 km'),
                  ),
                OutlinedButton(
                  onPressed: () => provider.resetFilters(),
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
