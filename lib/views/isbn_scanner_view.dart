import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../models/wishlist_book.dart';
import '../models/listing.dart';
import '../providers/czytella_provider.dart';
import '../services/isbn_lookup_service.dart';
import '../services/distance_service.dart';
import '../widgets/apk_download_dialog.dart';
import '../widgets/book_cover_widget.dart';

enum ScannerTargetMode {
  general,
  myBooks,
  wishlist,
}

class IsbnScannerView extends StatefulWidget {
  final ScannerTargetMode targetMode;

  const IsbnScannerView({
    super.key,
    this.targetMode = ScannerTargetMode.general,
  });

  @override
  State<IsbnScannerView> createState() => _IsbnScannerViewState();
}

class _IsbnScannerViewState extends State<IsbnScannerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final MobileScannerController _scannerController;
  final TextEditingController _isbnTextController = TextEditingController();

  bool _isLoading = false;
  bool _isProcessingCode = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    _isbnTextController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingCode || _isLoading) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        final cleanIsbn = IsbnLookupService.normalizeIsbn(raw);
        // Valid EAN-13 (13 digits) or ISBN-10 (10 chars)
        if (cleanIsbn.length == 10 || cleanIsbn.length == 13) {
          _isProcessingCode = true;
          _processIsbn(cleanIsbn);
          break;
        }
      }
    }
  }

  Future<void> _processIsbn(String rawIsbn) async {
    final cleanIsbn = IsbnLookupService.normalizeIsbn(rawIsbn);
    if (cleanIsbn.isEmpty) return;

    setState(() {
      _isLoading = true;
      _isProcessingCode = true;
    });

    try {
      await _scannerController.stop();
    } catch (_) {}

    final book = await IsbnLookupService.lookupIsbn(cleanIsbn);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (book != null) {
        await _showBookResultSheet(book);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie znaleziono książki o podanym numerze ISBN.'),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _isProcessingCode = false;
        });
        try {
          await _scannerController.start();
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Skaner kodów ISBN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _scannerController,
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: isTorchOn ? Colors.amber : Colors.white,
                ),
                onPressed: () => _scannerController.toggleTorch(),
                tooltip: 'Latarka',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _scannerController.switchCamera(),
            tooltip: 'Zmień aparat (przód / tył)',
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white12,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.targetMode == ScannerTargetMode.wishlist
                        ? 'Skieruj aparat na kod kreskowy książki, której szukasz'
                        : widget.targetMode == ScannerTargetMode.myBooks
                            ? 'Skieruj aparat na kod z okładki książki, którą posiadasz'
                            : 'Skieruj obiektyw na kod kreskowy ISBN z tyłu książki',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Viewfinder Camera Area
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Live Camera Stream
                Positioned.fill(
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) {
                      return Container(
                        color: Colors.grey.shade900,
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.videocam_off_outlined,
                                size: 52,
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Aparat niedostępny lub brak uprawnień',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Zezwól na dostęp do aparatu w przeglądarce, wpisz kod ISBN ręcznie poniżej lub skorzystaj z szybkich testów.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white30),
                                ),
                                onPressed: () {
                                  _scannerController.start();
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Ponów próbę uruchomienia aparatu'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    placeholderBuilder: (context) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.greenAccent),
                        ),
                      );
                    },
                  ),
                ),

                // Barcode Target Framing Box (Transparent cutout guide)
                IgnorePointer(
                  child: Container(
                    width: 280,
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isLoading ? Colors.amber : Colors.greenAccent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),

                // Animated Laser Line
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Positioned(
                        top: MediaQuery.of(context).size.height * 0.18 +
                            (_animController.value * 140),
                        child: Container(
                          width: 260,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Loading overlay
                if (_isLoading)
                  Container(
                    width: 280,
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.amber),
                        SizedBox(height: 12),
                        Text(
                          'Pobieranie danych książki...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Barcode Testing & Manual Input Controls
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tip: Mobile APK
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android,
                          size: 18, color: Color(0xFF1E5128)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Wskazówka: Aby skanować fizyczne kody ISBN aparatem telefonu, możesz także pobrać naszą aplikację APK na Androida!',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E5128),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => ApkDownloadDialog.show(context),
                        child: const Text(
                          'Pobierz APK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E5128),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Preset Barcode Tapper for Quick Demo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Przykładowe kody ISBN do testu:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Dotknij, aby przetestować',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: IsbnLookupService.demoIsbns.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = IsbnLookupService.demoIsbns[index];
                      return ActionChip(
                        avatar: const Icon(Icons.qr_code, size: 16),
                        label: Text('${item.title} (${item.author.split(' ').last})'),
                        onPressed: () => _processIsbn(item.isbn),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Manual ISBN input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _isbnTextController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Wpisz ISBN np. 9788375780635',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          prefixIcon: const Icon(Icons.keyboard, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            _processIsbn(val.trim());
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      onPressed: () {
                        if (_isbnTextController.text.trim().isNotEmpty) {
                          _processIsbn(_isbnTextController.text.trim());
                        }
                      },
                      child: const Text('Szukaj'),
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

  Future<void> _showBookResultSheet(Book initialBook) async {
    final provider = context.read<CzytellaProvider>();
    Book currentBook = initialBook;

    // Price controller
    final priceController = TextEditingController(text: '20');
    final prefController = TextEditingController();
    ListingType selectedType = ListingType.both;
    BookCondition selectedCondition = currentBook.condition;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
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

                // Book Card Preview
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookCoverWidget(
                      book: currentBook,
                      width: 80,
                      height: 120,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 14),
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
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border:
                                      Border.all(color: Colors.green.shade300),
                                ),
                                child: Text(
                                  'Pomyślnie zeskanowano!',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon:
                                    const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edytuj dane książki',
                                onPressed: () async {
                                  final titleCtrl = TextEditingController(
                                      text: currentBook.title);
                                  final authorCtrl = TextEditingController(
                                      text: currentBook.author);
                                  final coverCtrl = TextEditingController(
                                      text: currentBook.coverUrl ?? '');
                                  final edited = await showDialog<bool>(
                                    context: sheetContext,
                                    builder: (dCtx) => AlertDialog(
                                      title: const Text('Edytuj dane książki'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
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
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: coverCtrl,
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Link do okładki (URL, opcjonalnie)',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dCtx, false),
                                          child: const Text('Anuluj'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(dCtx, true),
                                          child: const Text('Zapisz'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (edited == true && sheetContext.mounted) {
                                    setSheetState(() {
                                      currentBook = currentBook.copyWith(
                                        title: titleCtrl.text.trim().isNotEmpty
                                            ? titleCtrl.text.trim()
                                            : currentBook.title,
                                        author: authorCtrl.text.trim().isNotEmpty
                                            ? authorCtrl.text.trim()
                                            : currentBook.author,
                                        coverUrl: coverCtrl.text.trim().isNotEmpty
                                            ? coverCtrl.text.trim()
                                            : currentBook.coverUrl,
                                      );
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentBook.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentBook.author,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ISBN: ${currentBook.isbn}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),

                // Typ oferty (Wymiana / Sprzedaż / Oba)
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
                const SizedBox(height: 12),

                // Price Section (if sale or both)
                if (selectedType != ListingType.exchange) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Twoja proponowana cena (PLN)',
                            suffixText: 'zł',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payments_outlined),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
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
                        onPressed: () =>
                            setSheetState(() => priceController.text = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Stan książki
                const Text('Stan egzemplarza:',
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
                const SizedBox(height: 12),

                // Miasto / Lokalizacja
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 18, color: Color(0xFF1E5128)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Miasto ogłoszenia: ${provider.currentCity}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          final cities = DistanceService.popularCities;
                          final customCityCtrl = TextEditingController();

                          await showDialog(
                            context: sheetContext,
                            builder: (dCtx) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.location_city,
                                      color: Color(0xFF1E5128)),
                                  SizedBox(width: 8),
                                  Text('Wybierz Twoje miasto'),
                                ],
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Wskaż miasto, w którym wystawiasz książki do wymiany/sprzedaży:',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: cities.map((c) {
                                          return ChoiceChip(
                                            label: Text(c.name),
                                            selected: c.name.toLowerCase() ==
                                                provider.currentCity
                                                    .toLowerCase(),
                                            selectedColor:
                                                const Color(0xFFD6E8D5),
                                            onSelected: (_) {
                                              provider.setUserLocation(
                                                cityName: c.name,
                                                latitude: c.latitude,
                                                longitude: c.longitude,
                                              );
                                              setSheetState(() {});
                                              Navigator.pop(dCtx);
                                            },
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(),
                                      const SizedBox(height: 6),
                                      const Text('Lub wpisz inne miasto:',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: customCityCtrl,
                                              decoration: const InputDecoration(
                                                hintText: 'np. Sopot, Zakopane',
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          FilledButton(
                                            onPressed: () {
                                              final val =
                                                  customCityCtrl.text.trim();
                                              if (val.isNotEmpty) {
                                                provider.setUserLocation(
                                                  cityName: val,
                                                  latitude:
                                                      provider.userLatitude,
                                                  longitude:
                                                      provider.userLongitude,
                                                );
                                                setSheetState(() {});
                                                Navigator.pop(dCtx);
                                              }
                                            },
                                            child: const Text('Zapisz'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx),
                                  child: const Text('Zamknij'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Zmień miasto',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Preferencje wymiany
                TextField(
                  controller: prefController,
                  decoration: const InputDecoration(
                    labelText: 'Preferencje wymiany (opcjonalnie)',
                    hintText: 'np. chętnie wymienię na inną ciekawą powieść',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 18),

                // Main Action 1: Wystaw jako publiczne ogłoszenie
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E5128),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.campaign),
                    label: const Text(
                      'Wystaw jako ogłoszenie na giełdzie',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      final priceVal = double.tryParse(priceController.text.trim());
                      final finalizedBook =
                          currentBook.copyWith(condition: selectedCondition);

                      provider.createDirectListing(
                        book: finalizedBook,
                        type: selectedType,
                        price: selectedType == ListingType.exchange
                            ? null
                            : priceVal,
                        exchangePreferences: prefController.text.trim().isNotEmpty
                            ? prefController.text.trim()
                            : 'Chętnie wymienię na inną książkę',
                        city: provider.currentCity,
                      );
                      Navigator.pop(ctx);
                      if (widget.targetMode != ScannerTargetMode.general &&
                          Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Opublikowano ogłoszenie dla "${finalizedBook.title}" w mieście ${provider.currentCity}!'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Main Action 2: Dodaj na półkę (bez natychmiastowego wystawiania)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.library_books),
                    label: const Text(
                      'Dodaj tylko do: Moje książki (Półka)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      final priceVal = double.tryParse(priceController.text.trim());
                      final finalizedBook =
                          currentBook.copyWith(condition: selectedCondition);

                      final userBookType = selectedType == ListingType.exchange
                          ? UserBookType.forExchange
                          : selectedType == ListingType.sale
                              ? UserBookType.forSale
                              : UserBookType.both;

                      provider.addUserBook(
                        UserBook(
                          id: 'ub_${DateTime.now().millisecondsSinceEpoch}',
                          book: finalizedBook,
                          type: userBookType,
                          price: selectedType == ListingType.exchange
                              ? null
                              : priceVal,
                          isListed: false,
                          preferredExchangeGenres:
                              prefController.text.trim().isNotEmpty
                                  ? prefController.text.trim()
                                  : null,
                        ),
                      );
                      Navigator.pop(ctx);
                      if (widget.targetMode != ScannerTargetMode.general &&
                          Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Dodano "${finalizedBook.title}" do Twojej półki!'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Main Action 3: Add to wishlist
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.favorite_border,
                        size: 16, color: Colors.pink),
                    label: const Text(
                      'Dodaj do: Książki których szukam (Lista życzeń)',
                      style: TextStyle(
                          color: Colors.pink,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      provider.addWishlistBook(
                        WishlistBook(
                          id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                          isbn: currentBook.isbn,
                          title: currentBook.title,
                          author: currentBook.author,
                          coverUrl: currentBook.coverUrl,
                          priority: WishlistPriority.high,
                        ),
                      );
                      Navigator.pop(ctx);
                      if (widget.targetMode != ScannerTargetMode.general &&
                          Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Dodano "${currentBook.title}" do listy książek, których szukasz!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
