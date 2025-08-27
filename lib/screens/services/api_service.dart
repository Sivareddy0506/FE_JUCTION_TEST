import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../../services/cache_manager.dart';
import '../../services/app_cache_service.dart';

class ApiService {
  static final CacheManager _cacheManager = CacheManager();
  
  // Get auth token from local storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// Helper: filter out auction products
  static List<Product> _filterNonAuction(List<Product> products) {
    return products.where((p) => p.isAuction != true).toList();
  }

  /// Fetch last opened products with caching
  static Future<List<Product>> fetchLastOpenedWithCache() async {
    // Check cache first
    final cachedProducts = await _cacheManager.getCachedData<List<Product>>(CacheConfig.lastViewedKey);
    if (cachedProducts != null) {
      debugPrint('ApiService: Returning cached last viewed products');
      return cachedProducts;
    }

    // Fetch from API if not cached
    final products = await fetchLastOpened();
    if (products.isNotEmpty) {
      // Cache the products
      await _cacheManager.setCachedData(
        CacheConfig.lastViewedKey,
        products,
        expiry: CacheConfig.productsExpiry,
      );
      debugPrint('ApiService: Cached last viewed products');
    }

    return products;
  }

  /// Fetch last opened products (original method)
  static Future<List<Product>> fetchLastOpened() async {
    final token = await _getToken();
    final uri = Uri.parse('https://api.junctionverse.com/api/history/last-opened');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    print('🔍 fetchLastOpened: ${res.statusCode}');
    print('🧾 Response: ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is List) {
        return _filterNonAuction(data.map((e) => Product.fromJson(e)).toList());
      }
    }
    return [];
  }

  /// Fetch most clicked products with caching
  static Future<List<Product>> fetchMostClickedWithCache() async {
    // Check cache first
    final cachedProducts = await _cacheManager.getCachedData<List<Product>>(CacheConfig.trendingKey);
    if (cachedProducts != null) {
      debugPrint('ApiService: Returning cached trending products');
      return cachedProducts;
    }

    // Fetch from API if not cached
    final products = await fetchMostClicked();
    if (products.isNotEmpty) {
      // Cache the products
      await _cacheManager.setCachedData(
        CacheConfig.trendingKey,
        products,
        expiry: CacheConfig.productsExpiry,
      );
      debugPrint('ApiService: Cached trending products');
    }

    return products;
  }

  /// Fetch most clicked products (original method)
  static Future<List<Product>> fetchMostClicked() async {
    final uri = Uri.parse('https://api.junctionverse.com/api/history/most-clicked');
    final res = await http.get(uri);

    print('🔍 fetchMostClicked: ${res.statusCode}');
    print('🧾 Response: ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is List) {
        return _filterNonAuction(data.map((e) => Product.fromJson(e)).toList());
      }
    }
    return [];
  }

  /// Fetch all public products with caching
  static Future<List<Product>> fetchAllProductsWithCache() async {
    // Check cache first
    final cachedProducts = await _cacheManager.getCachedData<List<Product>>(CacheConfig.productsKey);
    if (cachedProducts != null) {
      debugPrint('ApiService: Returning cached all products');
      return cachedProducts;
    }

    // Fetch from API if not cached
    final products = await fetchAllProducts();
    if (products.isNotEmpty) {
      // Cache the products
      await _cacheManager.setCachedData(
        CacheConfig.productsKey,
        products,
        expiry: CacheConfig.productsExpiry,
      );
      debugPrint('ApiService: Cached all products');
    }

    return products;
  }

  /// Fetch all public products (original method)
  static Future<List<Product>> fetchAllProducts() async {
    final token = await _getToken();
    final uri = Uri.parse('https://api.junctionverse.com/product/products/public');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    print('🔍 fetchAllProducts: ${res.statusCode}');
    print('🧾 Response: ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      List<Product> products = [];
      if (data is Map && data['products'] is List) {
        products = (data['products'] as List).map((e) => Product.fromJson(e)).toList();
      } else if (data is List) {
        products = data.map((e) => Product.fromJson(e)).toList();
      }
      return _filterNonAuction(products);
    }
    return [];
  }

  /// Track product click with offline support
  static Future<void> trackProductClick(String productId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('https://api.junctionverse.com/api/history/track-click');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'productId': productId}),
      );

      print('📌 Track Click Status: ${res.statusCode}');
      print('📦 Track Click Response: ${res.body}');
    } catch (e) {
      print('❌ Track Click Error: $e');
      // Queue for offline execution if network fails
      try {
        await AppCacheService.queueTrackClick(productId);
        print('📱 Track click queued for offline execution');
      } catch (offlineError) {
        print('❌ Failed to queue track click: $offlineError');
      }
    }
  }

  /// Fetch based on user previous searches (recommendations) with caching
  static Future<List<Product>> fetchLastSearchedWithCache() async {
    // Check cache first
    final cachedProducts = await _cacheManager.getCachedData<List<Product>>(CacheConfig.searchedKey);
    if (cachedProducts != null) {
      debugPrint('ApiService: Returning cached searched products');
      return cachedProducts;
    }

    // Fetch from API if not cached
    final products = await fetchLastSearched();
    if (products.isNotEmpty) {
      // Cache the products
      await _cacheManager.setCachedData(
        CacheConfig.searchedKey,
        products,
        expiry: CacheConfig.productsExpiry,
      );
      debugPrint('ApiService: Cached searched products');
    }

    return products;
  }

  /// Fetch based on user previous searches (server aggregates queries → products)
  static Future<List<Product>> fetchLastSearched() async {
    final token = await _getToken();
    final uri = Uri.parse('https://api.junctionverse.com/user/recommendations/previous-search-products?limit=20&maxQueries=6&days=7&nonAuction=true');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    print('🔍 fetchPrevSearchProducts: ${res.statusCode}');
    print('🧾 Response: ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is Map && data['products'] is List) {
        final products = (data['products'] as List).map((e) => Product.fromJson(e)).toList();
        return _filterNonAuction(products);
      }
      // If backend returns empty products, we return [] so UI hides the section
    }
    return [];
  }

  /// Fetch ad URLs with caching
  static Future<List<String>> fetchAdUrlsWithCache() async {
    // Check cache first
    final cachedAds = await _cacheManager.getCachedData<List<String>>(CacheConfig.adsKey);
    if (cachedAds != null) {
      debugPrint('ApiService: Returning cached ad URLs');
      return cachedAds;
    }

    // Fetch from API if not cached
    final ads = await fetchAdUrls();
    if (ads.isNotEmpty) {
      // Cache the ads
      await _cacheManager.setCachedData(
        CacheConfig.adsKey,
        ads,
        expiry: CacheConfig.adsExpiry,
      );
      debugPrint('ApiService: Cached ad URLs');
    }

    return ads;
  }

  /// Fetch ad URLs (original method)
  static Future<List<String>> fetchAdUrls() async {
    final token = await _getToken();
    final uri = Uri.parse('https://api.junctionverse.com/api/ad/allids');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    print('🔍 fetchAdUrls: ${res.statusCode}');
    print('🧾 Response: ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is List) {
        final urls = data
            .map<String>((e) => e['mediaUrl'] ?? '')
            .where((url) => url.isNotEmpty && url.startsWith('http'))
            .toList();

        print("✅ Filtered Ad URLs: $urls");
        return urls;
      }
    }
    return [];
  }

  /// Cache management methods
  static Future<void> clearProductCaches() async {
    await _cacheManager.invalidateCache(CacheConfig.productsKey);
    await _cacheManager.invalidateCache(CacheConfig.lastViewedKey);
    await _cacheManager.invalidateCache(CacheConfig.trendingKey);
    await _cacheManager.invalidateCache(CacheConfig.searchedKey);
    debugPrint('ApiService: Cleared all product caches');
  }

  static Future<void> clearAdCache() async {
    await _cacheManager.invalidateCache(CacheConfig.adsKey);
    debugPrint('ApiService: Cleared ad cache');
  }

  static Future<void> clearAllCaches() async {
    await _cacheManager.clearAllCaches();
    debugPrint('ApiService: Cleared all caches');
  }

  static Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheManager.getCacheStats();
  }

  /// Search products using the search API
  static Future<List<Product>> searchProducts(String query) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required for search');
      }

      final uri = Uri.parse('https://api.junctionverse.com/user/search/current');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'query': query}),
      );

      debugPrint('🔍 Search API Response: ${response.statusCode}');
      debugPrint('🔍 Search Query: $query');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['products'] is List) {
          final products = (data['products'] as List)
              .map((e) => Product.fromJson(e))
              .toList();
          debugPrint('✅ Search successful: ${products.length} results found');
          return products;
        }
      } else {
        debugPrint('❌ Search API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to search products: ${response.statusCode}');
      }

      return [];
    } catch (e) {
      debugPrint('❌ Search Error: $e');
      throw Exception('Search failed: $e');
    }
  }

  /// Save search history
  static Future<void> saveSearchHistory(String query) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final uri = Uri.parse('https://api.junctionverse.com/user/search-history');
      await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'query': query}),
      );
      debugPrint('✅ Search history saved: $query');
    } catch (e) {
      debugPrint('❌ Save search history error: $e');
      // Queue for offline execution if network fails
      try {
        await AppCacheService.queueTrackSearch(query);
        debugPrint('📱 Search history queued for offline execution');
      } catch (offlineError) {
        debugPrint('❌ Failed to queue search history: $offlineError');
      }
    }
  }

  /// Fetch seller details by ID
  static Future<Map<String, dynamic>?> fetchSellerDetails(String sellerId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final uri = Uri.parse('https://api.junctionverse.com/user/$sellerId');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('🔍 Fetch seller details: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Seller details fetched: $data');
        return data;
      } else {
        debugPrint('❌ Failed to fetch seller details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching seller details: $e');
      return null;
    }
  }
}

