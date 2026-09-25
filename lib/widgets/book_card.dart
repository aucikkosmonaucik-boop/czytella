import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../models/book.dart';
import '../providers/czytella_provider.dart';
import '../services/distance_service.dart';
import '../views/listing_detail_screen.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;

  const ListingCard({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CzytellaProvider>();
    final distanceKm = provider.getDistanceFromUser(listing);
    final isNearby = distanceKm <= 5.0;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isNearby
            ? BorderSide(color: Colors.green.shade400, width: 1.2)
            : BorderSide(color: Colors.grey.shade200),
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
                    Row(
                      children: [
                        _buildTypeBadge(listing, theme),
                        const SizedBox(width: 6),
                        if (isNearby)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.green.shade300, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on,
                                    size: 11, color: Colors.green.shade800),
                                Text(
                                  '< 5 km',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
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
                        color: Colors.grey.shade700,
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
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            listing.book.condition.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade800,
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
                                color: Colors.grey.shade600,
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
                                ? Colors.green.shade700
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
                                  ? Colors.green.shade800
                                  : Colors.grey.shade700,
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
    return Container(
      width: 80,
      height: 115,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: book.coverUrl != null && book.coverUrl!.isNotEmpty
          ? Image.network(
              book.coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackCover(book),
            )
          : _buildFallbackCover(book),
    );
  }

  Widget _buildFallbackCover(Book book) {
    return Container(
      padding: const EdgeInsets.all(6),
      color: const Color(0xFF2C3E50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, color: Colors.white70, size: 28),
          const SizedBox(height: 4),
          Text(
            book.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(Listing listing, ThemeData theme) {
    if (listing.type == ListingType.exchange) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.indigo.shade200),
        ),
        child: Text(
          'Wymiana',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        ),
      );
    } else if (listing.type == ListingType.sale) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Text(
          'Sprzedaż: ${listing.price?.toStringAsFixed(0) ?? "--"} zł',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Text(
          'Wymiana / ${listing.price?.toStringAsFixed(0) ?? "--"} zł',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade800,
          ),
        ),
      );
    }
  }
}
