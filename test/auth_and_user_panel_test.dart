import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:czytella/providers/czytella_provider.dart';
import 'package:czytella/views/auth_dialog.dart';
import 'package:czytella/views/user_profile_dialog.dart';
import 'package:czytella/views/create_listing_dialog.dart';
import 'package:czytella/models/book.dart';
import 'package:czytella/models/listing.dart';
import 'package:czytella/views/listing_detail_screen.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Czytella user shelf starts empty with 0 sample books and 0 wishlist', () async {
    final provider = CzytellaProvider();
    await Future.delayed(const Duration(milliseconds: 50));

    expect(provider.userBooks, isEmpty);
    expect(provider.wishlist, isEmpty);
    expect(provider.isAuthenticated, isFalse);
    expect(provider.currentUser, isNull);
  });

  test('CzytellaProvider registration, profile update, and logout flow', () async {
    final provider = CzytellaProvider();
    await Future.delayed(const Duration(milliseconds: 50));

    // 1. Register new user
    final registered = await provider.register(
      name: 'Tomasz Nowak',
      email: 'tomasz.nowak@czytella.pl',
      password: 'bezpieczne_haslo_123',
      city: 'Kraków, Stare Miasto',
      bio: 'Czytam literaturę faktu i reportaże',
    );
    expect(registered, isTrue);
    expect(provider.isAuthenticated, isTrue);
    expect(provider.currentUser?.name, 'Tomasz Nowak');
    expect(provider.currentUser?.initials, 'TN');
    expect(provider.currentUser?.city, 'Kraków, Stare Miasto');
    expect(provider.currentUser?.bio, 'Czytam literaturę faktu i reportaże');

    // 2. Update profile
    await provider.updateProfile(
      name: 'Tomasz N.',
      city: 'Wrocław, Krzyki',
      bio: 'Nowy opis profilu',
    );
    expect(provider.currentUser?.name, 'Tomasz N.');
    expect(provider.currentUser?.city, 'Wrocław, Krzyki');
    expect(provider.currentUser?.bio, 'Nowy opis profilu');

    // 3. Logout
    await provider.logout();
    expect(provider.isAuthenticated, isFalse);
    expect(provider.currentUser, isNull);

    // 4. Login again
    final loggedIn = await provider.login(
      email: 'tomasz.nowak@czytella.pl',
      password: 'bezpieczne_haslo_123',
    );
    expect(loggedIn, isTrue);
    expect(provider.isAuthenticated, isTrue);
    expect(provider.currentUser?.email, 'tomasz.nowak@czytella.pl');
  });

  testWidgets('AuthDialog renders login and register tabs', (WidgetTester tester) async {
    final provider = CzytellaProvider();

    // Test Login tab
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: AuthDialog(initialTabIndex: 0),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Konto w Czytella'), findsOneWidget);
    expect(find.text('Logowanie'), findsOneWidget);
    expect(find.text('Rejestracja'), findsOneWidget);
    expect(find.text('Zaloguj się do swojego profilu'), findsOneWidget);
    expect(find.text('Zaloguj się'), findsOneWidget);
    expect(find.text('Szybkie logowanie demo (Jan Czytelnik)'), findsNothing);

    // Test Register tab
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: AuthDialog(key: ValueKey('register'), initialTabIndex: 1),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Utwórz darmowe konto'), findsOneWidget);
    expect(find.text('Imię lub pseudonim'), findsOneWidget);
    expect(find.text('Twoje miasto / dzielnica'), findsOneWidget);
  });

  testWidgets('UserProfileDialog renders user details and stats when authenticated', (WidgetTester tester) async {
    final provider = CzytellaProvider();
    await provider.register(
      name: 'Ewa',
      email: 'ewa@czytella.pl',
      password: 'password123',
      city: 'Warszawa',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: UserProfileDialog(),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify UserProfileDialog
    expect(find.text('Panel czytelnika'), findsOneWidget);
    expect(find.text('Ewa'), findsOneWidget);
    expect(find.text('Zweryfikowany czytelnik'), findsOneWidget);
    expect(find.text('Twoja aktywność'), findsOneWidget);
    expect(find.text('Przejdź do Mojej Półki'), findsOneWidget);
    expect(find.text('Edytuj dane profilu'), findsOneWidget);
    expect(find.text('Wyloguj się z Czytelli'), findsOneWidget);
  });

  testWidgets('CreateListingDialog requires authentication', (WidgetTester tester) async {
    final provider = CzytellaProvider();

    // 1. Unauthenticated state -> shows login barrier
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: CreateListingDialog(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Wymagane logowanie'), findsOneWidget);
    expect(find.text('Zaloguj się lub załóż konto'), findsOneWidget);
    expect(find.text('Dodaj nowe ogłoszenie'), findsNothing);

    // 2. Authenticated state -> shows listing form
    await provider.register(
      name: 'Adam',
      email: 'adam@czytella.pl',
      password: 'password123',
      city: 'Kraków',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: CreateListingDialog(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Dodaj nowe ogłoszenie'), findsOneWidget);
    expect(find.text('Tytuł książki *'), findsOneWidget);
    expect(find.text('Wymagane logowanie'), findsNothing);
  });

  testWidgets('ListingDetailScreen hides edit and delete actions when logged out', (WidgetTester tester) async {
    final provider = CzytellaProvider();

    // Create a listing that has isUserListing flag or current_user
    final listing = Listing(
      id: 'listing_test_1',
      book: Book(
        id: 'book_test_1',
        title: 'Solaris',
        author: 'Stanisław Lem',
        isbn: '9788308060000',
        description: 'Klasyka polskiej SF',
        condition: BookCondition.veryGood,
      ),
      sellerId: 'current_user',
      sellerName: 'Ja (Moje konto)',
      city: 'Kraków',
      latitude: 50.0647,
      longitude: 19.9450,
      isUserListing: true,
    );

    // 1. Unauthenticated state: edit/delete buttons and banner must NOT appear
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: ListingDetailScreen(listing: listing),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Edytuj ofertę'), findsNothing);
    expect(find.text('Usuń ogłoszenie'), findsNothing);
    expect(find.byTooltip('Edytuj ogłoszenie'), findsNothing);
    expect(find.byTooltip('Usuń ogłoszenie'), findsNothing);
    expect(find.text('To jest Twoje ogłoszenie. Możesz je edytować lub usunąć.'), findsNothing);
    expect(find.text('Napisz na czacie'), findsOneWidget);
    expect(find.text('Zaproponuj wymianę'), findsOneWidget);

    // 2. Now user logs in as owner: edit/delete actions should become available
    await provider.register(
      name: 'Ja (Moje konto)',
      email: 'owner@czytella.pl',
      password: 'password123',
      city: 'Kraków',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: ListingDetailScreen(listing: listing),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Edytuj ofertę'), findsOneWidget);
    expect(find.text('Usuń ogłoszenie'), findsOneWidget);
    expect(find.byTooltip('Edytuj ogłoszenie'), findsOneWidget);
    expect(find.byTooltip('Usuń ogłoszenie'), findsOneWidget);
    expect(find.text('To jest Twoje ogłoszenie. Możesz je edytować lub usunąć.'), findsOneWidget);

    // 3. User logs out: actions must be hidden again
    await provider.logout();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: ListingDetailScreen(listing: listing),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Edytuj ofertę'), findsNothing);
    expect(find.text('Usuń ogłoszenie'), findsNothing);
    expect(find.byTooltip('Edytuj ogłoszenie'), findsNothing);
    expect(find.byTooltip('Usuń ogłoszenie'), findsNothing);
    expect(find.text('To jest Twoje ogłoszenie. Możesz je edytować lub usunąć.'), findsNothing);
  });
}

