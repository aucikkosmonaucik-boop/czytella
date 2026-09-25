import 'book.dart';

enum ListingType {
  exchange,
  sale,
  both,
}

extension ListingTypeExtension on ListingType {
  String get label {
    switch (this) {
      case ListingType.exchange:
        return 'Tylko wymiana';
      case ListingType.sale:
        return 'Tylko sprzedaż';
      case ListingType.both:
        return 'Wymiana lub sprzedaż';
    }
  }

  String get shortBadge {
    switch (this) {
      case ListingType.exchange:
        return 'Wymiana';
      case ListingType.sale:
        return 'Sprzedaż';
      case ListingType.both:
        return 'Wymiana / Sprzedaż';
    }
  }

  static ListingType fromString(String? value) {
    switch (value) {
      case 'exchange':
      case 'Tylko wymiana':
      case 'Wymiana':
        return ListingType.exchange;
      case 'sale':
      case 'Tylko sprzedaż':
      case 'Sprzedaż':
        return ListingType.sale;
      case 'both':
      case 'Wymiana lub sprzedaż':
      case 'Wymiana / Sprzedaż':
      default:
        return ListingType.both;
    }
  }
}

class Listing {
  final String id;
  final Book book;
  final String sellerId;
  final String sellerName;
  final double sellerRating;
  final int completedExchangesCount;
  final String city;
  final String? district;
  final double latitude;
  final double longitude;
  final ListingType type;
  final double? price; // PLN
  final String? exchangePreferences;
  final DateTime createdAt;
  final bool isUserListing;

  Listing({
    required this.id,
    required this.book,
    required this.sellerId,
    required this.sellerName,
    this.sellerRating = 4.9,
    this.completedExchangesCount = 8,
    required this.city,
    this.district,
    required this.latitude,
    required this.longitude,
    this.type = ListingType.both,
    this.price,
    this.exchangePreferences,
    DateTime? createdAt,
    this.isUserListing = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Listing copyWith({
    String? id,
    Book? book,
    String? sellerId,
    String? sellerName,
    double? sellerRating,
    int? completedExchangesCount,
    String? city,
    String? district,
    double? latitude,
    double? longitude,
    ListingType? type,
    double? price,
    String? exchangePreferences,
    DateTime? createdAt,
    bool? isUserListing,
  }) {
    return Listing(
      id: id ?? this.id,
      book: book ?? this.book,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerRating: sellerRating ?? this.sellerRating,
      completedExchangesCount:
          completedExchangesCount ?? this.completedExchangesCount,
      city: city ?? this.city,
      district: district ?? this.district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      price: price ?? this.price,
      exchangePreferences: exchangePreferences ?? this.exchangePreferences,
      createdAt: createdAt ?? this.createdAt,
      isUserListing: isUserListing ?? this.isUserListing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book': book.toJson(),
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerRating': sellerRating,
      'completedExchangesCount': completedExchangesCount,
      'city': city,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'price': price,
      'exchangePreferences': exchangePreferences,
      'createdAt': createdAt.toIso8601String(),
      'isUserListing': isUserListing,
    };
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] ?? '',
      book: Book.fromJson(json['book'] ?? {}),
      sellerId: json['sellerId'] ?? '',
      sellerName: json['sellerName'] ?? 'Anonimowy Czytelnik',
      sellerRating: (json['sellerRating'] as num?)?.toDouble() ?? 4.8,
      completedExchangesCount: json['completedExchangesCount'] ?? 0,
      city: json['city'] ?? 'Warszawa',
      district: json['district'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 52.2297,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 21.0122,
      type: ListingTypeExtension.fromString(json['type']),
      price: (json['price'] as num?)?.toDouble(),
      exchangePreferences: json['exchangePreferences'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isUserListing: json['isUserListing'] ?? false,
    );
  }
}
