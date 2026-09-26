import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../models/wishlist_book.dart';
import '../models/listing.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/distance_service.dart';
import '../services/sample_data.dart';

class CzytellaProvider with ChangeNotifier {
  // Current user location
  String _currentCity = 'Warszawa';
  double _userLatitude = 52.2297;
  double _userLongitude = 21.0122;

  // User Profile & Authentication
  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Data lists
  List<Listing> _listings = [];
  List<UserBook> _userBooks = SampleData.getInitialUserBooks();
  List<WishlistBook> _wishlist = SampleData.getInitialWishlist();
  List<ChatConversation> _conversations = SampleData.getInitialConversations();

  // Filter state
  String _searchQuery = '';
  String? _selectedCityFilter; // null = all
  double? _radiusFilterKm; // e.g. 5.0 for "w promieniu 5 km"
  ListingType? _typeFilter; // null = all
  String? _categoryFilter;
  String _sortBy = 'distance'; // 'distance', 'newest', 'price'

  bool _isInitialized = false;

  CzytellaProvider() {
    _loadInitialData();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  String get currentCity => _currentCity;
  double get userLatitude => _userLatitude;
  double get userLongitude => _userLongitude;

  List<Listing> get allListings => _listings;
  List<UserBook> get userBooks => _userBooks;
  List<WishlistBook> get wishlist => _wishlist;
  List<ChatConversation> get conversations => _conversations;

  String get searchQuery => _searchQuery;
  String? get selectedCityFilter => _selectedCityFilter;
  double? get radiusFilterKm => _radiusFilterKm;
  ListingType? get typeFilter => _typeFilter;
  String? get categoryFilter => _categoryFilter;
  String get sortBy => _sortBy;

  int get totalUnreadChats =>
      _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);

  // Filtered listings logic
  List<Listing> get filteredListings {
    var result = List<Listing>.from(_listings);

    // 1. Text Search Filter (Title, Author, ISBN, Categories)
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      result = result.where((item) {
        final title = item.book.title.toLowerCase();
        final author = item.book.author.toLowerCase();
        final isbn = item.book.isbn.toLowerCase();
        final categories = item.book.categories.join(' ').toLowerCase();
        return title.contains(query) ||
            author.contains(query) ||
            isbn.contains(query) ||
            categories.contains(query);
      }).toList();
    }

    // 2. City Filter (exact city match)
    if (_selectedCityFilter != null &&
        _selectedCityFilter != 'Wszystkie' &&
        _selectedCityFilter!.isNotEmpty) {
      result = result.where((item) {
        return item.city.toLowerCase() == _selectedCityFilter!.toLowerCase();
      }).toList();
    }

    // 3. Radius Filter ("w promieniu 5 km", 10 km, etc.)
    if (_radiusFilterKm != null) {
      result = result.where((item) {
        final dist = DistanceService.calculateDistanceKm(
          lat1: _userLatitude,
          lon1: _userLongitude,
          lat2: item.latitude,
          lon2: item.longitude,
        );
        return dist <= _radiusFilterKm!;
      }).toList();
    }

    // 4. Offer Type Filter (exchange / sale)
    if (_typeFilter != null) {
      result = result.where((item) {
        if (_typeFilter == ListingType.exchange) {
          return item.type == ListingType.exchange ||
              item.type == ListingType.both;
        } else if (_typeFilter == ListingType.sale) {
          return item.type == ListingType.sale || item.type == ListingType.both;
        }
        return true;
      }).toList();
    }

