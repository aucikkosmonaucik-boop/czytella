import 'package:flutter/material.dart';
import '../models/book.dart';

class BookCoverWidget extends StatelessWidget {
  final Book book;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const BookCoverWidget({
    super.key,
    required this.book,
    this.width = 75,
    this.height = 110,
    this.borderRadius,
    this.boxShadow,
  });

  Color _getCoverThemeColor(String title) {
    const palette = [
      Color(0xFF1E5128), // Czytella forest green
      Color(0xFF1B365D), // Midnight navy
      Color(0xFF5A1827), // Deep burgundy
      Color(0xFF2C3E50), // Classic slate
      Color(0xFF4A3525), // Leather brown
      Color(0xFF2E4057), // Steel blue
    ];
    int hash = 0;
    for (int i = 0; i < title.length; i++) {
      hash = (hash * 31 + title.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);
    final themeColor = _getCoverThemeColor(book.title);

    // Normalize URL - add default=false to openlibrary to avoid transparent 43-byte gifs
    String? effectiveUrl = book.coverUrl;
    if (effectiveUrl != null &&
        effectiveUrl.contains('openlibrary.org') &&
        !effectiveUrl.contains('default=false')) {
      effectiveUrl = effectiveUrl.contains('?')
          ? '$effectiveUrl&default=false'
          : '$effectiveUrl?default=false';
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(1, 2),
              ),
            ],
      ),
      clipBehavior: Clip.antiAlias,
      child: effectiveUrl != null && effectiveUrl.isNotEmpty
          ? Image.network(
              effectiveUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildStylizedJacket(themeColor),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: width,
                  height: height,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  ),
                );
              },
            )
          : _buildStylizedJacket(themeColor),
    );
  }

  Widget _buildStylizedJacket(Color themeColor) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColor,
            Color.alphaBlend(Colors.black.withOpacity(0.35), themeColor),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Left spine binding line
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: width > 90 ? 7 : 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.white.withOpacity(0.1),
                    Colors.black.withOpacity(0.25),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
              width > 90 ? 12 : 8,
              width > 90 ? 10 : 6,
              width > 90 ? 8 : 6,
              width > 90 ? 10 : 6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white.withOpacity(0.85),
                  size: width > 90 ? 20 : 14,
                ),
                const Spacer(),
                Text(
                  book.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width > 90 ? 12 : 9.5,
                    height: 1.15,
                  ),
                  maxLines: width > 90 ? 4 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  book.author,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: width > 90 ? 10 : 7.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
