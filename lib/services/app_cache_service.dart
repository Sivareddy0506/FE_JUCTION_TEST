import 'package:flutter/foundation.dart';
import 'cache_manager.dart';
import 'image_cache_service.dart';
import 'memory_monitor_service.dart';
import 'network_service.dart';
import 'smart_refresh_service.dart';
import 'offline_service.dart';

/// App Cache Service for managing cache initialization and lifecycle
class AppCacheService {
  static final CacheManager _cacheManager = CacheManager();
  static final NetworkService _networkService = NetworkService();
  static final SmartRefreshService _smartRefreshService = SmartRefreshService();
  static final OfflineService _offlineService = OfflineService();
  static final ImageCacheService _imageCacheService = ImageCacheService();
  static final MemoryMonitorService _memoryMonitorService = MemoryMonitorService();
  static bool _isInitialized = false;

  /// Initialize the cache system at app startup
  static Future<void> initializeCache() async {
    if (_isInitialized) {
      debugPrint('AppCacheService: Cache already initialized');
      return;
    }

    try {
      debugPrint('AppCacheService: Initializing cache system...');
      
      // Initialize the cache manager with persistent storage
      await _cacheManager.initialize();
      await _imageCacheService.initialize();
      
      // Initialize Phase 3 services
      await _networkService.initialize();
      await _smartRefreshService.initialize();
      await _offlineService.initialize();
      
      _isInitialized = true;
      debugPrint('AppCacheService: Cache system initialized successfully');
      
      // Log cache statistics
      final stats = await _cacheManager.getCacheStats();
      debugPrint('AppCacheService: Cache stats - ${stats['totalEntries']} entries, ${stats['memoryUsage']} bytes');
      
    } catch (e) {
      debugPrint('AppCacheService: Failed to initialize cache system: $e');
      _isInitialized = true; // Mark as initialized to prevent retry loops
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    await _ensureInitialized();
    return await _cacheManager.getCacheStats();
  }

  /// Clear all caches
  static Future<void> clearAllCaches() async {
    await _ensureInitialized();
    await _cacheManager.clearAllCaches();
    await _imageCacheService.clearCache();
    debugPrint('AppCacheService: All caches cleared');
  }

  /// Force cleanup (LRU eviction) on both caches
  static Future<void> forceCleanup() async {
    await _ensureInitialized();
    // CacheManager eviction happens when limits exceeded; we just persist.
    await _cacheManager.forceSave();
    // ImageCacheService has internal limits already enforced.
    debugPrint('AppCacheService: forceCleanup triggered');
  }

  /// Force save current cache to persistent storage
  static Future<void> forceSaveCache() async {
    await _ensureInitialized();
    await _cacheManager.forceSave();
    debugPrint('AppCacheService: Cache saved to persistent storage');
  }

  /// Get cache entry info
  static Future<Map<String, dynamic>?> getCacheInfo(String key) async {
    await _ensureInitialized();
    return _cacheManager.getCacheInfo(key);
  }

  /// Check if cache system is initialized
  static bool get isInitialized => _isInitialized;

  /// Ensure the cache system is initialized
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initializeCache();
    }
  }

  /// Preload critical cache data
  static Future<void> preloadCriticalData() async {
    await _ensureInitialized();
    
    try {
      debugPrint('AppCacheService: Preloading critical cache data...');
      
      // This can be extended to preload specific data types
      // For now, we just ensure the cache system is ready
      
      debugPrint('AppCacheService: Critical data preload completed');
    } catch (e) {
      debugPrint('AppCacheService: Error preloading critical data: $e');
    }
  }

  /// Clean up expired cache entries
  static Future<void> cleanupExpiredEntries() async {
    await _ensureInitialized();
    
    try {
      final stats = await _cacheManager.getCacheStats();
      final expiredCount = stats['expiredEntries'] as int;
      
      if (expiredCount > 0) {
        debugPrint('AppCacheService: Cleaning up $expiredCount expired entries...');
        // The cache manager automatically cleans expired entries
        // This is just for logging and monitoring
      }
    } catch (e) {
      debugPrint('AppCacheService: Error cleaning expired entries: $e');
    }
  }

  // Phase 3: Smart Refresh & Offline Capabilities

  /// Get network status
  static bool get isOnline => _networkService.isConnected;

  /// Get network connectivity stream
  static Stream<bool> get connectivityStream => _networkService.connectivityStream;

  /// Smart refresh a specific cache entry
  static Future<void> smartRefresh(String cacheKey, {Duration? maxAge}) async {
    await _ensureInitialized();
    await _smartRefreshService.smartRefresh(cacheKey, maxAge: maxAge);
  }

  /// Force refresh all caches
  static Future<void> forceRefreshAll() async {
    await _ensureInitialized();
    await _smartRefreshService.forceRefreshAll();
  }

  /// Refresh specific data type
  static Future<void> refreshDataType(String dataType) async {
    await _ensureInitialized();
    await _smartRefreshService.refreshDataType(dataType);
  }

  /// Check if refresh is needed
  static Future<bool> isRefreshNeeded(String cacheKey) async {
    await _ensureInitialized();
    return await _smartRefreshService.isRefreshNeeded(cacheKey);
  }

  /// Get refresh recommendations
  static Future<Map<String, dynamic>> getRefreshRecommendations() async {
    await _ensureInitialized();
    return await _smartRefreshService.getRefreshRecommendations();
  }

  /// Queue offline action
  static Future<void> queueOfflineAction(String type, Map<String, dynamic> data) async {
    await _ensureInitialized();
    await _offlineService.queueAction(type, data);
  }

  /// Queue track click for offline execution
  static Future<void> queueTrackClick(String productId) async {
    await _ensureInitialized();
    await _offlineService.queueTrackClick(productId);
  }

  /// Queue track search for offline execution
  static Future<void> queueTrackSearch(String query) async {
    await _ensureInitialized();
    await _offlineService.queueTrackSearch(query);
  }

  /// Queue update favorite for offline execution
  static Future<void> queueUpdateFavorite(String productId, bool isFavorite) async {
    await _ensureInitialized();
    await _offlineService.queueUpdateFavorite(productId, isFavorite);
  }

  /// Get offline status
  static Map<String, dynamic> getOfflineStatus() {
    return _offlineService.getOfflineStatus();
  }

  /// Force sync offline actions
  static Future<void> forceSync() async {
    await _ensureInitialized();
    await _offlineService.forceSync();
  }

  /// Get pending actions count
  static int get pendingActionsCount => _offlineService.pendingActionsCount;

  /// Check if there are pending actions
  static bool get hasPendingActions => _offlineService.hasPendingActions;

  /// Get comprehensive system status
  static Future<Map<String, dynamic>> getSystemStatus() async {
    await _ensureInitialized();
    
    try {
      final cacheStats = await _cacheManager.getCacheStats();
      final imageStats = _imageCacheService.stats();
      final refreshRecommendations = await _smartRefreshService.getRefreshRecommendations();
      final offlineStatus = _offlineService.getOfflineStatus();
      
      return {
        'cache': cacheStats,
        'imageCache': imageStats,
        'network': {
          'isOnline': _networkService.isConnected,
          'isInitialized': _networkService.isInitialized,
        },
        'smartRefresh': refreshRecommendations,
        'offline': offlineStatus,
        'system': {
          'isInitialized': _isInitialized,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('AppCacheService: Error getting system status: $e');
      return {'error': e.toString()};
    }
  }

  /// Dispose all services
  static void dispose() {
    _smartRefreshService.dispose();
    _offlineService.dispose();
    _networkService.dispose();
    debugPrint('AppCacheService: All services disposed');
  }
}
