import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network Service for monitoring connectivity status
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  
  bool _isInitialized = false;
  bool _isConnected = true; // Assume connected by default
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// Stream to listen to connectivity changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize network monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('NetworkService: Initializing network monitoring...');
      
      // Get initial connectivity status
      final result = await _connectivity.checkConnectivity();
      _isConnected = result != ConnectivityResult.none;
      _connectivityController.add(_isConnected);
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
        final wasConnected = _isConnected;
        _isConnected = result != ConnectivityResult.none;
        
        if (wasConnected != _isConnected) {
          debugPrint('NetworkService: Connectivity changed - Connected: $_isConnected');
          _connectivityController.add(_isConnected);
        }
      });
      
      _isInitialized = true;
      debugPrint('NetworkService: Network monitoring initialized. Connected: $_isConnected');
      
    } catch (e) {
      debugPrint('NetworkService: Failed to initialize network monitoring: $e');
      _isInitialized = true; // Mark as initialized to prevent retry loops
    }
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = result != ConnectivityResult.none;
      return _isConnected;
    } catch (e) {
      debugPrint('NetworkService: Error checking connectivity: $e');
      return false;
    }
  }

  /// Test internet connectivity by making a simple request
  Future<bool> testInternetConnectivity() async {
    try {
      // This is a simple test - in a real app, you might want to ping your own API
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('NetworkService: Error testing internet connectivity: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    debugPrint('NetworkService: Disposed');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
