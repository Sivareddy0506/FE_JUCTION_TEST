import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_manager.dart';
import 'network_service.dart';

/// Offline Service for handling offline capabilities and data synchronization
class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final CacheManager _cacheManager = CacheManager();
  final NetworkService _networkService = NetworkService();
  
  bool _isInitialized = false;
  final List<Map<String, dynamic>> _pendingActions = [];
  Timer? _syncTimer;
  
  // Sync intervals
  static const Duration syncInterval = Duration(minutes: 5);
  static const String pendingActionsKey = 'pending_actions';

  /// Initialize offline service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('OfflineService: Initializing offline service...');
      
      // Initialize network service
      await _networkService.initialize();
      
      // Load pending actions
      await _loadPendingActions();
      
      // Start sync timer
      _startSyncTimer();
      
      // Listen to network changes
      _networkService.connectivityStream.listen((isConnected) {
        if (isConnected) {
          _performSync();
        }
      });
      
      _isInitialized = true;
      debugPrint('OfflineService: Offline service initialized');
      
    } catch (e) {
      debugPrint('OfflineService: Failed to initialize: $e');
      _isInitialized = true; // Mark as initialized to prevent retry loops
    }
  }

  /// Load pending actions from persistent storage
  Future<void> _loadPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionsJson = prefs.getString(pendingActionsKey);
      
      if (actionsJson != null) {
        final List<dynamic> actions = json.decode(actionsJson);
        _pendingActions.clear();
        _pendingActions.addAll(actions.cast<Map<String, dynamic>>());
        debugPrint('OfflineService: Loaded ${_pendingActions.length} pending actions');
      }
    } catch (e) {
      debugPrint('OfflineService: Error loading pending actions: $e');
    }
  }

  /// Save pending actions to persistent storage
  Future<void> _savePendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionsJson = json.encode(_pendingActions);
      await prefs.setString(pendingActionsKey, actionsJson);
      debugPrint('OfflineService: Saved ${_pendingActions.length} pending actions');
    } catch (e) {
      debugPrint('OfflineService: Error saving pending actions: $e');
    }
  }

  /// Start sync timer
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(syncInterval, (timer) {
      if (_networkService.isConnected) {
        _performSync();
      }
    });
    debugPrint('OfflineService: Sync timer started');
  }

  /// Perform synchronization of pending actions
  Future<void> _performSync() async {
    if (_pendingActions.isEmpty) {
      return;
    }

    try {
      debugPrint('OfflineService: Performing sync for ${_pendingActions.length} actions...');
      
      final List<Map<String, dynamic>> successfulActions = [];
      final List<Map<String, dynamic>> failedActions = [];
      
      for (final action in _pendingActions) {
        try {
          final success = await _executeAction(action);
          if (success) {
            successfulActions.add(action);
          } else {
            failedActions.add(action);
          }
        } catch (e) {
          debugPrint('OfflineService: Error executing action: $e');
          failedActions.add(action);
        }
      }
      
      // Remove successful actions
      for (final action in successfulActions) {
        _pendingActions.remove(action);
      }
      
      // Update pending actions storage
      await _savePendingActions();
      
      debugPrint('OfflineService: Sync completed - ${successfulActions.length} successful, ${failedActions.length} failed');
      
    } catch (e) {
      debugPrint('OfflineService: Error during sync: $e');
    }
  }

  /// Execute a single action
  Future<bool> _executeAction(Map<String, dynamic> action) async {
    try {
      final actionType = action['type'] as String;
      
      switch (actionType) {
        case 'track_click':
          return await _executeTrackClick(action);
        case 'track_search':
          return await _executeTrackSearch(action);
        case 'update_favorite':
          return await _executeUpdateFavorite(action);
        default:
          debugPrint('OfflineService: Unknown action type: $actionType');
          return false;
      }
    } catch (e) {
      debugPrint('OfflineService: Error executing action: $e');
      return false;
    }
  }

  /// Execute track click action
  Future<bool> _executeTrackClick(Map<String, dynamic> action) async {
    try {
      final productId = action['productId'] as String;
      // In a real implementation, you would make an API call here
      debugPrint('OfflineService: Executed track click for product: $productId');
      return true;
    } catch (e) {
      debugPrint('OfflineService: Error executing track click: $e');
      return false;
    }
  }

  /// Execute track search action
  Future<bool> _executeTrackSearch(Map<String, dynamic> action) async {
    try {
      final query = action['query'] as String;
      // In a real implementation, you would make an API call here
      debugPrint('OfflineService: Executed track search for query: $query');
      return true;
    } catch (e) {
      debugPrint('OfflineService: Error executing track search: $e');
      return false;
    }
  }

  /// Execute update favorite action
  Future<bool> _executeUpdateFavorite(Map<String, dynamic> action) async {
    try {
      final productId = action['productId'] as String;
      final isFavorite = action['isFavorite'] as bool;
      // In a real implementation, you would make an API call here
      debugPrint('OfflineService: Executed update favorite for product: $productId, isFavorite: $isFavorite');
      return true;
    } catch (e) {
      debugPrint('OfflineService: Error executing update favorite: $e');
      return false;
    }
  }

  /// Queue an action for offline execution
  Future<void> queueAction(String type, Map<String, dynamic> data) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final action = {
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      _pendingActions.add(action);
      await _savePendingActions();
      
      debugPrint('OfflineService: Queued action: $type');
      
      // If online, try to execute immediately
      if (_networkService.isConnected) {
        _performSync();
      }
      
    } catch (e) {
      debugPrint('OfflineService: Error queuing action: $e');
    }
  }

  /// Queue track click action
  Future<void> queueTrackClick(String productId) async {
    await queueAction('track_click', {'productId': productId});
  }

  /// Queue track search action
  Future<void> queueTrackSearch(String query) async {
    await queueAction('track_search', {'query': query});
  }

  /// Queue update favorite action
  Future<void> queueUpdateFavorite(String productId, bool isFavorite) async {
    await queueAction('update_favorite', {
      'productId': productId,
      'isFavorite': isFavorite,
    });
  }

  /// Get offline status
  Map<String, dynamic> getOfflineStatus() {
    return {
      'isOnline': _networkService.isConnected,
      'pendingActions': _pendingActions.length,
      'lastSync': _getLastSyncTime(),
    };
  }

  /// Get last sync time
  String _getLastSyncTime() {
    if (_pendingActions.isEmpty) {
      return 'Never';
    }
    
    final timestamps = _pendingActions
        .map((action) => DateTime.parse(action['timestamp']))
        .toList();
    
    timestamps.sort();
    return timestamps.last.toIso8601String();
  }

  /// Force sync now
  Future<void> forceSync() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_networkService.isConnected) {
      await _performSync();
    } else {
      debugPrint('OfflineService: Cannot sync - offline');
    }
  }

  /// Clear all pending actions
  Future<void> clearPendingActions() async {
    _pendingActions.clear();
    await _savePendingActions();
    debugPrint('OfflineService: Cleared all pending actions');
  }

  /// Get pending actions for debugging
  List<Map<String, dynamic>> getPendingActions() {
    return List.unmodifiable(_pendingActions);
  }

  /// Check if there are pending actions
  bool get hasPendingActions => _pendingActions.isNotEmpty;

  /// Get pending actions count
  int get pendingActionsCount => _pendingActions.length;

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    debugPrint('OfflineService: Disposed');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
