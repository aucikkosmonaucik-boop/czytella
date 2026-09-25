import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:czytella/main.dart';
import 'package:czytella/widgets/apk_download_dialog.dart';
import 'package:czytella/widgets/mobile_app_banner.dart';

void main() {
  testWidgets('Czytella desktop web layout & APK download banner test', (WidgetTester tester) async {
    // Configure viewport to a desktop resolution (1280 x 800)
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CzytellaApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 800));

    // Desktop header is present
    expect(find.text('Czytella'), findsWidgets);
    expect(find.text('Dodaj ogłoszenie'), findsOneWidget);

    // Desktop "Pobierz APK" button is present in the navbar
    expect(find.text('Pobierz APK'), findsWidgets);

    // MobileAppBanner is visible on desktop
    expect(find.byType(MobileAppBanner), findsOneWidget);
    expect(find.textContaining('NOWOŚĆ • WERSJA MOBILNA'), findsOneWidget);
    expect(find.textContaining('Pobierz darmowy plik APK z GitHub Releases'), findsOneWidget);

    // Desktop filter elements are visible
    expect(find.text('W promieniu 5 km'), findsWidgets);
    expect(find.textContaining('Wszystkie'), findsWidgets);

    // Tap the navbar "Pobierz APK" button to open the modal
    final navApkButton = find.widgetWithText(OutlinedButton, 'Pobierz APK');
    expect(navApkButton, findsOneWidget);
    await tester.tap(navApkButton);
    await tester.pumpAndSettle();

    // Verify ApkDownloadDialog is shown with description and installation instructions
    expect(find.byType(ApkDownloadDialog), findsOneWidget);
    expect(find.text('Czytella na Androida'), findsOneWidget);
    expect(find.textContaining('Jak zainstalować plik APK na telefonie?'), findsOneWidget);
    expect(find.textContaining('Pobierz APK (GitHub Releases)'), findsOneWidget);

    // Close the dialog using its close button
    final dialogCloseBtn = find.descendant(
      of: find.byType(ApkDownloadDialog),
      matching: find.byIcon(Icons.close),
    );
    await tester.tap(dialogCloseBtn);
    await tester.pumpAndSettle();

    expect(find.byType(ApkDownloadDialog), findsNothing);
  });
}
