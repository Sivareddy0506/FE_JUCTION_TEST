import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache Manager for handling in-memory and persistent caching across the application
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Memory cache storage
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Duration> _cacheExpiries = {};
  // Size tracking for each entry (approximate bytes)
  final Map<String, int> _cacheSizes = {};

  // Runtime memory usage counters
  int _currentCacheSizeBytes = 0;

  // Memory limits
  static const int _maxCacheSizeBytes = 50 * 1024 * 1024; // 50 MB
  static const int _maxCacheEntries = 100;
  
  // SharedPreferences instance for persistent storage
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Initialize the cache manager with SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPersistentCache();
      _isInitialized = true;
      debugPrint('CacheManager: Initialized with persistent storage');
    } catch (e) {
      debugPrint('CacheManager: Failed to initialize persistent storage: $e');
      _isInitialized = true; // Continue with memory-only cache
    }
  }

  /// Load persistent cache data from SharedPreferences
  Future<void> _loadPersistentCache() async {
    if (_prefs == null) return;

    try {
      final cacheData = _prefs!.getString('cache_data');
      final timestampsData = _prefs!.getString('cache_timestamps');
      final expiriesData = _prefs!.getString('cache_expiries');

      // Safety: skip oversized blob (>5 MB) to avoid OOM
      const int _maxPersistentBytes = 5 * 1024 * 1024; // 5 MB
      if (cacheData != null && cacheData.length < _maxPersistentBytes) {
        final Map<String, dynamic> decoded = json.decode(cacheData);
        _memoryCache.addAll(decoded);
      } else if (cacheData != null) {
        debugPrint('CacheManager: persistent cache_data too large (${cacheData.length} bytes). Clearing…');
        // Clear persistent keys to free space
        await clearAllCaches();
      }

      if (timestampsData != null) {
        final Map<String, dynamic> decoded = json.decode(timestampsData);
        _cacheTimestamps.addAll(
          decoded.map((key, value) => MapEntry(key, DateTime.parse(value)))
        );
      }

      if (expiriesData != null) {
        final Map<String, dynamic> decoded = json.decode(expiriesData);
        _cacheExpiries.addAll(
          decoded.map((key, value) => MapEntry(key, Duration(milliseconds: value)))
        );
      }

      // Load sizes map if present
      final sizesData = _prefs!.getString('cache_sizes');
      if (sizesData != null) {
        final Map<String, dynamic> decoded = json.decode(sizesData);
        _cacheSizes.addAll(decoded.map((k, v) => MapEntry(k, v as int)));
      }

      // Re-calculate current size based on loaded sizes
      _currentCacheSizeBytes = _cacheSizes.values.fold(0, (p, c) => p + c);

      // Clean expired entries on load
      await _cleanExpiredEntries();
      debugPrint('CacheManager: Loaded ${_memoryCache.length} persistent cache entries');
    } catch (e) {
      debugPrint('CacheManager: Error loading persistent cache: $e');
    }
  }

  /// Save cache data to SharedPreferences
  Future<void> _savePersistentCache() async {
    if (_prefs == null) return;

    try {
      // Clean expired entries before saving
      await _cleanExpiredEntries();

      // Convert data for JSON serialization
      final cacheData = json.encode(_memoryCache);
      final timestampsData = json.encode(
        _cacheTimestamps.map((key, value) => MapEntry(key, value.toIso8601String()))
      );
      final expiriesData = json.encode(
        _cacheExpiries.map((key, value) => MapEntry(key, value.inMilliseconds))
      );

      await _prefs!.setString('cache_data', cacheData);
      await _prefs!.setString('cache_timestamps', timestampsData);
      await _prefs!.setString('cache_expiries', expiriesData);
      
      // Persist sizes
      final sizesData = json.encode(_cacheSizes);
      await _prefs!.setString('cache_sizes', sizesData);

      debugPrint('CacheManager: Saved ${_memoryCache.length} cache entries to persistent storage');
    } catch (e) {
      debugPrint('CacheManager: Error saving persistent cache: $e');
    }
  }

  /// Clean expired entries from both memory and persistent storage
  Future<void> _cleanExpiredEntries() async {
    final expiredKeys = _memoryCache.keys.where((key) => isCacheExpired(key)).toList();
    
    for (final key in expiredKeys) {
      await invalidateCache(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('CacheManager: Cleaned ${expiredKeys.length} expired entries');
    }
  }

  /// Get cached data by key
  Future<T?> getCachedData<T>(String key) async {
    await _ensureInitialized();
    
    if (!_memoryCache.containsKey(key)) {
      return null;
    }

    // Check if cache is expired
    if (isCacheExpired(key)) {
      await invalidateCache(key);
      return null;
    }

    try {
      return _memoryCache[key] as T;
    } catch (e) {
      debugPrint('CacheManager: Error casting cached data for key $key: $e');
      await invalidateCache(key);
      return null;
    }
  }

  /// Set data in cache with optional expiry
  Future<void> setCachedData<T>(String key, T data, {Duration? expiry}) async {
    await _ensureInitialized();

    // Estimate size of new entry
    final int newSize = _estimateObjectSize(data);

    // If single entry exceeds max size, skip caching
    if (newSize > _maxCacheSizeBytes) {
      debugPrint('CacheManager: Entry for $key (size $newSize) exceeds max cache size – skipping');
      return;
    }

    // Add/replace entry
    _memoryCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    _cacheSizes[key] = newSize;

    if (expiry != null) {
      _cacheExpiries[key] = expiry;
    }

    _currentCacheSizeBytes = _cacheSizes.values.fold(0, (p, c) => p + c);

    // Enforce limits
    await _evictLRUEntries();

    // Save to persistent storage
    await _savePersistentCache();

    debugPrint('CacheManager: Cached data for key $key (size $newSize bytes)');
  }

  /// Check if cache exists and is valid
  Future<bool> hasCachedData(String key) async {
    await _ensureInitialized();
    return _memoryCache.containsKey(key) && !isCacheExpired(key);
  }

  /// Check if cache is expired
  bool isCacheExpired(String key) {
    if (!_cacheTimestamps.containsKey(key)) {
      return true;
    }

    final timestamp = _cacheTimestamps[key]!;
    final expiry = _cacheExpiries[key];
    
    if (expiry == null) {
      return false; // No expiry set, cache is always valid
    }

    return DateTime.now().difference(timestamp) > expiry;
  }

  /// Invalidate specific cache entry
  Future<void> invalidateCache(String key) async {
    await _ensureInitialized();
    
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    _cacheExpiries.remove(key);
    _currentCacheSizeBytes -= _cacheSizes[key] ?? 0;
    _cacheSizes.remove(key);
    
    // Update persistent storage
    await _savePersistentCache();
    
    debugPrint('CacheManager: Invalidated cache for key $key');
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await _ensureInitialized();
    
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _cacheExpiries.clear();
    _cacheSizes.clear();
    _currentCacheSizeBytes = 0;
    
    // Clear persistent storage
    if (_prefs != null) {
      await _prefs!.remove('cache_data');
      await _prefs!.remove('cache_timestamps');
      await _prefs!.remove('cache_expiries');
      await _prefs!.remove('cache_sizes'); // Also clear sizes
    }
    
    debugPrint('CacheManager: Cleared all caches');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    await _ensureInitialized();
    
    return {
      'totalEntries': _memoryCache.length,
      'cacheKeys': _memoryCache.keys.toList(),
      'expiredEntries': _memoryCache.keys.where((key) => isCacheExpired(key)).length,
      'persistentStorage': _prefs != null,
      'memoryUsageBytes': _currentCacheSizeBytes,
      'maxCacheSizeBytes': _maxCacheSizeBytes,
      'maxEntries': _maxCacheEntries,
    };
  }

  /// Get cache size in memory (approximate)
  int getCacheSize() {
    return _memoryCache.length;
  }

  /// Check if cache is empty
  bool get isEmpty => _memoryCache.isEmpty;

  /// Get all cache keys
  List<String> get cacheKeys => _memoryCache.keys.toList();

  /// Ensure the cache manager is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Estimate memory usage of cache
  int _estimateMemoryUsage() {
    int size = 0;
    for (final entry in _memoryCache.entries) {
      size += entry.key.length;
      if (entry.value is String) {
        size += (entry.value as String).length;
      } else if (entry.value is Map || entry.value is List) {
        size += json.encode(entry.value).length;
      }
    }
    return size;
  }

  // Estimate generic object size (rough)
  int _estimateObjectSize(dynamic value) {
    if (value == null) return 0;
    if (value is String) {
      return value.length;
    } else if (value is Map || value is List) {
      try {
        return json.encode(value).length;
      } catch (_) {
        return 256; // fallback for complex objects
      }
    } else {
      return 64; // fallback rough estimate
    }
  }

  /// Evict least-recently-used entries until limits are within bounds
  Future<void> _evictLRUEntries() async {
    // Evict by entry count first
    while (_memoryCache.length > _maxCacheEntries) {
      final lruKey = _leastRecentlyUsedKey();
      if (lruKey == null) break;
      await invalidateCache(lruKey);
    }

    // Evict by size
    while (_currentCacheSizeBytes > _maxCacheSizeBytes) {
      final lruKey = _leastRecentlyUsedKey();
      if (lruKey == null) break;
      await invalidateCache(lruKey);
    }
  }

  String? _leastRecentlyUsedKey() {
    if (_cacheTimestamps.isEmpty) return null;
    return _cacheTimestamps.entries.reduce((a, b) => a.value.isBefore(b.value) ? a : b).key;
  }

  /// Get cache entry age
  Duration? getCacheAge(String key) {
    if (!_cacheTimestamps.containsKey(key)) {
      return null;
    }
    return DateTime.now().difference(_cacheTimestamps[key]!);
  }

  /// Force save current cache to persistent storage
  Future<void> forceSave() async {
    await _ensureInitialized();
    await _savePersistentCache();
  }

  /// Get cache entry info
  Map<String, dynamic>? getCacheInfo(String key) {
    if (!_memoryCache.containsKey(key)) {
      return null;
    }

    return {
      'exists': true,
      'expired': isCacheExpired(key),
      'age': getCacheAge(key)?.inSeconds,
      'expiry': _cacheExpiries[key]?.inSeconds,
      'size': _estimateEntrySize(key),
    };
  }

  /// Estimate size of a specific cache entry
  int _estimateEntrySize(String key) {
    final value = _memoryCache[key];
    if (value == null) return 0;
    
    if (value is String) {
      return value.length;
    } else if (value is Map || value is List) {
      return json.encode(value).length;
    }
    return 0;
  }
}

