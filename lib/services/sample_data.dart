import '../models/book.dart';
import '../models/user_book.dart';
import '../models/wishlist_book.dart';
import '../models/listing.dart';
import '../models/chat_message.dart';

class SampleData {
  static List<Listing> getInitialListings() {
    return [];
  }

  static List<UserBook> getInitialUserBooks() {
    return [
      UserBook(
        id: 'ub_1',
        book: const Book(
          id: 'my_b_1',
          isbn: '9788308075302',
          title: 'Solaris',
          author: 'Stanisław Lem',
          description: 'Stan idealny, raz czytana, bez zagięć.',
          coverUrl: 'https://covers.openlibrary.org/b/isbn/9788308075302-L.jpg',
          publisher: 'Wydawnictwo Literackie',
          publishYear: 2021,
          pageCount: 264,
          categories: ['Science Fiction'],
          condition: BookCondition.asNew,
        ),
        type: UserBookType.both,
        price: 25.0,
        isListed: true,
        preferredExchangeGenres: 'Kryminał, Thriller, Klasyka',
      ),
      UserBook(
        id: 'ub_2',
        book: const Book(
          id: 'my_b_2',
          isbn: '9788375155280',
          title: 'Kasacja',
          author: 'Remigiusz Mróz',
          description: 'Dobry stan, drobne ślady czytania na grzbiecie.',
          coverUrl: 'https://covers.openlibrary.org/b/isbn/9788375155280-L.jpg',
          publisher: 'Czwarta Strona',
          publishYear: 2019,
          pageCount: 496,
          categories: ['Kryminał'],
          condition: BookCondition.good,
        ),
        type: UserBookType.forExchange,
        price: null,
        isListed: false,
        preferredExchangeGenres: 'Fantastyka, Dukaj, Sapkowski',
      ),
    ];
  }

  static List<WishlistBook> getInitialWishlist() {
    return [
      WishlistBook(
        id: 'w_1',
        isbn: '9788328700581',
        title: '1984',
        author: 'George Orwell',
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9788328700581-L.jpg',
        notes: 'Szukam wydania ze współczesnym przekładem, stan min. dobry.',
        maxBudget: 25.0,
        willingToExchange: true,
        priority: WishlistPriority.high,
      ),
      WishlistBook(
        id: 'w_2',
        isbn: '9788381162470',
        title: 'Lśnienie',
        author: 'Stephen King',
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9788381162470-L.jpg',
        notes: 'Chętnie wymienię na inną książkę z mojej półki.',
        maxBudget: 35.0,
        willingToExchange: true,
        priority: WishlistPriority.medium,
      ),
      WishlistBook(
        id: 'w_3',
        isbn: '9788324404551',
        title: 'Hobbit',
        author: 'J.R.R. Tolkien',
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9788324404551-L.jpg',
        notes: 'Dla młodszego rodzeństwa, ilustrowane wydanie mile widziane.',
        maxBudget: 30.0,
        willingToExchange: true,
        priority: WishlistPriority.low,
      ),
    ];
  }

  static List<ChatConversation> getInitialConversations() {
    return [
      ChatConversation(
        id: 'conv_1',
        listingId: 'list_1',
        bookTitle: 'Bieguni',
        bookAuthor: 'Olga Tokarczuk',
        bookCoverUrl: 'https://covers.openlibrary.org/b/isbn/9788308064177-L.jpg',
        otherUserId: 'seller_anna',
        otherUserName: 'Anna Kowalska',
        otherUserCity: 'Warszawa, Mokotów',
        messages: [
          ChatMessage(
            id: 'm_1',
            senderId: 'current_user',
            senderName: 'Ja',
            text: 'Dzień dobry! Czy ta książka jest nadal do wymiany?',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
            isMe: true,
          ),
          ChatMessage(
            id: 'm_2',
            senderId: 'seller_anna',
            senderName: 'Anna Kowalska',
            text:
                'Cześć! Tak, Bieguni są dostępni. Jesteś z Warszawy? Gdzie najbardziej pasowałoby Ci się spotkać?',
            timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
            isMe: false,
          ),
          ChatMessage(
            id: 'm_3',
            senderId: 'current_user',
            senderName: 'Ja',
            text:
                'Pracuję przy Rondzie Daszyńskiego, ale mogę podjechać na stację Metro Pole Mokotowskie!',
            timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
            isMe: true,
            proposal: ExchangeProposal(
              id: 'prop_1',
              offeredBookTitle: 'Solaris - Stanisław Lem',
              offeredBookCover:
                  'https://covers.openlibrary.org/b/isbn/9788308075302-L.jpg',
              requestedBookTitle: 'Bieguni - Olga Tokarczuk',
              proposedLocation: 'Metro Pole Mokotowskie (przy kawiarni)',
              status: ProposalStatus.accepted,
            ),
          ),
          ChatMessage(
            id: 'm_4',
            senderId: 'seller_anna',
            senderName: 'Anna Kowalska',
            text:
                'Świetnie! Lem bardzo mi odpowiada. Pasuje mi jutro o 17:30. Nie musimy wymieniać się telefonami, napiszemy tutaj jak będziemy na miejscu.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
            isMe: false,
          ),
        ],
        updatedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
        unreadCount: 0,
      ),
      ChatConversation(
        id: 'conv_2',
        listingId: 'list_3',
        bookTitle: 'Kasacja',
        bookAuthor: 'Remigiusz Mróz',
        bookCoverUrl: 'https://covers.openlibrary.org/b/isbn/9788375155280-L.jpg',
        otherUserId: 'seller_kasia',
        otherUserName: 'Kasia Zielińska',
        otherUserCity: 'Warszawa, Śródmieście',
        messages: [
          ChatMessage(
            id: 'm_20',
            senderId: 'seller_kasia',
            senderName: 'Kasia Zielińska',
            text: 'Cześć! Widziałam, że Kasacja Cię interesuje. Odbiór w Śródmieściu.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
            isMe: false,
          ),
        ],
        updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        unreadCount: 1,
      ),
    ];
  }
}
