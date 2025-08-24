import 'dart:async';
import 'package:flutter/material.dart';
import '../services/app_cache_service.dart';

/// Phase 3 Status Widget for monitoring smart refresh and offline capabilities
class Phase3StatusWidget extends StatefulWidget {
  const Phase3StatusWidget({super.key});

  @override
  State<Phase3StatusWidget> createState() => _Phase3StatusWidgetState();
}

class _Phase3StatusWidgetState extends State<Phase3StatusWidget> {
  Map<String, dynamic> _systemStatus = {};
  bool _isLoading = false;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadSystemStatus();
    _listenToConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _listenToConnectivity() {
    _connectivitySubscription = AppCacheService.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          // Refresh status when connectivity changes
          _loadSystemStatus();
        });
      }
    });
  }

  Future<void> _loadSystemStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await AppCacheService.getSystemStatus();
      setState(() {
        _systemStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Phase3StatusWidget: Error loading system status: $e');
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
                  'Phase 3: Smart Refresh & Offline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadSystemStatus,
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
                  // Network Status
                  _buildSectionHeader('Network Status'),
                  _buildNetworkStatus(),
                  
                  const SizedBox(height: 12),
                  
                  // Smart Refresh Status
                  _buildSectionHeader('Smart Refresh'),
                  _buildSmartRefreshStatus(),
                  
                  const SizedBox(height: 12),
                  
                  // Offline Status
                  _buildSectionHeader('Offline Capabilities'),
                  _buildOfflineStatus(),
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildNetworkStatus() {
    final network = _systemStatus['network'] as Map<String, dynamic>? ?? {};
    final isOnline = network['isOnline'] ?? false;
    final isInitialized = network['isInitialized'] ?? false;

    return Column(
      children: [
        _buildStatusRow('Status', isOnline ? 'Online' : 'Offline', isOnline ? Colors.green : Colors.red),
        _buildStatusRow('Initialized', isInitialized ? 'Yes' : 'No', isInitialized ? Colors.green : Colors.orange),
      ],
    );
  }

  Widget _buildSmartRefreshStatus() {
    final smartRefresh = _systemStatus['smartRefresh'] as Map<String, dynamic>? ?? {};
    final recommendations = smartRefresh['recommendations'] as List<dynamic>? ?? [];

    return Column(
      children: [
        _buildStatusRow('Network Status', smartRefresh['networkStatus'] == true ? 'Online' : 'Offline', 
                       smartRefresh['networkStatus'] == true ? Colors.green : Colors.red),
        _buildStatusRow('Total Entries', '${smartRefresh['totalEntries'] ?? 0}'),
        _buildStatusRow('Expired Entries', '${smartRefresh['expiredEntries'] ?? 0}'),
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 4),
          const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 2.0),
            child: Text('• $rec', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          )),
        ],
      ],
    );
  }

  Widget _buildOfflineStatus() {
    final offline = _systemStatus['offline'] as Map<String, dynamic>? ?? {};
    final isOnline = offline['isOnline'] ?? false;
    final pendingActions = offline['pendingActions'] ?? 0;
    final lastSync = offline['lastSync'] ?? 'Never';

    return Column(
      children: [
        _buildStatusRow('Status', isOnline ? 'Online' : 'Offline', isOnline ? Colors.green : Colors.red),
        _buildStatusRow('Pending Actions', '$pendingActions', pendingActions > 0 ? Colors.orange : Colors.green),
        _buildStatusRow('Last Sync', lastSync == 'Never' ? 'Never' : _formatTimestamp(lastSync)),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _refreshProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Refresh Products', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _refreshProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Refresh Profile', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _forceSync,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Force Sync', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _queueTestAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Test Offline', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AppCacheService.refreshDataType('products');
      await _loadSystemStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Products refreshed')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Phase3StatusWidget: Error refreshing products: $e');
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AppCacheService.refreshDataType('profile');
      await _loadSystemStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile refreshed')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Phase3StatusWidget: Error refreshing profile: $e');
    }
  }

  Future<void> _forceSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AppCacheService.forceSync();
      await _loadSystemStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Forced sync completed')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Phase3StatusWidget: Error force syncing: $e');
    }
  }

  Future<void> _queueTestAction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AppCacheService.queueTrackClick('test-product-${DateTime.now().millisecondsSinceEpoch}');
      await _loadSystemStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test action queued')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Phase3StatusWidget: Error queuing test action: $e');
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return timestamp;
    }
  }
}
