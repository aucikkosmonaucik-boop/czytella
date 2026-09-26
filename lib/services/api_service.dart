import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/listing.dart';

class ApiService {
  static const String _prefApiUrlKey = 'czytella_backend_api_url';
  
  // Default Railway production URL fallback (or empty for relative path on Web)
  static String _baseUrl = kIsWeb ? '' : 'https://czytella.up.railway.app';

  static String get baseUrl => _baseUrl;

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefApiUrlKey);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _baseUrl = savedUrl.trim();
      }
    } catch (e) {
      debugPrint('Error loading API URL: $e');
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiUrlKey, _baseUrl);
  }

  static Uri _getUri(String path) {
    if (_baseUrl.isEmpty && kIsWeb) {
      // Relative path for same-origin web deployment
      return Uri.parse(path);
    }
    final cleanBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  /// Checks if the backend and Railway PostgreSQL database are operational
  static Future<Map<String, dynamic>> checkDatabaseConnection() async {
    try {
      final uri = _getUri('/api/db-check');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return json.decode(utf8.decode(res.bodyBytes));
      } else {
        return {
          'status': 'error',
          'connected': false,
          'message': 'Serwer zwrócił kod ${res.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'connected': false,
        'message': 'Nie udało się połączyć z backendem: $e',
      };
    }
  }

  /// Fetch listings from the PostgreSQL database
  static Future<List<Listing>> fetchListings() async {
    try {
      final uri = _getUri('/api/listings');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List data = json.decode(utf8.decode(res.bodyBytes));
        return data.map((item) => Listing.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchListings error: $e');
    }
    return [];
  }

  /// Send a newly created listing to the PostgreSQL database
  static Future<bool> createListing(Listing listing) async {
    try {
      final uri = _getUri('/api/listings');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(listing.toJson()),
      ).timeout(const Duration(seconds: 8));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService.createListing error: $e');
      return false;
    }
  }

  /// Update an existing listing in the PostgreSQL database
  static Future<bool> updateListing(Listing listing) async {
    try {
      final uri = _getUri('/api/listings/${listing.id}');
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(listing.toJson()),
      ).timeout(const Duration(seconds: 8));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.updateListing error: $e');
      return false;
    }
  }

  /// Delete a listing from the PostgreSQL database
  static Future<bool> deleteListing(String id) async {
    try {
      final uri = _getUri('/api/listings/$id');
      final res = await http.delete(uri).timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deleteListing error: $e');
      return false;
    }
  }
}
