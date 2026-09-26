import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../models/book.dart';
import '../providers/czytella_provider.dart';
import '../services/distance_service.dart';
import '../views/listing_detail_screen.dart';
import 'book_cover_widget.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final EdgeInsetsGeometry? margin;

  const ListingCard({
    super.key,
    required this.listing,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CzytellaProvider>();
    final distanceKm = provider.getDistanceFromUser(listing);
    final isNearby = distanceKm <= 5.0;

    return Card(
      elevation: 1.5,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isNearby
            ? BorderSide(
                color: theme.brightness == Brightness.dark
                    ? Colors.green.shade600
                    : Colors.green.shade400,
                width: 1.2)
            : BorderSide(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ListingDetailScreen(listing: listing),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              _buildBookCover(listing.book),
              const SizedBox(width: 14),

              // Book Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top badges row: Type + Nearby indicator
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildTypeBadge(listing, theme),
                        if (isNearby)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.green.shade900.withOpacity(0.3)
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.green.shade800
                                      : Colors.green.shade300,
                                  width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on,
                                    size: 11,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.green.shade300
                                        : Colors.green.shade800),
                                Text(
                                  '< 5 km',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.green.shade300
                                        : Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      listing.book.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Author
                    Text(
                      listing.book.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Condition + Category
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? theme.colorScheme.surfaceContainerHighest
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            listing.book.condition.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (listing.book.categories.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              listing.book.categories.first,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Location, distance & seller
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 13,
                            color: isNearby
                                ? (theme.brightness == Brightness.dark
                                    ? Colors.green.shade400
                                    : Colors.green.shade700)
                                : Colors.blueGrey),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${listing.city}${listing.district != null ? ", ${listing.district!.split(" ").first}" : ""} • ${DistanceService.formatDistance(distanceKm)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isNearby ? FontWeight.w600 : FontWeight.normal,
                              color: isNearby
                                  ? (theme.brightness == Brightness.dark
                                      ? Colors.green.shade300
                                      : Colors.green.shade800)
                                  : (theme.brightness == Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  Widget _buildBookCover(Book book) {
    return BookCoverWidget(
      book: book,
      width: 80,
      height: 115,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildTypeBadge(Listing listing, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (listing.type == ListingType.exchange) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? Colors.indigo.shade900.withOpacity(0.4) : Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isDark ? Colors.indigo.shade800 : Colors.indigo.shade200),
        ),
        child: Text(
          'Wymiana',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.indigo.shade200 : Colors.indigo.shade700,
          ),
        ),
      );
    } else if (listing.type == ListingType.sale) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? Colors.teal.shade900.withOpacity(0.4) : Colors.teal.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isDark ? Colors.teal.shade800 : Colors.teal.shade200),
        ),
        child: Text(
          'Sprzedaż: ${listing.price?.toStringAsFixed(0) ?? "--"} zł',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.teal.shade200 : Colors.teal.shade800,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? Colors.amber.shade900.withOpacity(0.4) : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isDark ? Colors.amber.shade800 : Colors.amber.shade300),
        ),
        child: Text(
          'Wymiana / ${listing.price?.toStringAsFixed(0) ?? "--"} zł',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.amber.shade200 : Colors.brown.shade800,
          ),
        ),
      );
    }
  }
}
