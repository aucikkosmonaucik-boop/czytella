enum BookCondition {
  asNew,
  veryGood,
  good,
  acceptable,
}

extension BookConditionExtension on BookCondition {
  String get label {
    switch (this) {
      case BookCondition.asNew:
        return 'Jak nowa';
      case BookCondition.veryGood:
        return 'Bardzo dobry';
      case BookCondition.good:
        return 'Dobry';
      case BookCondition.acceptable:
        return 'Ślady używania';
    }
  }

  static BookCondition fromString(String? value) {
    switch (value) {
      case 'asNew':
      case 'Jak nowa':
        return BookCondition.asNew;
      case 'veryGood':
      case 'Bardzo dobry':
        return BookCondition.veryGood;
      case 'good':
      case 'Dobry':
        return BookCondition.good;
      case 'acceptable':
      case 'Ślady używania':
      default:
        return BookCondition.veryGood;
    }
  }
}

class Book {
  final String id;
  final String isbn;
  final String title;
  final String author;
  final String description;
  final String? coverUrl;
  final String? publisher;
  final int? publishYear;
  final int? pageCount;
  final List<String> categories;
  final BookCondition condition;

  const Book({
    required this.id,
    required this.isbn,
    required this.title,
    required this.author,
    this.description = '',
    this.coverUrl,
    this.publisher,
    this.publishYear,
    this.pageCount,
    this.categories = const [],
    this.condition = BookCondition.veryGood,
  });

  Book copyWith({
    String? id,
    String? isbn,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    String? publisher,
    int? publishYear,
    int? pageCount,
    List<String>? categories,
    BookCondition? condition,
  }) {
    return Book(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      publisher: publisher ?? this.publisher,
      publishYear: publishYear ?? this.publishYear,
      pageCount: pageCount ?? this.pageCount,
      categories: categories ?? this.categories,
      condition: condition ?? this.condition,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isbn': isbn,
      'title': title,
      'author': author,
      'description': description,
      'coverUrl': coverUrl,
      'publisher': publisher,
      'publishYear': publishYear,
      'pageCount': pageCount,
      'categories': categories,
      'condition': condition.name,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      isbn: json['isbn'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'],
      publisher: json['publisher'],
      publishYear: json['publishYear'],
      pageCount: json['pageCount'],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      condition: BookConditionExtension.fromString(json['condition']),
    );
  }
}
