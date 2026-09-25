enum WishlistPriority {
  high,
  medium,
  low,
}

extension WishlistPriorityExtension on WishlistPriority {
  String get label {
    switch (this) {
      case WishlistPriority.high:
        return 'Wysoki';
      case WishlistPriority.medium:
        return 'Średni';
      case WishlistPriority.low:
        return 'Niski';
    }
  }

  static WishlistPriority fromString(String? value) {
    switch (value) {
      case 'high':
      case 'Wysoki':
        return WishlistPriority.high;
      case 'medium':
      case 'Średni':
        return WishlistPriority.medium;
      case 'low':
      case 'Niski':
      default:
        return WishlistPriority.medium;
    }
  }
}

class WishlistBook {
  final String id;
  final String? isbn;
  final String title;
  final String author;
  final String? coverUrl;
  final String? notes;
  final double? maxBudget; // PLN
  final bool willingToExchange;
  final WishlistPriority priority;
  final DateTime addedAt;

  WishlistBook({
    required this.id,
    this.isbn,
    required this.title,
    required this.author,
    this.coverUrl,
    this.notes,
    this.maxBudget,
    this.willingToExchange = true,
    this.priority = WishlistPriority.medium,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  WishlistBook copyWith({
    String? id,
    String? isbn,
    String? title,
    String? author,
    String? coverUrl,
    String? notes,
    double? maxBudget,
    bool? willingToExchange,
    WishlistPriority? priority,
    DateTime? addedAt,
  }) {
    return WishlistBook(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      notes: notes ?? this.notes,
      maxBudget: maxBudget ?? this.maxBudget,
      willingToExchange: willingToExchange ?? this.willingToExchange,
      priority: priority ?? this.priority,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isbn': isbn,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'notes': notes,
      'maxBudget': maxBudget,
      'willingToExchange': willingToExchange,
      'priority': priority.name,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory WishlistBook.fromJson(Map<String, dynamic> json) {
    return WishlistBook(
      id: json['id'] ?? '',
      isbn: json['isbn'],
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      coverUrl: json['coverUrl'],
      notes: json['notes'],
      maxBudget: (json['maxBudget'] as num?)?.toDouble(),
      willingToExchange: json['willingToExchange'] ?? true,
      priority: WishlistPriorityExtension.fromString(json['priority']),
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'])
          : DateTime.now(),
    );
  }
}