    // 5. Category Filter
    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      result = result.where((item) {
        return item.book.categories.any((c) =>
            c.toLowerCase().contains(_categoryFilter!.toLowerCase()));
      }).toList();
    }

    // 6. Sorting
    result.sort((a, b) {
      if (_sortBy == 'distance') {
        final distA = DistanceService.calculateDistanceKm(
          lat1: _userLatitude,
          lon1: _userLongitude,
          lat2: a.latitude,
          lon2: a.longitude,
        );
        final distB = DistanceService.calculateDistanceKm(
          lat1: _userLatitude,
          lon1: _userLongitude,
          lat2: b.latitude,
          lon2: b.longitude,
        );
        return distA.compareTo(distB);
      } else if (_sortBy == 'newest') {
        return b.createdAt.compareTo(a.createdAt);
      } else if (_sortBy == 'price') {
        final priceA = a.price ?? 0;
        final priceB = b.price ?? 0;
        return priceA.compareTo(priceB);
      }
      return 0;
    });

    return result;
  }

  // Calculate distance for a listing
  double getDistanceFromUser(Listing listing) {
    return DistanceService.calculateDistanceKm(
      lat1: _userLatitude,
      lon1: _userLongitude,
      lat2: listing.latitude,
      lon2: listing.longitude,
    );
  }

  // Matches between community listings and wishlist items
  List<Listing> getMatchesForWishlist(WishlistBook wish) {
    return _listings.where((l) {
      if (wish.isbn != null && wish.isbn!.isNotEmpty && l.book.isbn.isNotEmpty) {
        if (l.book.isbn.replaceAll(RegExp(r'[-\s]'), '') ==
            wish.isbn!.replaceAll(RegExp(r'[-\s]'), '')) {
          return true;
        }
      }
      final wishTitle = wish.title.toLowerCase().trim();
      final listTitle = l.book.title.toLowerCase().trim();
      return listTitle.contains(wishTitle) || wishTitle.contains(listTitle);
    }).toList();
  }

  // --- ACTIONS & MUTATIONS ---

  void setUserLocation({
    required String cityName,
    required double latitude,
    required double longitude,
  }) {
    _currentCity = cityName;
    _userLatitude = latitude;
    _userLongitude = longitude;
    notifyListeners();
    _saveState();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCityFilter(String? city) {
    _selectedCityFilter = city;
    notifyListeners();
  }

  void setRadiusFilter(double? radiusKm) {
    _radiusFilterKm = radiusKm;
    notifyListeners();
  }

  void setTypeFilter(ListingType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCityFilter = null;
    _radiusFilterKm = null;
    _typeFilter = null;
    _categoryFilter = null;
    _sortBy = 'distance';
    notifyListeners();
  }

  // User Books (Tab 1)
  void addUserBook(UserBook userBook) {
    _userBooks.insert(0, userBook);
    notifyListeners();
    _saveState();
  }

  void removeUserBook(String id) {
    _userBooks.removeWhere((b) => b.id == id);
    notifyListeners();
    _saveState();
  }

  void publishUserBookAsListing(
    UserBook userBook, {
    required double? price,
    required ListingType type,
    String? exchangePreferences,
    String? district,
  }) {
    // 1. Mark as listed in shelf
    final index = _userBooks.indexWhere((b) => b.id == userBook.id);
    if (index != -1) {
      final userBookType = type == ListingType.exchange
          ? UserBookType.forExchange
          : type == ListingType.sale
              ? UserBookType.forSale
              : UserBookType.both;
      _userBooks[index] = _userBooks[index].copyWith(
        isListed: true,
        price: price,
        type: userBookType,
        preferredExchangeGenres: exchangePreferences,
      );
    }

    // 2. Add to marketplace listings
    final newListing = Listing(
      id: 'listing_user_${DateTime.now().millisecondsSinceEpoch}',
      book: userBook.book,
      sellerId: 'current_user',
      sellerName: 'Ja (Moje konto)',
      sellerRating: 5.0,
      completedExchangesCount: 3,
      city: _currentCity,
      district: district ?? 'Moja lokalizacja',
      latitude: _userLatitude,
      longitude: _userLongitude,
      type: type,
      price: price,
      exchangePreferences: exchangePreferences,
      isUserListing: true,
    );

    _listings.insert(0, newListing);
    notifyListeners();
    _saveState();
    ApiService.createListing(newListing);
  }

  void createDirectListing({
    required Book book,
    required ListingType type,
    required double? price,
    String? exchangePreferences,
    String? district,
    String? city,
    double? latitude,
    double? longitude,
  }) {
    final effectiveCity =
        (city != null && city.trim().isNotEmpty) ? city.trim() : _currentCity;
    double lat = latitude ?? _userLatitude;
    double lon = longitude ?? _userLongitude;
    if (city != null && city.trim().isNotEmpty && latitude == null) {
      final found = DistanceService.findCityByName(city);
      lat = found.latitude;
      lon = found.longitude;
    }

    // Add to user shelf
    final userBook = UserBook(
      id: 'ub_${DateTime.now().millisecondsSinceEpoch}',
      book: book,
      type: type == ListingType.exchange
          ? UserBookType.forExchange
          : type == ListingType.sale
              ? UserBookType.forSale
              : UserBookType.both,
      price: price,
      isListed: true,
      preferredExchangeGenres: exchangePreferences,
    );
    _userBooks.insert(0, userBook);

    // Add to listings
    final newListing = Listing(
      id: 'listing_user_${DateTime.now().millisecondsSinceEpoch}',
      book: book,
      sellerId: _currentUser?.id ?? 'current_user',
      sellerName: _currentUser?.name ?? 'Ja (Moje konto)',
      sellerRating: _currentUser?.rating ?? 5.0,
      completedExchangesCount: _currentUser?.completedExchanges ?? 3,
      city: effectiveCity,
      district: district ?? 'Moja dzielnica',
      latitude: lat,
      longitude: lon,
      type: type,
      price: price,
      exchangePreferences: exchangePreferences,
      isUserListing: true,
    );
    _listings.insert(0, newListing);
    notifyListeners();
    _saveState();
    ApiService.createListing(newListing);
  }

  void updateListing(Listing updatedListing) {
    final index = _listings.indexWhere((l) => l.id == updatedListing.id);
    if (index != -1) {
      _listings[index] = updatedListing;
      // Also sync matching user shelf book
      final ubIndex = _userBooks.indexWhere((b) =>
          b.book.id == updatedListing.book.id ||
          b.book.title == updatedListing.book.title);
      if (ubIndex != -1) {
        _userBooks[ubIndex] = _userBooks[ubIndex].copyWith(
          book: updatedListing.book,
          price: updatedListing.price,
          type: updatedListing.type == ListingType.exchange
              ? UserBookType.forExchange
              : updatedListing.type == ListingType.sale
                  ? UserBookType.forSale
                  : UserBookType.both,
          preferredExchangeGenres: updatedListing.exchangePreferences,
        );
      }
      notifyListeners();
      _saveState();
      ApiService.updateListing(updatedListing);
    }
  }

  void updateUserBook(UserBook updatedUserBook) {
    final index = _userBooks.indexWhere((b) => b.id == updatedUserBook.id);
    if (index != -1) {
      _userBooks[index] = updatedUserBook;
      // Sync matching listing
      final listingIndex = _listings.indexWhere((l) =>
          l.book.id == updatedUserBook.book.id ||
          l.book.title == updatedUserBook.book.title);
      if (listingIndex != -1) {
        if (!updatedUserBook.isListed) {
          final removed = _listings.removeAt(listingIndex);
          ApiService.deleteListing(removed.id);
        } else {
          final updatedListing = _listings[listingIndex].copyWith(
            book: updatedUserBook.book,
            price: updatedUserBook.price,
            type: updatedUserBook.type == UserBookType.forExchange
                ? ListingType.exchange
                : updatedUserBook.type == UserBookType.forSale
                    ? ListingType.sale
                    : ListingType.both,
            exchangePreferences: updatedUserBook.preferredExchangeGenres,
          );
          _listings[listingIndex] = updatedListing;
          ApiService.updateListing(updatedListing);
        }
      }
      notifyListeners();
      _saveState();
    }
  }

  void removeListing(String listingId) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      final listing = _listings[index];
      // Mark matching shelf book as unlisted
      final ubIndex = _userBooks.indexWhere((b) =>
          b.book.id == listing.book.id || b.book.title == listing.book.title);
      if (ubIndex != -1) {
        _userBooks[ubIndex] = _userBooks[ubIndex].copyWith(isListed: false);
      }
      _listings.removeAt(index);
      notifyListeners();
      _saveState();
      ApiService.deleteListing(listingId);
    }
  }

  // Wishlist (Tab 2)
  void addWishlistBook(WishlistBook wish) {
    _wishlist.insert(0, wish);
    notifyListeners();
    _saveState();
  }

  void removeWishlistBook(String id) {
    _wishlist.removeWhere((w) => w.id == id);
    notifyListeners();
    _saveState();
  }

  // Chat methods
  ChatConversation getOrCreateConversationForListing(Listing listing) {
    // Check if conversation already exists for this listing
    final existingIndex = _conversations.indexWhere((c) =>
        c.listingId == listing.id ||
        (c.otherUserId == listing.sellerId && c.bookTitle == listing.book.title));

    if (existingIndex != -1) {
      return _conversations[existingIndex];
    }

    // Create new conversation
    final newConv = ChatConversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      listingId: listing.id,
      bookTitle: listing.book.title,
      bookAuthor: listing.book.author,
      bookCoverUrl: listing.book.coverUrl,
      otherUserId: listing.sellerId,
      otherUserName: listing.sellerName,
      otherUserCity: listing.district != null
          ? '${listing.city}, ${listing.district}'
          : listing.city,
      messages: [],
    );

    _conversations.insert(0, newConv);
    notifyListeners();
    _saveState();
    return newConv;
  }

  void markConversationAsRead(String conversationId) {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1 && _conversations[idx].unreadCount > 0) {
      _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
      notifyListeners();
      _saveState();
    }
  }

  void deleteConversation(String conversationId) {
    _conversations.removeWhere((c) => c.id == conversationId);
    notifyListeners();
    _saveState();
  }

  void sendMessage(
    String conversationId,
    String text, {
    ExchangeProposal? proposal,
  }) {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;

    final userMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'current_user',
      senderName: 'Ja',
      text: text,
      isMe: true,
      proposal: proposal,
    );

    final currentMessages = List<ChatMessage>.from(_conversations[idx].messages);
    currentMessages.add(userMessage);

    _conversations[idx] = _conversations[idx].copyWith(
      messages: currentMessages,
      updatedAt: DateTime.now(),
    );

    notifyListeners();
    _saveState();
  }

  void updateProposalStatus(
    String conversationId,
    String proposalId,
    ProposalStatus newStatus,
  ) {
    final convIdx = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIdx == -1) return;

    final conv = _conversations[convIdx];
    final updatedMessages = conv.messages.map((m) {
      if (m.proposal != null && m.proposal!.id == proposalId) {
        return ChatMessage(
          id: m.id,
          senderId: m.senderId,
          senderName: m.senderName,
          text: m.text,
          timestamp: m.timestamp,
          isMe: m.isMe,
          proposal: m.proposal!.copyWith(status: newStatus),
        );
      }
      return m;
    }).toList();

    _conversations[convIdx] = conv.copyWith(messages: updatedMessages);
    notifyListeners();
    _saveState();
  }

  // --- USER AUTH & PROFILE ---

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String city,
    String? bio,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    if (cleanEmail.isEmpty || cleanName.isEmpty) return false;

    final profile = UserProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      email: cleanEmail,
      city: city.trim().isNotEmpty ? city.trim() : _currentCity,
      bio: bio?.trim(),
      createdAt: DateTime.now(),
      rating: 5.0,
      completedExchanges: 0,
    );

    _currentUser = profile;
    _currentCity = profile.city;
    await _saveState();
    notifyListeners();
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final savedProfileJson = prefs.getString('czytella_user_profile');
    if (savedProfileJson != null) {
      try {
        final decoded = json.decode(savedProfileJson);
        final profile = UserProfile.fromJson(decoded);
        if (profile.email.toLowerCase() == cleanEmail) {
          _currentUser = profile;
          _currentCity = profile.city;
          await _saveState();
          notifyListeners();
          return true;
        }
      } catch (_) {}
    }

    final namePart = cleanEmail.split('@').first;
    final formattedName = namePart.isNotEmpty
        ? '${namePart[0].toUpperCase()}${namePart.substring(1)}'
        : 'Czytelnik';

    _currentUser = UserProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: formattedName,
      email: cleanEmail,
      city: _currentCity,
      createdAt: DateTime.now(),
      rating: 5.0,
      completedExchanges: 0,
    );
    await _saveState();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('czytella_user_profile');
    await prefs.setBool('czytella_is_logged_in', false);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? city,
    String? bio,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      name: (name != null && name.trim().isNotEmpty) ? name.trim() : null,
      city: (city != null && city.trim().isNotEmpty) ? city.trim() : null,
      bio: bio?.trim(),
    );
    if (city != null && city.trim().isNotEmpty) {
      _currentCity = city.trim();
    }
    await _saveState();
    notifyListeners();
  }

  // --- PERSISTENCE ---

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Location
      _currentCity = prefs.getString('user_city') ?? 'Warszawa';
      _userLatitude = prefs.getDouble('user_lat') ?? 52.2297;
      _userLongitude = prefs.getDouble('user_lon') ?? 21.0122;

      // User Profile & Authentication
      if (_currentUser == null) {
        final isLoggedIn = prefs.getBool('czytella_is_logged_in') ?? false;
        final profileJson = prefs.getString('czytella_user_profile');
        if (isLoggedIn && profileJson != null) {
          try {
            final decoded = json.decode(profileJson);
            _currentUser = UserProfile.fromJson(decoded);
          } catch (_) {
            _currentUser = null;
          }
        }
      }

      // Listings (clean up any legacy cached sample listings)
      final listingsJson = prefs.getString('czytella_listings_v2');
      if (listingsJson != null) {
        final List decoded = json.decode(listingsJson);
        _listings = decoded
            .map((e) => Listing.fromJson(e))
            .where((l) => l.isUserListing)
            .toList();
      } else {
        prefs.remove('czytella_listings');
        _listings = [];
      }

      // User books (clean up any legacy cached sample books ub_1, ub_2)
      final userBooksJson = prefs.getString('czytella_user_books');
      if (userBooksJson != null) {
        final List decoded = json.decode(userBooksJson);
        _userBooks = decoded
            .map((e) => UserBook.fromJson(e))
            .where((b) => b.id != 'ub_1' && b.id != 'ub_2')
            .toList();
      } else {
        _userBooks = [];
      }

      // Wishlist (clean up any legacy cached sample wishlist books w_1, w_2, w_3)
      final wishlistJson = prefs.getString('czytella_wishlist');
      if (wishlistJson != null) {
        final List decoded = json.decode(wishlistJson);
        _wishlist = decoded
            .map((e) => WishlistBook.fromJson(e))
            .where((w) => w.id != 'w_1' && w.id != 'w_2' && w.id != 'w_3')
            .toList();
      } else {
        _wishlist = [];
      }

      // Conversations
      _conversations = SampleData.getInitialConversations();
    } catch (e) {
      debugPrint('Error loading saved state: $e');
      _listings = [];
      _userBooks = [];
      _wishlist = [];
      _conversations = [];
      _currentUser = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
      _syncWithBackendListings();
    }
  }

  Future<void> _syncWithBackendListings() async {
    try {
      final remoteListings = await ApiService.fetchListings();
      if (remoteListings.isNotEmpty) {
        _listings = remoteListings.map((l) {
          final isMine = _currentUser != null && l.sellerId == _currentUser!.id;
          return l.copyWith(isUserListing: isMine || l.isUserListing);
        }).toList();
        notifyListeners();
        _saveState();
      }
    } catch (e) {
      debugPrint('Sync with backend listings error: $e');
    }
  }

  Future<void> refreshListings() async {
    await _syncWithBackendListings();
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_city', _currentCity);
      await prefs.setDouble('user_lat', _userLatitude);
      await prefs.setDouble('user_lon', _userLongitude);

      if (_currentUser != null) {
        await prefs.setString(
            'czytella_user_profile', json.encode(_currentUser!.toJson()));
        await prefs.setBool('czytella_is_logged_in', true);
      } else {
        await prefs.remove('czytella_user_profile');
        await prefs.setBool('czytella_is_logged_in', false);
      }

      final listingsJson =
          json.encode(_listings.map((l) => l.toJson()).toList());
      await prefs.setString('czytella_listings_v2', listingsJson);

      final userBooksJson =
          json.encode(_userBooks.map((b) => b.toJson()).toList());
      await prefs.setString('czytella_user_books', userBooksJson);

      final wishlistJson =
          json.encode(_wishlist.map((w) => w.toJson()).toList());
      await prefs.setString('czytella_wishlist', wishlistJson);
    } catch (e) {
      debugPrint('Error saving state: $e');
    }
  }
}
