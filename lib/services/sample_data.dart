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
    return [];
  }
}
