import 'book.dart';

enum UserBookType {
  forExchange,
  forSale,
  both,
}

extension UserBookTypeExtension on UserBookType {
  String get label {
    switch (this) {
      case UserBookType.forExchange:
        return 'Na wymianę';
      case UserBookType.forSale:
        return 'Na sprzedaż';
      case UserBookType.both:
        return 'Wymiana lub sprzedaż';
    }
  }

  static UserBookType fromString(String? value) {
    switch (value) {
      case 'forExchange':
      case 'Na wymianę':
        return UserBookType.forExchange;
      case 'forSale':
      case 'Na sprzedaż':
        return UserBookType.forSale;
      case 'both':
      case 'Wymiana lub sprzedaż':
      default:
        return UserBookType.both;
    }
  }
}

class UserBook {
  final String id;
  final Book book;
  final UserBookType type;
  final double? price; // Price in PLN if forSale or both
  final bool isListed;
  final DateTime addedAt;
  final String? preferredExchangeGenres;

  UserBook({
    required this.id,
    required this.book,
    this.type = UserBookType.both,
    this.price,
    this.isListed = false,
    DateTime? addedAt,
    this.preferredExchangeGenres,
  }) : addedAt = addedAt ?? DateTime.now();

  UserBook copyWith({
    String? id,
    Book? book,
    UserBookType? type,
    double? price,
    bool? isListed,
    DateTime? addedAt,
    String? preferredExchangeGenres,
  }) {
    return UserBook(
      id: id ?? this.id,
      book: book ?? this.book,
      type: type ?? this.type,
      price: price ?? this.price,
      isListed: isListed ?? this.isListed,
      addedAt: addedAt ?? this.addedAt,
      preferredExchangeGenres:
          preferredExchangeGenres ?? this.preferredExchangeGenres,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book': book.toJson(),
      'type': type.name,
      'price': price,
      'isListed': isListed,
      'addedAt': addedAt.toIso8601String(),
      'preferredExchangeGenres': preferredExchangeGenres,
    };
  }

  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      id: json['id'] ?? '',
      book: Book.fromJson(json['book'] ?? {}),
      type: UserBookTypeExtension.fromString(json['type']),
      price: (json['price'] as num?)?.toDouble(),
      isListed: json['isListed'] ?? false,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'])
          : DateTime.now(),
      preferredExchangeGenres: json['preferredExchangeGenres'],
    );
  }
}
