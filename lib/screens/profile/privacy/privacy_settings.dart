import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../widgets/custom_appbar.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> with WidgetsBindingObserver {
  bool isLoading = true;

  bool allowLocation = false;
  bool allowCamera = false;
  bool allowNotifications = false;
  
  static const MethodChannel _permissionChannel = MethodChannel('com.junction.permissions');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh permissions when user returns from system settings
    if (state == AppLifecycleState.resumed) {
      // Add small delay to ensure system has updated permission states
      Future.delayed(const Duration(milliseconds: 300), () {
        _checkAllPermissions();
      });
    }
  }

  /// Check actual OS-level permission status
  Future<void> _checkAllPermissions() async {
    setState(() => isLoading = true);

    try {
      bool locationGranted = false;
      bool cameraGranted = false;
      bool notificationsGranted = false;
      
      if (Platform.isIOS) {
        try {
          final locationStatusStr = await _permissionChannel.invokeMethod<String>('checkPermission', {'permission': 'location'});
          locationGranted = locationStatusStr == 'granted' || locationStatusStr == 'limited';
          debugPrint('iOS Location (native) - status: $locationStatusStr, granted: $locationGranted');
        } catch (e) {
          debugPrint('Error checking iOS location permission: $e');
          final locationStatus = await Permission.location.status;
          final locationServiceStatus = await Permission.location.serviceStatus;
          locationGranted = (locationStatus.isGranted || locationStatus.isLimited) && 
                           locationServiceStatus != ServiceStatus.disabled;
        }
        
        try {
          final cameraStatusStr = await _permissionChannel.invokeMethod<String>('checkPermission', {'permission': 'camera'});
          cameraGranted = cameraStatusStr == 'granted' || cameraStatusStr == 'limited';
          debugPrint('iOS Camera (native) - status: $cameraStatusStr, granted: $cameraGranted');
        } catch (e) {
          debugPrint('Error checking iOS camera permission: $e');
          final cameraStatus = await Permission.camera.status;
          cameraGranted = cameraStatus.isGranted || cameraStatus.isLimited;
        }
        
        try {
          final notificationStatusStr = await _permissionChannel.invokeMethod<String>('checkPermission', {'permission': 'notifications'});
          notificationsGranted = notificationStatusStr == 'granted' || notificationStatusStr == 'limited';
          debugPrint('iOS Notifications (native) - status: $notificationStatusStr, granted: $notificationsGranted');
        } catch (e) {
          debugPrint('Error checking iOS notifications permission: $e');
          final notificationStatus = await Permission.notification.status;
          notificationsGranted = notificationStatus.isGranted || notificationStatus.isLimited;
        }
      } else {
        final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
        final locationAlwaysStatus = await Permission.locationAlways.status;
        locationGranted = locationWhenInUseStatus.isGranted || locationAlwaysStatus.isGranted;
        debugPrint('Android Location status - WhenInUse: $locationWhenInUseStatus, Always: $locationAlwaysStatus, granted: $locationGranted');
        
        final cameraStatus = await Permission.camera.status;
        cameraGranted = cameraStatus.isGranted || cameraStatus.isLimited;
        debugPrint('Android Camera status: $cameraStatus, granted: $cameraGranted');
        
        final notificationStatus = await Permission.notification.status;
        notificationsGranted = notificationStatus.isGranted || notificationStatus.isLimited;
        debugPrint('Android Notifications status: $notificationStatus, granted: $notificationsGranted');
      }

      setState(() {
        allowLocation = locationGranted;
        allowCamera = cameraGranted;
        allowNotifications = notificationsGranted;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error checking permissions: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => isLoading = false);
    }
  }

  /// Show dialog explaining that user needs to go to system settings
  Future<void> _showSettingsDialog(String permissionName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Settings'),
          content: Text(
            'To change $permissionName permission, please go to your device settings.\n\nWould you like to open settings now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await openAppSettings();
    }
  }

  Widget buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required String permissionName,
  }) {
    return GestureDetector(
      onTap: () => _showSettingsDialog(permissionName),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8894),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 1,
              child: SizedBox(
                width: 38,
                height: 23,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: Switch(
                    value: value,
                    onChanged: (_) => _showSettingsDialog(permissionName),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFFFF6705),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFC9C8D3),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "App Permissions"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _checkAllPermissions,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6E6E6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF8A8894),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tap any permission to open device settings and manage access.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildToggle(
                    title: "Location Access",
                    subtitle: "Enable precise or approximate location to show nearby listings",
                    value: allowLocation,
                    permissionName: "Location",
                  ),
                  buildToggle(
                    title: "Camera Access",
                    subtitle: "Use your phone's camera to click and upload product images directly while posting.",
                    value: allowCamera,
                    permissionName: "Camera",
                  ),
                  buildToggle(
                    title: "Notifications",
                    subtitle: "Receive push notifications for messages, listings, and important updates.",
                    value: allowNotifications,
                    permissionName: "Notifications",
                  ),
                ],
              ),
            ),
    );
  }
}
