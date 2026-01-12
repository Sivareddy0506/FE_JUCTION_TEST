import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../../models/promotional_banner.dart';
import '../../services/cache_manager.dart';
import '../../services/app_cache_service.dart';
import '../../services/search_service.dart';

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

  /// Fetch active promotional banner for a specific position
  static Future<PromotionalBanner?> fetchPromotionalBanner(String position) async {
    try {
      final uri = Uri.parse('https://api.junctionverse.com/api/promotional-banner/active/$position');
      final res = await http.get(uri);

      debugPrint('🔍 fetchPromotionalBanner ($position): ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data != null && data is Map && data.isNotEmpty) {
          final banner = PromotionalBanner.fromJson(Map<String, dynamic>.from(data));
          debugPrint('✅ Promotional banner fetched: ${banner.title}');
          return banner;
        }
        // If data is null, no active banner for this position
        debugPrint('ℹ️ No active banner for position: $position');
        return null;
      } else {
        debugPrint('❌ Failed to fetch promotional banner: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching promotional banner: $e');
      return null;
    }
  }

  /// Fetch promotional banner with caching
  static Future<PromotionalBanner?> fetchPromotionalBannerWithCache(String position) async {
    try {
      // Check cache first
      final cacheKey = '${CacheConfig.promotionalBannerKeyPrefix}$position';
      final cachedBanner = await _cacheManager.getCachedData<PromotionalBanner>(cacheKey);
      if (cachedBanner != null) {
        debugPrint('ApiService: Returning cached promotional banner for $position');
        return cachedBanner;
      }

      // Fetch from API if not cached
      final banner = await fetchPromotionalBanner(position);
      if (banner != null) {
        // Cache the banner
        await _cacheManager.setCachedData(
          cacheKey,
          banner,
          expiry: CacheConfig.promotionalBannerExpiry,
        );
        debugPrint('ApiService: Cached promotional banner for $position');
      }

      return banner;
    } catch (e) {
      debugPrint('❌ Error in fetchPromotionalBannerWithCache: $e');
      return null;
    }
  }

  /// Clear promotional banner cache for a specific position
  static Future<void> clearPromotionalBannerCache(String position) async {
    final cacheKey = '${CacheConfig.promotionalBannerKeyPrefix}$position';
    await _cacheManager.invalidateCache(cacheKey);
    debugPrint('ApiService: Cleared promotional banner cache for $position');
  }

  static Future<void> clearAllCaches() async {
    await _cacheManager.clearAllCaches();
    debugPrint('ApiService: Cleared all caches');
  }

  static Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheManager.getCacheStats();
  }

  /// Search products using the enhanced search API with location support
  static Future<List<Product>> searchProducts(String query) async {
    try {
      debugPrint('🔍 Search Query: $query');
      
      // Use the enhanced search service which handles location and authentication
      final searchResult = await SearchService.searchProducts(
        query: query,
        sortBy: 'Distance',
        limit: 50,
        radius: 50,
      );
      
      debugPrint('✅ Search successful: ${searchResult.products.length} results found');
      return searchResult.products;
    } catch (e) {
      debugPrint('❌ Search Error: $e');
      throw Exception('Search failed: $e');
    }
  }

  /// Save search history
  static Future<void> saveSearchHistory(String query) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ Save search history: No auth token found');
        return;
      }

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

  /// Fetch a single product by ID
  static Future<Product?> getProductById(String productId) async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        debugPrint('ApiService: No auth token available for getProductById');
        return null;
      }
      
      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/product/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final productData = jsonDecode(response.body);
        return Product.fromJson(productData);
      } else if (response.statusCode == 404) {
        debugPrint('ApiService: Product not found: $productId');
        return null;
      } else if (response.statusCode == 401) {
        debugPrint('ApiService: Unauthorized - token may be expired');
        return null;
      } else {
        debugPrint('ApiService: Failed to fetch product: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('ApiService: Error fetching product by ID: $e');
      return null;
    }
  }

  // Removed fetchSellerDetails; product.seller is now populated by backend
}

