import 'package:flutter/material.dart';
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
  bool allowMedia = false;
  bool allowMicrophone = false;
  bool allowContacts = false;

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
      _checkAllPermissions();
    }
  }

  /// Check actual OS-level permission status
  Future<void> _checkAllPermissions() async {
    setState(() => isLoading = true);

    try {
      final locationStatus = await Permission.locationWhenInUse.status;
      final cameraStatus = await Permission.camera.status;
      final photosStatus = await Permission.photos.status;
      final microphoneStatus = await Permission.microphone.status;
      final contactsStatus = await Permission.contacts.status;

      setState(() {
        allowLocation = locationStatus.isGranted;
        allowCamera = cameraStatus.isGranted;
        allowMedia = photosStatus.isGranted;
        allowMicrophone = microphoneStatus.isGranted;
        allowContacts = contactsStatus.isGranted;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error checking permissions: $e');
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
                    title: "Media & Files Access",
                    subtitle: "Access photos and files to upload product images from your gallery.",
                    value: allowMedia,
                    permissionName: "Photos/Media",
                  ),
                  buildToggle(
                    title: "Microphone Access",
                    subtitle: "Enable voice notes or voice search",
                    value: allowMicrophone,
                    permissionName: "Microphone",
                  ),
                  buildToggle(
                    title: "Contacts Access",
                    subtitle: "Used only if you offer referral via contact sharing.",
                    value: allowContacts,
                    permissionName: "Contacts",
                  ),
                ],
              ),
            ),
    );
  }
}
