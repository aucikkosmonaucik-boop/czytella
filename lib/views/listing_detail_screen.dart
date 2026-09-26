import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listing.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../models/chat_message.dart';
import '../providers/czytella_provider.dart';
import '../services/distance_service.dart';
import '../widgets/book_cover_widget.dart';
import '../widgets/safe_exchange_badge.dart';
import 'chat_detail_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final Listing listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late Listing _currentListing;

  @override
  void initState() {
    super.initState();
    _currentListing = widget.listing;
  }

  bool _isMyListing(CzytellaProvider provider) {
    if (!provider.isAuthenticated || provider.currentUser == null) {
      return false;
    }
    final user = provider.currentUser!;
    if (_currentListing.sellerId == user.id ||
        _currentListing.sellerName == user.name) {
      return true;
    }
    if (_currentListing.isUserListing && _currentListing.sellerId == 'current_user') {
      return true;
    }
    return false;
  }

  Future<void> _confirmDeleteListing(
      BuildContext context, CzytellaProvider provider) async {
    if (!provider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Musisz być zalogowany, aby usunąć ogłoszenie.'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Usunąć ogłoszenie?'),
          ],
        ),
        content: Text(
          'Czy na pewno chcesz usunąć ofertę "${_currentListing.book.title}" z giełdy Czytelli? Książka pozostanie na Twojej prywatnej półce.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Usuń ogłoszenie'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      provider.removeListing(_currentListing.id);
      Navigator.of(this.context).pop();
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Usunięto ogłoszenie "${_currentListing.book.title}".'),
        ),
      );
    }
  }

  Future<void> _openEditListingDialog(
      BuildContext context, CzytellaProvider provider) async {
    if (!provider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Musisz być zalogowany, aby edytować ogłoszenie.'),
        ),
      );
      return;
    }
    final titleCtrl = TextEditingController(text: _currentListing.book.title);
    final authorCtrl = TextEditingController(text: _currentListing.book.author);
    final priceCtrl = TextEditingController(
      text: _currentListing.price != null
          ? _currentListing.price!.toStringAsFixed(0)
          : '20',
    );
    final prefCtrl = TextEditingController(
      text: _currentListing.exchangePreferences ?? '',
    );
    final descCtrl = TextEditingController(
      text: _currentListing.book.description,
    );
    final coverCtrl = TextEditingController(
      text: _currentListing.book.coverUrl ?? '',
    );

    ListingType selectedType = _currentListing.type;
    BookCondition selectedCondition = _currentListing.book.condition;
    String selectedCity = _currentListing.city;

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
                      'Edytuj ogłoszenie',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title & Author
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tytuł książki',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Autor',
                    border: OutlineInputBorder(),
                  ),
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
                      selected: selectedType == ListingType.both,
                      selectedColor: const Color(0xFFD6E8D5),
                      onSelected: (_) =>
                          setSheetState(() => selectedType = ListingType.both),
                    ),
                    ChoiceChip(
                      label: const Text('Tylko sprzedaż'),
                      selected: selectedType == ListingType.sale,
                      selectedColor: const Color(0xFFD6E8D5),
                      onSelected: (_) =>
                          setSheetState(() => selectedType = ListingType.sale),
                    ),
                    ChoiceChip(
                      label: const Text('Tylko wymiana'),
                      selected: selectedType == ListingType.exchange,
                      selectedColor: const Color(0xFFD6E8D5),
                      onSelected: (_) => setSheetState(
                          () => selectedType = ListingType.exchange),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Price (if sale or both)
                if (selectedType != ListingType.exchange) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cena w złotych (PLN)',
                            suffixText: 'zł',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['10', '15', '20', '25', '30', '50'].map((p) {
                      return ActionChip(
                        label: Text('$p zł'),
                        onPressed: () => setSheetState(() => priceCtrl.text = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Condition
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

                // City
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 18, color: Color(0xFF1E5128)),
                    const SizedBox(width: 6),
                    Text(
                      'Miasto: $selectedCity',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final cities = DistanceService.popularCities;
                        final picked = await showDialog<String>(
                          context: ctx,
                          builder: (dCtx) => SimpleDialog(
                            title: const Text('Wybierz miasto'),
                            children: cities.map((c) {
                              return SimpleDialogOption(
                                onPressed: () => Navigator.pop(dCtx, c.name),
                                child: Text(c.name),
                              );
                            }).toList(),
                          ),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedCity = picked);
                        }
                      },
                      child: const Text('Zmień miasto'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Cover URL
                TextField(
                  controller: coverCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Link do okładki (URL, opcjonalnie)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 10),

                // Exchange Preferences
                TextField(
                  controller: prefCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Preferencje wymiany (opcjonalnie)',
                    hintText: 'np. chętnie wymienię na kryminał lub Kinga',
                    border: OutlineInputBorder(),
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
                        backgroundColor: const Color(0xFF1E5128),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        final priceVal = double.tryParse(priceCtrl.text.trim());
                        final updatedBook = _currentListing.book.copyWith(
                          title: titleCtrl.text.trim().isNotEmpty
                              ? titleCtrl.text.trim()
                              : _currentListing.book.title,
                          author: authorCtrl.text.trim().isNotEmpty
                              ? authorCtrl.text.trim()
                              : _currentListing.book.author,
                          condition: selectedCondition,
                          coverUrl: coverCtrl.text.trim().isNotEmpty
                              ? coverCtrl.text.trim()
                              : _currentListing.book.coverUrl,
                          description: descCtrl.text.trim(),
                        );

                        final updatedListing = _currentListing.copyWith(
                          book: updatedBook,
                          type: selectedType,
                          price: selectedType == ListingType.exchange
                              ? null
                              : priceVal,
                          city: selectedCity,
                          exchangePreferences: prefCtrl.text.trim().isNotEmpty
                              ? prefCtrl.text.trim()
                              : null,
                        );

                        provider.updateListing(updatedListing);
                        setState(() {
                          _currentListing = updatedListing;
                        });

                        Navigator.pop(mCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Zaktualizowano ogłoszenie!'),
                          ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CzytellaProvider>();
    final distanceKm = provider.getDistanceFromUser(_currentListing);
    final isNearby = distanceKm <= 5.0;
    final isMine = _isMyListing(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły oferty'),
        actions: [
          if (isMine) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edytuj ogłoszenie',
              onPressed: () => _openEditListingDialog(context, provider),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Usuń ogłoszenie',
              onPressed: () => _confirmDeleteListing(context, provider),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Udostępniono ofertę: ${_currentListing.book.title}'),
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
            // Banner if user's own listing
            if (isMine)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                color: Colors.green.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        size: 16, color: Color(0xFF1E5128)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'To jest Twoje ogłoszenie. Możesz je edytować lub usunąć.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E5128),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.edit,
                          size: 13, color: Color(0xFF1E5128)),
                      label: const Text('Edytuj',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E5128))),
                      onPressed: () =>
                          _openEditListingDialog(context, provider),
                    ),
                  ],
                ),
              ),

            // Top Cover & Main Details Banner
            Container(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Cover using BookCoverWidget
                  BookCoverWidget(
                    book: _currentListing.book,
                    width: 110,
                    height: 165,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),

                  // Metadata column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Badge
                        _buildDetailTypeBadge(_currentListing),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          _currentListing.book.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Author
                        Text(
                          _currentListing.book.author,
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
                            'Stan: ${_currentListing.book.condition.label}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Location
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _currentListing.district != null
                                    ? '${_currentListing.city}, ${_currentListing.district}'
                                    : _currentListing.city,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                ),
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

            // Distance Radar Banner (<= 5 km)
            if (isNearby)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.near_me,
                          size: 18, color: Colors.green.shade900),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'W Twojej okolicy (${DistanceService.formatDistance(distanceKm)})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.green.shade900,
                            ),
                          ),
                          const Text(
                            'Idealna okazja do szybkiej wymiany osobiście bez kosztów wysyłki!',
                            style:
                                TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Content Sections
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Safe exchange badge
                  const SafeExchangeBadge(),
                  const SizedBox(height: 20),

                  // Seller Profile Card (or My Account indicator)
                  _buildSellerCard(context, provider),
                  const SizedBox(height: 20),

                  // Exchange Preferences
                  if (_currentListing.exchangePreferences != null &&
                      _currentListing.exchangePreferences!.isNotEmpty) ...[
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
                        _currentListing.exchangePreferences!,
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
                  if (_currentListing.book.description.isNotEmpty) ...[
                    Text(
                      'O książce:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentListing.book.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Additional metadata details
                  _buildBookSpecs(_currentListing.book),
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
          child: isMine
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 15, color: Colors.green.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'To Twoja oferta. Inni czytelnicy widzą tutaj przycisk „Napisz na czacie” i mogą pisać do Ciebie.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            label: const Text(
                              'Usuń ogłoszenie',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                _confirmDeleteListing(context, provider),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text(
                              'Edytuj ofertę',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1E5128),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                _openEditListingDialog(context, provider),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Propose Exchange Button
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Zaproponuj wymianę'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            _openExchangeProposalModal(context, provider),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Open Internal Chat Button
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Napisz na czacie'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5128),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final conv = provider
                              .getOrCreateConversationForListing(_currentListing);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) =>
                                  ChatDetailScreen(conversation: conv),
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

  Widget _buildSellerCard(BuildContext context, CzytellaProvider provider) {
    final isMine = _isMyListing(provider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMine ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMine ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                isMine ? const Color(0xFF1E5128) : Colors.teal.shade100,
            child: Text(
              _currentListing.sellerName.isNotEmpty
                  ? _currentListing.sellerName[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMine ? Colors.white : Colors.teal.shade800,
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
                      isMine ? 'Moje konto' : _currentListing.sellerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Autor',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      '${_currentListing.sellerRating}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_currentListing.completedExchangesCount} udanych transakcji',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade700),
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

  Widget _buildBookSpecs(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metryka książki:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildSpecRow('Numer ISBN', book.isbn),
              if (book.publisher != null)
                _buildSpecRow('Wydawnictwo', book.publisher!),
              if (book.publishYear != null)
                _buildSpecRow('Rok wydania', '${book.publishYear}'),
              if (book.pageCount != null)
                _buildSpecRow('Liczba stron', '${book.pageCount}'),
              if (book.categories.isNotEmpty)
                _buildSpecRow('Kategoria', book.categories.join(', ')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
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
                  'Wybierz książkę ze swojej półki, którą chcesz zaoferować za "${_currentListing.book.title}":',
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
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E5128),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (selectedUserBook == null) return;
                      Navigator.pop(ctx);

                      final conv = provider
                          .getOrCreateConversationForListing(_currentListing);

                      final proposal = ExchangeProposal(
                        id: 'prop_${DateTime.now().millisecondsSinceEpoch}',
                        offeredBookTitle:
                            '${selectedUserBook!.book.title} (${selectedUserBook!.book.author})',
                        offeredBookCover: selectedUserBook!.book.coverUrl,
                        requestedBookTitle:
                            '${_currentListing.book.title} (${_currentListing.book.author})',
                        proposedLocation: locationController.text.trim(),
                        status: ProposalStatus.pending,
                      );

                      provider.sendMessage(
                        conv.id,
                        '',
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