/// Cache configuration constants
class CacheConfig {
  // Cache expiry durations
  static const Duration productsExpiry = Duration(minutes: 30);
  static const Duration profileExpiry = Duration(hours: 1);
  static const Duration adsExpiry = Duration(hours: 2);
  static const Duration favoritesExpiry = Duration.zero; // Real-time, no expiry
  
  // Cache keys
  static const String productsKey = 'products';
  static const String lastViewedKey = 'last_viewed';
  static const String trendingKey = 'trending';
  static const String searchedKey = 'searched';
  static const String adsKey = 'ads';
  static const String profileKey = 'profile';
  static const String upcomingAuctionsKey = 'upcoming_auctions';
  static const String currentAuctionsKey = 'current_auctions';
  static const String todayAuctionsKey = 'today_auctions';
  static const String previousSearchAuctionsKey = 'previous_search_auctions';
  static const String trendingAuctionsKey = 'trending_auctions';
  
  // All cache keys for easy access
  static const List<String> cacheKeys = [
    productsKey,
    lastViewedKey,
    trendingKey,
    searchedKey,
    adsKey,
    profileKey,
    upcomingAuctionsKey,
    currentAuctionsKey,
    todayAuctionsKey,
    previousSearchAuctionsKey,
    trendingAuctionsKey,
  ];
}
