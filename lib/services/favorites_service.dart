import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  Set<String> _favoriteProductIds = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  Set<String> get favoriteProductIds => _favoriteProductIds;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Initialize favorites - call this once when app starts
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null || token.isEmpty) {
        _favoriteProductIds = {};
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('https://api.junctionverse.com/user/my-favourites');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List favList = data['favourites'] ?? [];
        _favoriteProductIds = favList.map<String>((item) => item['id'].toString()).toSet();
      } else {
        _favoriteProductIds = {};
      }
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
      _favoriteProductIds = {};
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  // Add product to favorites
  Future<bool> addToFavorites(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null || token.isEmpty) return false;

      final uri = Uri.parse('https://api.junctionverse.com/user/add-favourite');
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'productId': productId}),
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        _favoriteProductIds.add(productId);
        notifyListeners();
        return true;
      }
      
      // Throw exception with response so error handler can process it
      // This allows proper handling of 403 NOT_ONBOARDED errors
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      // Re-throw to allow caller to handle with ErrorHandler
      rethrow;
    }
  }

  // Remove product from favorites
  Future<bool> removeFromFavorites(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null || token.isEmpty) return false;

      debugPrint('FavoritesService: Removing product $productId from favorites');
      final uri = Uri.parse('https://api.junctionverse.com/user/remove-favourite');
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'productId': productId}),
      );

      if (response.statusCode == 200) {
        _favoriteProductIds.remove(productId);
        debugPrint('FavoritesService: Successfully removed product $productId, notifying listeners');
        notifyListeners();
        return true;
      }
      
      // Throw exception with response so error handler can process it
      debugPrint('FavoritesService: Failed to remove product $productId, status: ${response.statusCode}');
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      // Re-throw to allow caller to handle with ErrorHandler
      rethrow;
    }
  }

  // Check if product is favorited
  bool isFavorited(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  // Refresh favorites from server
  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }
}
