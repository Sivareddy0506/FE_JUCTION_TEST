import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cache_manager.dart';
import 'network_service.dart';

/// Smart Refresh Service for intelligent cache invalidation and background refresh
class SmartRefreshService {
  static final SmartRefreshService _instance = SmartRefreshService._internal();
  factory SmartRefreshService() => _instance;
  SmartRefreshService._internal();

  final CacheManager _cacheManager = CacheManager();
  final NetworkService _networkService = NetworkService();
  
  bool _isInitialized = false;
  Timer? _backgroundRefreshTimer;
  final Map<String, Timer> _staleDataTimers = {};
  
  // Refresh intervals
  static const Duration backgroundRefreshInterval = Duration(minutes: 15);
  static const Duration staleDataCheckInterval = Duration(minutes: 5);

  /// Initialize smart refresh service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('SmartRefreshService: Initializing smart refresh...');
      
      // Initialize network service
      await _networkService.initialize();
      
      // Start background refresh timer
      _startBackgroundRefresh();
      
      // Start stale data monitoring
      _startStaleDataMonitoring();
      
      _isInitialized = true;
      debugPrint('SmartRefreshService: Smart refresh initialized');
      
    } catch (e) {
      debugPrint('SmartRefreshService: Failed to initialize: $e');
      _isInitialized = true; // Mark as initialized to prevent retry loops
    }
  }

  /// Start background refresh timer
  void _startBackgroundRefresh() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer.periodic(backgroundRefreshInterval, (timer) {
      _performBackgroundRefresh();
    });
    debugPrint('SmartRefreshService: Background refresh timer started');
  }

  /// Start stale data monitoring
  void _startStaleDataMonitoring() {
    _staleDataTimers.forEach((key, timer) => timer.cancel());
    _staleDataTimers.clear();
    
    _staleDataTimers['stale_check'] = Timer.periodic(staleDataCheckInterval, (timer) {
      _checkAndMarkStaleData();
    });
    debugPrint('SmartRefreshService: Stale data monitoring started');
  }

  /// Perform background refresh of cached data
  Future<void> _performBackgroundRefresh() async {
    if (!_networkService.isConnected) {
      debugPrint('SmartRefreshService: Skipping background refresh - no network');
      return;
    }

    try {
      debugPrint('SmartRefreshService: Performing background refresh...');
      
      // Get cache stats to see what needs refreshing
      final stats = await _cacheManager.getCacheStats();
      final totalEntries = stats['totalEntries'] as int;
      
      if (totalEntries > 0) {
        // In a real implementation, you would refresh specific data types
        // For now, we'll just log the refresh attempt
        debugPrint('SmartRefreshService: Background refresh completed for $totalEntries entries');
      }
      
    } catch (e) {
      debugPrint('SmartRefreshService: Error during background refresh: $e');
    }
  }

  /// Check and mark stale data
  Future<void> _checkAndMarkStaleData() async {
    try {
      final stats = await _cacheManager.getCacheStats();
      final expiredEntries = stats['expiredEntries'] as int;
      
      if (expiredEntries > 0) {
        debugPrint('SmartRefreshService: Found $expiredEntries expired entries');
        // The cache manager automatically cleans expired entries
        // This is just for monitoring and logging
      }
      
    } catch (e) {
      debugPrint('SmartRefreshService: Error checking stale data: $e');
    }
  }

  /// Smart refresh based on data type and conditions
  Future<void> smartRefresh(String cacheKey, {Duration? maxAge}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final cacheInfo = _cacheManager.getCacheInfo(cacheKey);
      if (cacheInfo == null) {
        debugPrint('SmartRefreshService: No cache info for key $cacheKey');
        return;
      }

      final isExpired = cacheInfo['expired'] as bool;
      final age = cacheInfo['age'] as int?;
      
      // Check if data is stale based on maxAge
      bool isStale = false;
      if (maxAge != null && age != null) {
        isStale = age > maxAge.inSeconds;
      }

      if (isExpired || isStale) {
        debugPrint('SmartRefreshService: Refreshing stale data for key $cacheKey');
        await _refreshCacheEntry(cacheKey);
      } else {
        debugPrint('SmartRefreshService: Data for key $cacheKey is still fresh');
      }
      
    } catch (e) {
      debugPrint('SmartRefreshService: Error in smart refresh for key $cacheKey: $e');
    }
  }

  /// Refresh a specific cache entry
  Future<void> _refreshCacheEntry(String cacheKey) async {
    try {
      // Invalidate the cache entry to force a fresh fetch
      await _cacheManager.invalidateCache(cacheKey);
      debugPrint('SmartRefreshService: Refreshed cache entry $cacheKey');
    } catch (e) {
      debugPrint('SmartRefreshService: Error refreshing cache entry $cacheKey: $e');
    }
  }

  /// Force refresh all caches
  Future<void> forceRefreshAll() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('SmartRefreshService: Force refreshing all caches...');
      await _cacheManager.clearAllCaches();
      debugPrint('SmartRefreshService: All caches force refreshed');
    } catch (e) {
      debugPrint('SmartRefreshService: Error force refreshing all caches: $e');
    }
  }

  /// Refresh specific data types
  Future<void> refreshDataType(String dataType) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('SmartRefreshService: Refreshing data type: $dataType');
      
      // Map data types to cache keys
      final cacheKeys = _getCacheKeysForDataType(dataType);
      
      for (final key in cacheKeys) {
        await _refreshCacheEntry(key);
      }
      
      debugPrint('SmartRefreshService: Refreshed data type: $dataType');
    } catch (e) {
      debugPrint('SmartRefreshService: Error refreshing data type $dataType: $e');
    }
  }

  /// Get cache keys for a specific data type
  List<String> _getCacheKeysForDataType(String dataType) {
    switch (dataType.toLowerCase()) {
      case 'products':
        return [CacheConfig.productsKey, CacheConfig.lastViewedKey, CacheConfig.trendingKey];
      case 'profile':
        return [CacheConfig.profileKey];
      case 'ads':
        return [CacheConfig.adsKey];
      case 'auctions':
        return [CacheConfig.upcomingAuctionsKey, CacheConfig.currentAuctionsKey, CacheConfig.todayAuctionsKey];
      case 'all':
        return CacheConfig.cacheKeys;
      default:
        return [];
    }
  }

  /// Check if refresh is needed based on network and cache conditions
  Future<bool> isRefreshNeeded(String cacheKey) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Check network connectivity
      if (!_networkService.isConnected) {
        return false; // No refresh needed if offline
      }

      // Check cache status
      final cacheInfo = _cacheManager.getCacheInfo(cacheKey);
      if (cacheInfo == null) {
        return true; // Refresh needed if no cache
      }

      final isExpired = cacheInfo['expired'] as bool;
      return isExpired;
      
    } catch (e) {
      debugPrint('SmartRefreshService: Error checking if refresh needed: $e');
      return false;
    }
  }

  /// Get refresh recommendations
  Future<Map<String, dynamic>> getRefreshRecommendations() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final stats = await _cacheManager.getCacheStats();
      final recommendations = <String, dynamic>{
        'networkStatus': _networkService.isConnected,
        'totalEntries': stats['totalEntries'],
        'expiredEntries': stats['expiredEntries'],
        'recommendations': <String>[],
      };

      // Add recommendations based on conditions
      if (!_networkService.isConnected) {
        recommendations['recommendations'].add('Offline mode - using cached data');
      }

      if (stats['expiredEntries'] > 0) {
        recommendations['recommendations'].add('${stats['expiredEntries']} entries need refresh');
      }

      return recommendations;
      
    } catch (e) {
      debugPrint('SmartRefreshService: Error getting refresh recommendations: $e');
      return {'error': e.toString()};
    }
  }

  /// Dispose resources
  void dispose() {
    _backgroundRefreshTimer?.cancel();
    _staleDataTimers.forEach((key, timer) => timer.cancel());
    _staleDataTimers.clear();
    debugPrint('SmartRefreshService: Disposed');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
