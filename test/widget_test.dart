import 'package:flutter_test/flutter_test.dart';
import 'package:czytella/main.dart';
import 'package:czytella/services/distance_service.dart';
import 'package:czytella/services/isbn_lookup_service.dart';

void main() {
  testWidgets('Czytella smoke test and main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const CzytellaApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app brand is present
    expect(find.text('Czytella'), findsOneWidget);

    // Verify Navigation destinations
    expect(find.text('Ogłoszenia'), findsWidgets);
    expect(find.text('Moja Półka'), findsOneWidget);
    expect(find.text('Skaner ISBN'), findsOneWidget);
    expect(find.text('Czat'), findsOneWidget);

    // Verify 5 km radius chip is present on the marketplace screen
    expect(find.text('W promieniu 5 km'), findsOneWidget);

    // Tap on "Moja Półka" tab
    await tester.tap(find.text('Moja Półka'));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify the two requested tabs in Moja Półka
    expect(find.textContaining('Wymiana / Sprzedaż'), findsOneWidget);
    expect(find.textContaining('Książki których szukam'), findsOneWidget);

    // Tap on second tab: "Książki których szukam"
    await tester.tap(find.textContaining('Książki których szukam'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify wishlist content is visible
    expect(find.textContaining('Radar Czytelli'), findsOneWidget);

    // Tap on "Czat"
    await tester.tap(find.text('Czat'));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify safe chat notice without phone/facebook
    expect(find.textContaining('Bezpieczna wymiana w Czytelli'), findsWidgets);
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
}
