class UserProfile {
  final String id;
  final String name;
  final String email;
  final String city;
  final String? bio;
  final String? avatarUrl;
  final DateTime createdAt;
  final double rating;
  final int completedExchanges;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.city,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    this.rating = 5.0,
    this.completedExchanges = 0,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? city,
    String? bio,
    String? avatarUrl,
    DateTime? createdAt,
    double? rating,
    int? completedExchanges,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      completedExchanges: completedExchanges ?? this.completedExchanges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'city': city,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'rating': rating,
      'completedExchanges': completedExchanges,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'user_guest',
      name: json['name'] as String? ?? 'Czytelnik',
      email: json['email'] as String? ?? '',
      city: json['city'] as String? ?? 'Warszawa',
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      completedExchanges: (json['completedExchanges'] as num?)?.toInt() ?? 0,
    );
  }
}
