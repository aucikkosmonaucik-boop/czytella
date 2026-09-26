import 'package:flutter_test/flutter_test.dart';
import 'package:czytella/services/isbn_lookup_service.dart';

void main() {
  group('IsbnLookupService Tests', () {
    test('normalizes ISBN with various spaces, dashes and case', () {
      expect(IsbnLookupService.normalizeIsbn(' 978-83-7578-063-5 '), '9788375780635');
      expect(IsbnLookupService.normalizeIsbn('0-306-40615-2'), '0306406152');
      expect(IsbnLookupService.normalizeIsbn('0-19-853453-x'), '019853453X');
      expect(IsbnLookupService.normalizeIsbn('ISBN: 978 83 240 7984 1'), '9788324079841');
    });

    test('validates correct ISBN-10 and ISBN-13 formats', () {
      expect(IsbnLookupService.isValidIsbnFormat('9788375780635'), isTrue);
      expect(IsbnLookupService.isValidIsbnFormat('019853453X'), isTrue);
      expect(IsbnLookupService.isValidIsbnFormat('978-83-7578-063-5'), isTrue);
      expect(IsbnLookupService.isValidIsbnFormat('123'), isFalse);
      expect(IsbnLookupService.isValidIsbnFormat('9788375780635999'), isFalse);
    });

    test('instant lookup for curated demo ISBNs', () async {
      final book = await IsbnLookupService.lookupIsbn('9788375780635');
      expect(book, isNotNull);
      expect(book!.title, contains('Ostatnie życzenie'));
      expect(book.author, contains('Sapkowski'));
    });

    test('fallback book object returned for novel ISBNs', () async {
      // 13-digit dummy ISBN
      const dummyIsbn = '9999999999999';
      final book = await IsbnLookupService.lookupIsbn(dummyIsbn);
      expect(book, isNotNull);
      expect(book!.isbn, dummyIsbn);
      expect(book.title, contains('ISBN: 9999999999999'));
    });
  });
}
