import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'app_cache_service.dart';

class MemoryMonitorService {
  static final MemoryMonitorService _instance = MemoryMonitorService._internal();
  factory MemoryMonitorService() => _instance;
  MemoryMonitorService._internal();

  Timer? _timer;
  bool get isMonitoring => _timer != null;

  // thresholds (percent of max heap)
  static const double _highThreshold = 0.8; // 80%
  static const double _criticalThreshold = 0.9; // 90%
  static const Duration _interval = Duration(minutes: 2);

  void startMonitoring() {
    if (isMonitoring) return;
    _timer = Timer.periodic(_interval, (_) => _check());
    debugPrint('MemoryMonitorService: started');
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    debugPrint('MemoryMonitorService: stopped');
  }

  Future<void> _check() async {
    // Fetch cache & image-cache stats
    final stats = await AppCacheService.getSystemStatus();
    final int cacheBytes = stats['cache']?['memoryUsageBytes'] ?? 0;
    final int imageBytes = stats['imageCache']?['bytes'] ?? 0;

    const int maxBytes = 70 * 1024 * 1024; // 50MB cache + 20MB image cache
    final int used = cacheBytes + imageBytes;
    final double ratio = used / maxBytes;

    if (ratio >= _criticalThreshold) {
      debugPrint('MemoryMonitor: critical usage ${(ratio * 100).toStringAsFixed(1)}% - full clear');
      await AppCacheService.clearAllCaches();
    } else if (ratio >= _highThreshold) {
      debugPrint('MemoryMonitor: high usage ${(ratio * 100).toStringAsFixed(1)}% - cleanup');
      await AppCacheService.forceCleanup();
    }
  }
}
