import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../models/chat_message.dart';
import '../providers/czytella_provider.dart';
import '../services/distance_service.dart';
import '../widgets/safe_exchange_badge.dart';
import 'chat_detail_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  final Listing listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CzytellaProvider>();
    final distanceKm = provider.getDistanceFromUser(listing);
    final isNearby = distanceKm <= 5.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły oferty'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Udostępniono ofertę: ${listing.book.title}'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Cover & Main Details Banner
            Container(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Cover
                  Container(
                    width: 110,
                    height: 165,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: listing.book.coverUrl != null &&
                            listing.book.coverUrl!.isNotEmpty
                        ? Image.network(
                            listing.book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildFallbackCover(listing.book),
                          )
                        : _buildFallbackCover(listing.book),
                  ),
                  const SizedBox(width: 18),

                  // Metadata column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Badge
                        _buildDetailTypeBadge(listing),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          listing.book.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Author
                        Text(
                          listing.book.author,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Condition Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'Stan: ${listing.book.condition.label}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ISBN tag
                        if (listing.book.isbn.isNotEmpty)
                          Text(
                            'ISBN: ${listing.book.isbn}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Safe exchange notice
                  const SafeExchangeBadge(),
                  const SizedBox(height: 14),

                  // Location and Distance Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isNearby
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isNearby
                            ? Colors.green.shade300
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isNearby
                                ? Colors.green.shade600
                                : Colors.blueGrey,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.district != null
                                    ? '${listing.city} • ${listing.district}'
                                    : listing.city,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DistanceService.formatDistance(distanceKm)}${isNearby ? " (w Twoim promieniu 5 km! 🎯)" : ""}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isNearby
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isNearby
                                      ? Colors.green.shade900
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Seller Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            listing.sellerName.substring(0, 1),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    listing.sellerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified,
                                      size: 16, color: Colors.blue),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 15, color: Colors.amber),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${listing.sellerRating.toStringAsFixed(1)} • ${listing.completedExchangesCount} udanych wymian',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
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
                  const SizedBox(height: 20),

                  // Exchange Preferences
                  if (listing.exchangePreferences != null &&
                      listing.exchangePreferences!.isNotEmpty) ...[
                    Text(
                      'Preferencje wymiany:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        listing.exchangePreferences!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.brown.shade900,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Description
                  if (listing.book.description.isNotEmpty) ...[
                    Text(
                      'O książce:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing.book.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Additional metadata details
                  _buildBookSpecs(listing.book),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Bar with Action Buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Propose Exchange Button
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Zaproponuj wymianę'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _openExchangeProposalModal(context, provider),
                ),
              ),
              const SizedBox(width: 10),

              // Open Internal Chat Button
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Napisz na czacie'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final conv =
                        provider.getOrCreateConversationForListing(listing);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => ChatDetailScreen(conversation: conv),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTypeBadge(Listing listing) {
    if (listing.type == ListingType.exchange) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.indigo.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Tylko wymiana',
          style: TextStyle(
            color: Colors.indigo.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    } else if (listing.type == ListingType.sale) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.teal.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Sprzedaż: ${listing.price?.toStringAsFixed(0) ?? "--"} PLN',
          style: TextStyle(
            color: Colors.teal.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Wymiana lub sprzedaż (${listing.price?.toStringAsFixed(0) ?? "--"} PLN)',
          style: TextStyle(
            color: Colors.brown.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
  }

  Widget _buildBookSpecs(Book book) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (book.publisher != null)
            _buildSpecRow('Wydawnictwo', book.publisher!),
          if (book.publishYear != null)
            _buildSpecRow('Rok wydania', book.publishYear.toString()),
          if (book.pageCount != null)
            _buildSpecRow('Liczba stron', '${book.pageCount}'),
          if (book.categories.isNotEmpty)
            _buildSpecRow('Kategorie', book.categories.join(', ')),
          if (book.isbn.isNotEmpty) _buildSpecRow('Numer ISBN', book.isbn),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFallbackCover(Book book) {
    return Container(
      color: const Color(0xFF2C3E50),
      child: const Center(
        child: Icon(Icons.menu_book, color: Colors.white, size: 36),
      ),
    );
  }

  void _openExchangeProposalModal(
      BuildContext context, CzytellaProvider provider) {
    final userBooks = provider.userBooks;

    if (userBooks.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Brak książek na półce'),
          content: const Text(
            'Aby zaproponować wymianę, dodaj najpierw przynajmniej jedną książkę do zakładki "Moje książki na wymianę/sprzedaż".',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    UserBook? selectedUserBook = userBooks.first;
    final locationController = TextEditingController(
      text: 'np. stacja metra, rynek, kawiarnia',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
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
                const Text(
                  'Zaproponuj wymianę książek',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wybierz książkę ze swojej półki, którą chcesz zaoferować za "${listing.book.title}":',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),

                // Book Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserBook>(
                      isExpanded: true,
                      value: selectedUserBook,
                      items: userBooks.map((ub) {
                        return DropdownMenuItem<UserBook>(
                          value: ub,
                          child: Text(
                            '${ub.book.title} (${ub.book.author})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedUserBook = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Location field
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Proponowane miejsce bezpiecznego spotkania',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Wyślij propozycję na czacie'),
                    onPressed: () {
                      if (selectedUserBook == null) return;
                      Navigator.pop(ctx);

                      final conv =
                          provider.getOrCreateConversationForListing(listing);

                      final proposal = ExchangeProposal(
                        id: 'prop_${DateTime.now().millisecondsSinceEpoch}',
                        offeredBookTitle:
                            '${selectedUserBook!.book.title} (${selectedUserBook!.book.author})',
                        offeredBookCover: selectedUserBook!.book.coverUrl,
                        requestedBookTitle:
                            '${listing.book.title} (${listing.book.author})',
                        proposedLocation: locationController.text.trim(),
                        status: ProposalStatus.pending,
                      );

                      provider.sendMessage(
                        conv.id,
                        'Cześć! Chciał(a)bym zaproponować wymianę mojej książki na Twoją.',
                        proposal: proposal,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => ChatDetailScreen(conversation: conv),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
