import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/listing.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../models/chat_message.dart';
import '../providers/czytella_provider.dart';
import '../services/distance_service.dart';
import '../widgets/book_cover_widget.dart';
import '../widgets/safe_exchange_badge.dart';
import 'chat_detail_screen.dart';
import 'auth_dialog.dart';

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
    if (_currentListing.isUserListing) {
      return true;
    }
    if (_currentListing.sellerId == user.id ||
        _currentListing.sellerName == user.name) {
      return true;
    }
    if (provider.userBooks.any((ub) =>
        ub.book.id == _currentListing.book.id ||
        (ub.book.title.trim().toLowerCase() ==
                _currentListing.book.title.trim().toLowerCase() &&
            ub.book.author.trim().toLowerCase() ==
                _currentListing.book.author.trim().toLowerCase()))) {
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

  Future<void> _confirmAdminDeleteListing(
      CzytellaProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Moderacja Administratora'),
          ],
        ),
        content: Text(
          'Czy na pewno chcesz usunąć ogłoszenie "${_currentListing.book.title}" (wystawił: ${_currentListing.sellerName}) jako administrator platformy Czytella?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Usuń z platformy'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await provider.adminDeleteListing(_currentListing.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Usunięto ogłoszenie "${_currentListing.book.title}" jako administrator.',
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _shareListing(BuildContext context) async {
    final listing = _currentListing;
    final location =
        listing.district != null && listing.district!.trim().isNotEmpty
            ? '${listing.city}, ${listing.district}'
            : listing.city;

    final typeDescription = listing.type == ListingType.exchange
        ? 'Tylko wymiana'
        : listing.type == ListingType.sale
            ? 'Sprzedaż: ${listing.price?.toStringAsFixed(0) ?? "--"} zł'
            : 'Wymiana lub sprzedaż (${listing.price?.toStringAsFixed(0) ?? "--"} zł)';

    final shareUrl = 'https://czytella.pl/?listing=${listing.id}';
    final shareText = '''
📚 Czytella: "${listing.book.title}" – ${listing.book.author}
📍 Lokalizacja: $location
🔄 Oferta: $typeDescription
📖 Stan: ${listing.book.condition.label}

Zobacz ogłoszenie:
$shareUrl'''
        .trim();

    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

      XFile? imageFile;
      final coverUrl = listing.book.coverUrl;
      if (coverUrl != null && coverUrl.trim().isNotEmpty) {
        try {
          if (coverUrl.startsWith('data:image/')) {
            final commaIndex = coverUrl.indexOf(',');
            if (commaIndex != -1) {
              final base64Str = coverUrl.substring(commaIndex + 1);
              final bytes = base64Decode(base64Str);
              imageFile = XFile.fromData(
                bytes,
                mimeType: 'image/jpeg',
                name: 'okladka.jpg',
              );
            }
          } else if (coverUrl.startsWith('http')) {
            final res = await http
                .get(Uri.parse(coverUrl))
                .timeout(const Duration(seconds: 4));
            if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
              final contentType = res.headers['content-type'] ?? 'image/jpeg';
              imageFile = XFile.fromData(
                res.bodyBytes,
                mimeType: contentType,
                name: 'okladka.jpg',
              );
            }
          }
        } catch (e) {
          debugPrint('Error preparing cover for share: $e');
        }
      }

      ShareResult result;
      if (imageFile != null) {
        result = await Share.shareXFiles(
          [imageFile],
          text: shareText,
          subject: 'Książka w Czytella: ${listing.book.title}',
          sharePositionOrigin: origin,
        );
      } else {
        result = await Share.share(
          shareText,
          subject: 'Książka w Czytella: ${listing.book.title}',
          sharePositionOrigin: origin,
        );
      }

      if (result.status == ShareResultStatus.unavailable) {
        throw Exception('Share unavailable');
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skopiowano treść i link ogłoszenia do schowka!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      builder: (mCtx) {
        final isDark = Theme.of(mCtx).brightness == Brightness.dark;
        return StatefulBuilder(
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
                        color: isDark ? const Color(0xFF3E4F41) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.edit_note,
                          size: 24,
                          color: isDark
                              ? const Color(0xFF86E875)
                              : const Color(0xFF1E5128)),
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
                        selectedColor: isDark
                            ? const Color(0xFF2E6B32)
                            : const Color(0xFFD6E8D5),
                        onSelected: (_) =>
                            setSheetState(() => selectedType = ListingType.both),
                      ),
                      ChoiceChip(
                        label: const Text('Tylko sprzedaż'),
                        selected: selectedType == ListingType.sale,
                        selectedColor: isDark
                            ? const Color(0xFF2E6B32)
                            : const Color(0xFFD6E8D5),
                        onSelected: (_) =>
                            setSheetState(() => selectedType = ListingType.sale),
                      ),
                      ChoiceChip(
                        label: const Text('Tylko wymiana'),
                        selected: selectedType == ListingType.exchange,
                        selectedColor: isDark
                            ? const Color(0xFF2E6B32)
                            : const Color(0xFFD6E8D5),
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
                        selectedColor: isDark
                            ? const Color(0xFF2E6B32)
                            : const Color(0xFFD6E8D5),
                        onSelected: (_) =>
                            setSheetState(() => selectedCondition = cond),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // City
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF86E875)
                              : const Color(0xFF1E5128)),
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
                        backgroundColor: isDark ? const Color(0xFF2E7D32) : const Color(0xFF1E5128),
                        foregroundColor: Colors.white,
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
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CzytellaProvider>();
    final distanceKm = provider.getDistanceFromUser(_currentListing);
    final isNearby = distanceKm <= 5.0;
    final isMine = _isMyListing(provider);
    final isDark = theme.brightness == Brightness.dark;

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
          ] else if (provider.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.shield_outlined, color: Colors.red),
              tooltip: 'Usuń jako Administrator',
              onPressed: () => _confirmAdminDeleteListing(provider),
            ),
          ],
          Builder(
            builder: (btnContext) => IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Udostępnij ogłoszenie',
              onPressed: () => _shareListing(btnContext),
            ),
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
                color: isDark ? const Color(0xFF1E3520) : Colors.green.shade100,
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF86E875)
                            : const Color(0xFF1E5128)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'To jest Twoje ogłoszenie. Możesz je edytować lub usunąć.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFA5F098)
                              : const Color(0xFF1E5128),
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
                      icon: Icon(Icons.edit,
                          size: 13,
                          color: isDark
                              ? const Color(0xFF86E875)
                              : const Color(0xFF1E5128)),
                      label: Text('Edytuj',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF86E875)
                                  : const Color(0xFF1E5128))),
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
                        _buildDetailTypeBadge(_currentListing, isDark),
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
                            color: isDark ? const Color(0xFF1B231C) : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isDark ? const Color(0xFF28352A) : Colors.grey.shade300),
                          ),
                          child: Text(
                            'Stan: ${_currentListing.book.condition.label}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade200 : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Location
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _currentListing.district != null
                                    ? '${_currentListing.city}, ${_currentListing.district}'
                                    : _currentListing.city,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
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
                  color: isDark ? const Color(0xFF162E18) : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF28552D) : Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F4324) : Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.near_me,
                          size: 18, color: isDark ? const Color(0xFF86E875) : Colors.green.shade900),
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
                              color: isDark ? const Color(0xFF86E875) : Colors.green.shade900,
                            ),
                          ),
                          Text(
                            'Idealna okazja do szybkiej wymiany osobiście bez kosztów wysyłki!',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade300 : Colors.black87,
                            ),
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
                        color: isDark ? const Color(0xFF2E2413) : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF5E4923) : Colors.amber.shade200),
                      ),
                      child: Text(
                        _currentListing.exchangePreferences!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFFFD54F) : Colors.brown.shade900,
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
                        color: isDark ? const Color(0xFFDDE3DD) : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Additional metadata details
                  _buildBookSpecs(context, _currentListing.book),
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
                        color: isDark ? const Color(0xFF162E18) : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF28552D) : Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 15, color: isDark ? const Color(0xFF86E875) : Colors.green.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'To Twoja oferta. Inni czytelnicy widzą tutaj przycisk „Napisz na czacie” i mogą pisać do Ciebie.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFC7EBC6) : Colors.green.shade900,
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
                              backgroundColor: isDark ? const Color(0xFF2E7D32) : const Color(0xFF1E5128),
                              foregroundColor: Colors.white,
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
                          foregroundColor: isDark ? const Color(0xFF86E875) : const Color(0xFF1E5128),
                          side: BorderSide(color: isDark ? const Color(0xFF4E9F3D) : const Color(0xFF1E5128)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (!provider.isAuthenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Zaloguj się, aby zaproponować wymianę książek.'),
                              ),
                            );
                            AuthDialog.show(context);
                            return;
                          }
                          _openExchangeProposalModal(context, provider);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Open Internal Chat Button
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Napisz na czacie'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF2E7D32) : const Color(0xFF1E5128),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (!provider.isAuthenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Zaloguj się, aby pisać na czacie z właścicielem oferty.'),
                              ),
                            );
                            AuthDialog.show(context);
                            return;
                          }
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

  Widget _buildDetailTypeBadge(Listing listing, bool isDark) {
    if (listing.type == ListingType.exchange) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E284A) : Colors.indigo.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Tylko wymiana',
          style: TextStyle(
            color: isDark ? const Color(0xFF90CAF9) : Colors.indigo.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    } else if (listing.type == ListingType.sale) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF113834) : Colors.teal.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Sprzedaż: ${listing.price?.toStringAsFixed(0) ?? "--"} PLN',
          style: TextStyle(
            color: isDark ? const Color(0xFF80CBC4) : Colors.teal.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF382A13) : Colors.amber.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Wymiana lub sprzedaż (${listing.price?.toStringAsFixed(0) ?? "--"} PLN)',
          style: TextStyle(
            color: isDark ? const Color(0xFFFFD54F) : Colors.brown.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
  }

  Widget _buildSellerCard(BuildContext context, CzytellaProvider provider) {
    final isMine = _isMyListing(provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMine
            ? (isDark ? const Color(0xFF162E18) : Colors.green.shade50)
            : (isDark ? const Color(0xFF1B231C) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMine
              ? (isDark ? const Color(0xFF28552D) : Colors.green.shade200)
              : (isDark ? const Color(0xFF28352A) : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isMine
                ? (isDark ? const Color(0xFF2E7D32) : const Color(0xFF1E5128))
                : (isDark ? const Color(0xFF1C3A35) : Colors.teal.shade100),
            child: Text(
              _currentListing.sellerName.isNotEmpty
                  ? _currentListing.sellerName[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMine
                    ? Colors.white
                    : (isDark ? const Color(0xFF80CBC4) : Colors.teal.shade800),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2E5E33)
                              : Colors.green.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Autor',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : Colors.green.shade900)),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade200 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_currentListing.completedExchangesCount} udanych transakcji',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
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

  Widget _buildBookSpecs(BuildContext context, Book book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metryka książki:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B231C) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF28352A) : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildSpecRow(context, 'Numer ISBN', book.isbn),
              if (book.publisher != null)
                _buildSpecRow(context, 'Wydawnictwo', book.publisher!),
              if (book.publishYear != null)
                _buildSpecRow(context, 'Rok wydania', '${book.publishYear}'),
              if (book.pageCount != null)
                _buildSpecRow(context, 'Liczba stron', '${book.pageCount}'),
              if (book.categories.isNotEmpty)
                _buildSpecRow(context, 'Kategoria', book.categories.join(', ')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
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
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
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
                        color: isDark ? const Color(0xFF3E4F41) : Colors.grey.shade300,
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
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Book Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF28352A) : Colors.grey.shade300,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UserBook>(
                        isExpanded: true,
                        value: selectedUserBook,
                        dropdownColor: isDark ? const Color(0xFF1B231C) : null,
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
                        backgroundColor: isDark ? const Color(0xFF2E7D32) : const Color(0xFF1E5128),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                      if (!provider.isAuthenticated) {
                        AuthDialog.show(context);
                        return;
                      }
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
      );
    },
  );
}
}