/// Lightweight auth helpers used at app launch
class AuthHealthService {
  /// Attempts to refresh the access token using backend validate-and-refresh API.
  /// Returns a map with keys:
  /// - status: 'refreshed' | 'still_valid' | 'expired' | 'invalid' | 'timeout' | 'network_error'
  /// - token: when refreshed
  /// - isVerified / isOnboarded: when refreshed (from backend)
  static Future<Map<String, dynamic>> refreshAuthToken({
    Duration refreshIfExpiringWithin = const Duration(hours: 6),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null || token.isEmpty) {
        return {'status': 'invalid'};
      }

      // Local expiry check first to avoid logging users out due to network issues.
      final expiry = _JwtTokenUtils.tryGetExpiry(token);
      if (expiry != null) {
        if (_JwtTokenUtils.isExpired(expiry)) {
          return {'status': 'expired'};
        }
        if (!_JwtTokenUtils.isNearExpiry(expiry, within: refreshIfExpiringWithin)) {
          return {'status': 'still_valid'};
        }
      }

      final uri = Uri.parse('https://api.junctionverse.com/auth/token/refresh');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('🔐 refreshAuthToken: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final newToken = data['token']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          final user = data['user'];
          return {
            'status': 'refreshed',
            'token': newToken,
            'isVerified': user?['isVerified'] ?? false,
            'isOnboarded': user?['isOnboarded'] ?? false,
          };
        }
        return {'status': 'invalid'};
      }

      if (res.statusCode == 401) {
        // Token is rejected by backend.
        // Treat as expired/invalid (don't guess which unless backend provides a status).
        try {
          final data = json.decode(res.body);
          final status = data['status']?.toString();
          if (status == 'expired') return {'status': 'expired'};
        } catch (_) {}
        return {'status': 'invalid'};
      }

      // 5xx / 429 / 408 etc: don't log out; treat as network/server error.
      return {'status': 'network_error'};
    } on TimeoutException catch (_) {
      return {'status': 'timeout'};
    } catch (e) {
      debugPrint('🔐 refreshAuthToken error: $e');
      return {'status': 'network_error'};
    }
  }

  /// Always fetches user verification status from backend, even if token is still_valid.
  /// This ensures we get the latest status from database, avoiding stale SharedPreferences.
  /// Returns a map with keys:
  /// - status: 'success' | 'error' | 'timeout' | 'network_error'
  /// - isVerified / isOnboarded: when status is 'success'
  static Future<Map<String, dynamic>> checkUserStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null || token.isEmpty) {
        return {'status': 'error'};
      }

      final uri = Uri.parse('https://api.junctionverse.com/auth/token/refresh');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final user = data['user'];
        if (user != null) {
          return {
            'status': 'success',
            'isVerified': user['isVerified'] ?? false,
            'isOnboarded': user['isOnboarded'] ?? false,
            // Optionally return new token if provided (but don't require it)
            'token': data['token']?.toString(),
          };
        }
        return {'status': 'error'};
      }

      if (res.statusCode == 401) {
        return {'status': 'error'};
      }

      return {'status': 'network_error'};
    } on TimeoutException catch (_) {
      return {'status': 'timeout'};
    } catch (e) {
      debugPrint('🔐 checkUserStatus error: $e');
      return {'status': 'network_error'};
    }
  }
}

/// Minimal JWT helper for local expiry checks (no extra deps).
class _JwtTokenUtils {
  static DateTime? tryGetExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payloadPart = parts[1];
      final payloadJson = _decodeBase64UrlToString(payloadPart);
      final payload = json.decode(payloadJson);
      final exp = payload is Map ? payload['exp'] : null;
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }
      if (exp is String) {
        final parsed = int.tryParse(exp);
        if (parsed != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsed * 1000, isUtc: true);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool isExpired(DateTime expiryUtc, {Duration clockSkew = const Duration(seconds: 30)}) {
    final nowUtc = DateTime.now().toUtc();
    return nowUtc.isAfter(expiryUtc.subtract(clockSkew));
  }

  static bool isNearExpiry(DateTime expiryUtc, {required Duration within}) {
    final nowUtc = DateTime.now().toUtc();
    return expiryUtc.isBefore(nowUtc.add(within));
  }

  static String _decodeBase64UrlToString(String input) {
    final normalized = base64Url.normalize(input);
    final bytes = base64Url.decode(normalized);
    return utf8.decode(bytes);
  }
}
