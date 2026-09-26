import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class SampleIsbn {
  final String isbn;
  final String title;
  final String author;
  final String genre;
  final String? coverUrl;

  const SampleIsbn({
    required this.isbn,
    required this.title,
    required this.author,
    required this.genre,
    this.coverUrl,
  });
}

class IsbnLookupService {
  /// Curated preset books for instant lookup and scanner testing
  static const List<SampleIsbn> demoIsbns = [
    SampleIsbn(
      isbn: '9788308064177',
      title: 'Bieguni',
      author: 'Olga Tokarczuk',
      genre: 'Literatura piękna',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9788308064177-L.jpg',
    ),
    SampleIsbn(
      isbn: '9788375780635',
      title: 'Ostatnie życzenie',
      author: 'Andrzej Sapkowski',
      genre: 'Fantastyka',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9788375780635-L.jpg',
    ),
    SampleIsbn(
      isbn: '9788375155280',
      title: 'Kasacja',
      author: 'Remigiusz Mróz',
      genre: 'Kryminał',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9788375155280-L.jpg',
    ),
    SampleIsbn(
      isbn: '9788308047972',
      title: 'Lód',
      author: 'Jacek Dukaj',
      genre: 'Fantastyka / Sci-Fi',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9788308047972-L.jpg',
    ),
    SampleIsbn(
      isbn: '9788308075302',
      title: 'Solaris',
      author: 'Stanisław Lem',
      genre: 'Science Fiction',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9788308075302-L.jpg',
    ),
    SampleIsbn(
      isbn: '9788328700581',
      title: '1984',
      author: 'George Orwell',
      genre: 'Klasyka / Dystopia',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9788328700581-L.jpg',
    ),
    SampleIsbn(
      isbn: '9788381162470',
      title: 'Lśnienie',
      author: 'Stephen King',
      genre: 'Horror / Thriller',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9788381162470-L.jpg',
    ),
    SampleIsbn(
      isbn: '9788324404551',
      title: 'Hobbit, czyli tam i z powrotem',
      author: 'J.R.R. Tolkien',
      genre: 'Fantastyka',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/9788324404551-L.jpg',
    ),
  ];

  /// Normalize ISBN string: remove dashes, spaces, and non-ISBN characters
  static String normalizeIsbn(String input) {
    return input.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
  }

  /// Check if string looks like valid ISBN-10 or ISBN-13
  static bool isValidIsbnFormat(String input) {
    final cleaned = normalizeIsbn(input);
    if (cleaned.length == 10) {
      return RegExp(r'^\d{9}[\dX]$').hasMatch(cleaned);
    } else if (cleaned.length == 13) {
      return RegExp(r'^\d{13}$').hasMatch(cleaned);
    }
    return false;
  }

  static String _cleanBnTitle(String rawTitle) {
    var title = rawTitle.trim();
    if (title.contains(' / ')) {
      final parts = title.split(' / ');
      title = parts[0].trim();
    }
    title = title.replaceAll(RegExp(r'[\s\.,;:]+$'), '');
    return title.isEmpty ? rawTitle : title;
  }

  static String _cleanBnAuthor(String rawAuthor) {
    var author = rawAuthor.trim();
    author = author.replaceAll(RegExp(r'\s*\(\s*\d{4}[^)]*\)'), '');
    final commaIndex = author.indexOf(',');
    if (commaIndex != -1) {
      final lastName = author.substring(0, commaIndex).trim();
      final rest = author.substring(commaIndex + 1).trim();
      final firstName = rest.split(RegExp(r'\s+')).first;
      author = '$firstName $lastName';
    }
    author = author.replaceAll(RegExp(r'[\s\.,;:]+$'), '');
    return author.isEmpty ? rawAuthor : author;
  }

