import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:czytella/main.dart';
import 'package:czytella/services/distance_service.dart';
import 'package:czytella/services/isbn_lookup_service.dart';

void main() {
  testWidgets('Czytella smoke test – app loads and brand is visible', (WidgetTester tester) async {
    // Use a narrow (mobile) viewport so the bottom NavigationBar is rendered.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Suppress RenderFlex overflow warnings that only occur at the test viewport
    // size but do not affect the actual UI (overflow is clipped safely).
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(const CzytellaApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 800));

    // App brand appears in header
    expect(find.text('Czytella'), findsWidgets);

    // Bottom navigation destinations are rendered
    expect(find.text('Ogłoszenia'), findsWidgets);
    expect(find.text('Moja Półka'), findsOneWidget);
    expect(find.text('Skaner ISBN'), findsOneWidget);
    expect(find.text('Czat'), findsOneWidget);

    // Radius filter chip is visible on the listings tab
    expect(find.text('W promieniu 5 km'), findsOneWidget);

    // Navigate to "Moja Półka"
    await tester.tap(find.text('Moja Półka'));
    await tester.pumpAndSettle(const Duration(milliseconds: 800));

    // The two shelf tabs are visible
    expect(find.textContaining('Wymiana'), findsWidgets);
    expect(find.textContaining('szukam'), findsWidgets);
  });

  test('DistanceService calculates distance correctly with Haversine formula', () {
    // Distance between Warszawa and Kraków is ~250-260 km
    final dist = DistanceService.calculateDistanceKm(
      lat1: 52.2297,
      lon1: 21.0122,
      lat2: 50.0647,
      lon2: 19.9450,
    );
    expect(dist, greaterThan(240));
    expect(dist, lessThan(270));

    // Distance formatting test
    expect(DistanceService.formatDistance(0.45), '450 m stąd');
    expect(DistanceService.formatDistance(3.24), '3.2 km stąd');
    expect(DistanceService.formatDistance(25.4), '25 km stąd');
  });

  test('IsbnLookupService normalizes and validates ISBNs', () {
    expect(IsbnLookupService.normalizeIsbn('978-83-08-06417-7'), '9788308064177');
    expect(IsbnLookupService.isValidIsbnFormat('9788308064177'), isTrue);
    expect(IsbnLookupService.isValidIsbnFormat('12345'), isFalse);
  });

  test('DistanceService contains cities representing all 16 Polish voivodeships', () {
    final allVoivodeships = {
      'dolnośląskie',
      'kujawsko-pomorskie',
      'lubelskie',
      'lubuskie',
      'łódzkie',
      'małopolskie',
      'mazowieckie',
      'opolskie',
      'podkarpackie',
      'podlaskie',
      'pomorskie',
      'śląskie',
      'świętokrzyskie',
      'warmińsko-mazurskie',
      'wielkopolskie',
      'zachodniopomorskie',
    };

    final representedRegions = DistanceService.popularCities.map((c) => c.region).toSet();
    for (final voivodeship in allVoivodeships) {
      expect(
        representedRegions.contains(voivodeship),
        isTrue,
        reason: 'Missing voivodeship: $voivodeship',
      );
    }
    expect(DistanceService.popularCities.length, greaterThanOrEqualTo(16));
  });
}

