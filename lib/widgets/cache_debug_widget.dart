import 'package:flutter/material.dart';
import '../services/app_cache_service.dart';

/// Debug widget for monitoring and managing cache
class CacheDebugWidget extends StatefulWidget {
  const CacheDebugWidget({super.key});

  @override
  State<CacheDebugWidget> createState() => _CacheDebugWidgetState();
}

class _CacheDebugWidgetState extends State<CacheDebugWidget> {
  Map<String, dynamic> _cacheStats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await AppCacheService.getCacheStats();
      setState(() {
        _cacheStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('CacheDebugWidget: Error loading stats: $e');
    }
  }

  Future<void> _clearAllCaches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AppCacheService.clearAllCaches();
      await _loadCacheStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All caches cleared')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('CacheDebugWidget: Error clearing caches: $e');
    }
  }

  Future<void> _forceSaveCache() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AppCacheService.forceSaveCache();
      await _loadCacheStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache saved to persistent storage')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('CacheDebugWidget: Error saving cache: $e');
    }
  }

  Future<void> _forceRefreshAll() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AppCacheService.forceRefreshAll();
      await _loadCacheStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All caches force refreshed')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('CacheDebugWidget: Error force refreshing: $e');
    }
  }

  Future<void> _forceSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AppCacheService.forceSync();
      await _loadCacheStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline actions synced')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('CacheDebugWidget: Error force syncing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cache Debug Info',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadCacheStats,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase 2: Cache Stats
                  _buildStatRow('Total Entries', '${_cacheStats['totalEntries'] ?? 0}'),
                  _buildStatRow('Expired Entries', '${_cacheStats['expiredEntries'] ?? 0}'),
                  _buildStatRow('Memory Usage', '${_cacheStats['memoryUsage'] ?? 0} bytes'),
                  _buildStatRow('Persistent Storage', '${_cacheStats['persistentStorage'] ?? false}'),
                  
                  // Phase 3: Network & Offline Status
                  const SizedBox(height: 8),
                  _buildStatRow('Network Status', AppCacheService.isOnline ? 'Online' : 'Offline'),
                  _buildStatRow('Pending Actions', '${AppCacheService.pendingActionsCount}'),
                  
                  const SizedBox(height: 8),
                  if (_cacheStats['cacheKeys'] != null) ...[
                    const Text(
                      'Cache Keys:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...(_cacheStats['cacheKeys'] as List<dynamic>? ?? []).map((key) => 
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('• $key', style: const TextStyle(fontSize: 12)),
                      )
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _clearAllCaches,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _forceSaveCache,
                          child: const Text('Force Save'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Phase 3 Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _forceRefreshAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Force Refresh'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _forceSync,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Force Sync'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