  /// Look up book details by ISBN.
  /// 1) Checks preset catalog for instant recognition
  /// 2) Queries Biblioteka Narodowa (National Library of Poland) API
  /// 3) Queries Google Books API
  /// 4) Falls back to Open Library API
  /// 5) Generates editable fallback book record
  static Future<Book?> lookupIsbn(String rawIsbn) async {
    final isbn = normalizeIsbn(rawIsbn);
    if (isbn.isEmpty) return null;

    // 1) Check fast preset catalog first
    final presetMatch = demoIsbns.firstWhere(
      (p) => normalizeIsbn(p.isbn) == isbn,
      orElse: () => const SampleIsbn(isbn: '', title: '', author: '', genre: ''),
    );

    if (presetMatch.isbn.isNotEmpty) {
      return Book(
        id: 'book_${DateTime.now().millisecondsSinceEpoch}',
        isbn: isbn,
        title: presetMatch.title,
        author: presetMatch.author,
        categories: [presetMatch.genre],
        coverUrl: presetMatch.coverUrl,
        description:
            'Książka: ${presetMatch.title} autorstwa ${presetMatch.author}. Gatunek: ${presetMatch.genre}.',
        condition: BookCondition.veryGood,
      );
    }

    // 2) Try Biblioteka Narodowa (data.bn.org.pl) API for Polish books
    try {
      final bnUrl = Uri.parse(
        'https://data.bn.org.pl/api/institutions/bibs.json?isbnIssn=$isbn',
      );
      final response = await http.get(bnUrl).timeout(
        const Duration(seconds: 4),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final bibs = data['bibs'] as List<dynamic>?;
        if (bibs != null && bibs.isNotEmpty) {
          final firstBib = bibs[0] as Map<String, dynamic>;
          final rawTitle = firstBib['title'] as String?;
          final rawAuthor = firstBib['author'] as String?;

          if (rawTitle != null && rawTitle.isNotEmpty) {
            final title = _cleanBnTitle(rawTitle);
            final author = rawAuthor != null && rawAuthor.isNotEmpty
                ? _cleanBnAuthor(rawAuthor)
                : 'Autor nieznany';
            final publisher = firstBib['publisher'] as String?;
            final pubYearStr = firstBib['publicationYear'] as String?;
            int? publishYear;
            if (pubYearStr != null) {
              final yearMatch = RegExp(r'\b\d{4}\b').firstMatch(pubYearStr);
              if (yearMatch != null) {
                publishYear = int.tryParse(yearMatch.group(0)!);
              }
            }
            final genre = (firstBib['genre'] as String?) ??
                (firstBib['domain'] as String?) ??
                'Literatura';

            // Try to enrich cover from Google Books
            String? coverUrl;
            try {
              final googleUrl = Uri.parse(
                'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn',
              );
              final gRes = await http.get(googleUrl).timeout(
                const Duration(seconds: 3),
              );
              if (gRes.statusCode == 200) {
                final gData = json.decode(gRes.body);
                if ((gData['totalItems'] ?? 0) > 0 &&
                    gData['items'] != null &&
                    gData['items'].isNotEmpty) {
                  final vInfo = gData['items'][0]['volumeInfo'] ?? {};
                  if (vInfo['imageLinks'] != null) {
                    coverUrl = vInfo['imageLinks']['thumbnail'] ??
                        vInfo['imageLinks']['smallThumbnail'];
                    if (coverUrl != null && coverUrl.startsWith('http://')) {
                      coverUrl = coverUrl.replaceFirst('http://', 'https://');
                    }
                  }
                }
              }
            } catch (_) {}

            coverUrl ??= 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg?default=false';

            return Book(
              id: 'book_${DateTime.now().millisecondsSinceEpoch}',
              isbn: isbn,
              title: title,
              author: author,
              publisher: publisher?.replaceAll(RegExp(r'[\s\.,;:]+$'), ''),
              publishYear: publishYear,
              categories: [genre],
              description: 'Książka: $title, autor: $author.',
              coverUrl: coverUrl,
              condition: BookCondition.veryGood,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Biblioteka Narodowa lookup error: $e');
    }

    // 3) Try Google Books API
    try {
      final googleUrl = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn',
      );
      final response = await http.get(googleUrl).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final totalItems = data['totalItems'] ?? 0;
        if (totalItems > 0 && data['items'] != null && data['items'].isNotEmpty) {
          final volumeInfo = data['items'][0]['volumeInfo'] ?? {};
          final title = volumeInfo['title'] ?? 'Nieznany tytuł';
          final authors = (volumeInfo['authors'] as List<dynamic>?)
                  ?.join(', ') ??
              'Nieznany autor';
          final description = volumeInfo['description'] ?? '';
          final publisher = volumeInfo['publisher'];
          final pageCount = volumeInfo['pageCount'] as int?;
          final publishedDate = volumeInfo['publishedDate'] as String?;
          int? publishYear;
          if (publishedDate != null && publishedDate.length >= 4) {
            publishYear = int.tryParse(publishedDate.substring(0, 4));
          }

          final categories = (volumeInfo['categories'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

          String? coverUrl;
          if (volumeInfo['imageLinks'] != null) {
            coverUrl = volumeInfo['imageLinks']['thumbnail'] ??
                volumeInfo['imageLinks']['smallThumbnail'];
            if (coverUrl != null && coverUrl.startsWith('http://')) {
              coverUrl = coverUrl.replaceFirst('http://', 'https://');
            }
          }

          coverUrl ??= 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg';

          return Book(
            id: 'book_${DateTime.now().millisecondsSinceEpoch}',
            isbn: isbn,
            title: title,
            author: authors,
            description: description,
            coverUrl: coverUrl,
            publisher: publisher,
            publishYear: publishYear,
            pageCount: pageCount,
            categories: categories.isNotEmpty ? categories : ['Literatura'],
            condition: BookCondition.veryGood,
          );
        }
      }
    } catch (e) {
      debugPrint('Google Books lookup failed: $e');
    }

    // 4) Try Open Library API
    try {
      final openLibUrl = Uri.parse(
        'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data',
      );
      final response = await http.get(openLibUrl).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final key = 'ISBN:$isbn';
        if (data.containsKey(key)) {
          final bookData = data[key];
          final title = bookData['title'] ?? 'Nieznany tytuł';
          final authorsList = bookData['authors'] as List<dynamic>?;
          final author = authorsList != null && authorsList.isNotEmpty
              ? authorsList.map((a) => a['name']).join(', ')
              : 'Nieznany autor';
          final numberOfPages = bookData['number_of_pages'] as int?;
          final publishDate = bookData['publish_date'] as String?;
          int? publishYear;
          if (publishDate != null) {
            final match = RegExp(r'\b\d{4}\b').firstMatch(publishDate);
            if (match != null) {
              publishYear = int.tryParse(match.group(0)!);
            }
          }

          String? coverUrl;
          if (bookData['cover'] != null) {
            coverUrl = bookData['cover']['large'] ??
                bookData['cover']['medium'] ??
                bookData['cover']['small'];
          }
          coverUrl ??= 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg?default=false';

          return Book(
            id: 'book_${DateTime.now().millisecondsSinceEpoch}',
            isbn: isbn,
            title: title,
            author: author,
            coverUrl: coverUrl,
            pageCount: numberOfPages,
            publishYear: publishYear,
            categories: ['Literatura'],
            condition: BookCondition.veryGood,
          );
        }
      }
    } catch (e) {
      debugPrint('OpenLibrary lookup failed: $e');
    }

    // 5) Fallback book with the ISBN so user can still add it
    return Book(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      isbn: isbn,
      title: 'Książka ISBN: $isbn',
      author: 'Autor do uzupełnienia',
      description: 'Zeskanowano kod ISBN: $isbn. Możesz edytować tytuł i dane książki.',
      coverUrl: 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg?default=false',
      condition: BookCondition.veryGood,
    );
  }
}