/// Lightweight auth helpers used at app launch
class AuthHealthService {
  /// Attempts to refresh the access token using backend validate-and-refresh API.
  /// Returns a map with keys: status ('refreshed' | 'expired' | 'invalid' | 'error'),
  /// and 'token' when refreshed.
  static Future<Map<String, dynamic>> refreshAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null || token.isEmpty) {
        return {'status': 'invalid'};
      }

      final uri = Uri.parse('https://api.junctionverse.com/auth/token/refresh');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('🔐 refreshAuthToken: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final newToken = data['token']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          return {'status': 'refreshed', 'token': newToken};
        }
        return {'status': 'error'};
      }

      // Treat 404 (endpoint not deployed yet) as OK to proceed without changes
      if (res.statusCode == 404) {
        return {'status': 'refreshed'}; // proceed; no new token provided
      }

      // 401 payload contains { status: 'expired' | 'invalid' }
      if (res.statusCode == 401) {
        try {
          final data = json.decode(res.body);
          final status = data['status']?.toString() ?? 'invalid';
          return {'status': status};
        } catch (_) {
          return {'status': 'invalid'};
        }
      }

      return {'status': 'error'};
    } catch (e) {
      debugPrint('🔐 refreshAuthToken error: $e');
      return {'status': 'error'};
    }
  }
}
