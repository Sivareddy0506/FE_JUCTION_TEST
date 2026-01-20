import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fallback when API does not return version data. Keep in sync with pubspec.yaml.
/// Format: semantic part only (e.g. 1.0.11 from 1.0.11+61).
const String kFallbackLatestVersion = '1.0.11';

/// Model for version check response
class VersionCheckResult {
  final String currentVersion;
  final String minVersion;
  final String latestVersion;
  final bool needsUpdate;
  final bool updateAvailable;
  final bool forceUpdate;
  final String updateMessage;
  final String storeUrl;

  VersionCheckResult({
    required this.currentVersion,
    required this.minVersion,
    required this.latestVersion,
    required this.needsUpdate,
    required this.updateAvailable,
    required this.forceUpdate,
    required this.updateMessage,
    required this.storeUrl,
  });

  factory VersionCheckResult.fromJson(Map<String, dynamic> json) {
    return VersionCheckResult(
      currentVersion: json['currentVersion'] ?? '1.0.0',
      minVersion: json['minVersion'] ?? kFallbackLatestVersion,
      latestVersion: json['latestVersion'] ?? kFallbackLatestVersion,
      needsUpdate: json['needsUpdate'] ?? false,
      updateAvailable: json['updateAvailable'] ?? false,
      forceUpdate: json['forceUpdate'] ?? false,
      updateMessage: json['updateMessage'] ?? 'A new version is available!',
      storeUrl: json['storeUrl'] ?? '',
    );
  }
}

/// Service to check app version against backend
class VersionCheckService {
  static const String _baseUrl = 'https://api.junctionverse.com';

  /// Check if app needs update
  static Future<VersionCheckResult?> checkVersion() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final platform = Platform.isIOS ? 'ios' : 'android';

      debugPrint('📱 [Version] Checking version: $currentVersion on $platform');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/app/version-check?platform=$platform&currentVersion=$currentVersion'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('📱 [Version] Request timeout');
          throw Exception('Version check timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = VersionCheckResult.fromJson(data);
        
        debugPrint('📱 [Version] Result: needsUpdate=${result.needsUpdate}, forceUpdate=${result.forceUpdate}');
        return result;
      } else {
        debugPrint('📱 [Version] Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('📱 [Version] Exception: $e');
      return null;
    }
  }

  /// Open app store for update
  static Future<void> openStore(String storeUrl) async {
    if (storeUrl.isEmpty) {
      // Fallback URLs
      if (Platform.isIOS) {
        storeUrl = 'https://apps.apple.com/app/junction/id123456789';
      } else {
        storeUrl = 'https://play.google.com/store/apps/details?id=com.junction.app';
      }
    }

    final uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Widget that shows update dialog
class UpdateDialog extends StatelessWidget {
  final VersionCheckResult versionInfo;
  final VoidCallback? onSkip;

  const UpdateDialog({
    super.key,
    required this.versionInfo,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back button if force update
      canPop: !versionInfo.forceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6705).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.system_update,
                color: Color(0xFFFF6705),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Update Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              versionInfo.updateMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'v${versionInfo.currentVersion}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Latest',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'v${versionInfo.latestVersion}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF6705),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (versionInfo.forceUpdate) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update is required to continue using the app.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!versionInfo.forceUpdate && onSkip != null)
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Later',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ElevatedButton(
            onPressed: () => VersionCheckService.openStore(versionInfo.storeUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6705),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}

/// Mixin to add version check capability to any StatefulWidget
mixin VersionCheckMixin<T extends StatefulWidget> on State<T> {
  bool _hasCheckedVersion = false;

  /// Call this in initState or after first frame
  Future<void> checkAppVersion() async {
    if (_hasCheckedVersion) return;
    _hasCheckedVersion = true;

    // Small delay to ensure app is fully loaded
    await Future.delayed(const Duration(milliseconds: 500));

    final result = await VersionCheckService.checkVersion();
    
    if (result != null && mounted) {
      if (result.needsUpdate || result.updateAvailable) {
        _showUpdateDialog(result);
      }
    }
  }

  void _showUpdateDialog(VersionCheckResult result) {
    showDialog(
      context: context,
      barrierDismissible: !result.forceUpdate,
      builder: (context) => UpdateDialog(
        versionInfo: result,
        onSkip: result.forceUpdate ? null : () => Navigator.pop(context),
      ),
    );
  }
}
