import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_appbar.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool isLoading = true;

  bool allowLocation = false;
  bool allowCamera = false;
  bool allowMedia = false;
  bool allowMicrophone = false;
  bool allowContacts = false;

  @override
  void initState() {
    super.initState();
    _fetchPrivacySettings();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> _fetchPrivacySettings() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/user/privacy-settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        setState(() {
          allowLocation = data['allowLocation'] ?? false;
          allowCamera = data['allowCamera'] ?? false;
          allowMedia = data['allowMedia'] ?? false;
          allowMicrophone = data['allowMicrophone'] ?? false;
          allowContacts = data['allowContacts'] ?? false;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updatePrivacySettings() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    final payload = {
      "allowLocation": allowLocation,
      "allowCamera": allowCamera,
      "allowMedia": allowMedia,
      "allowMicrophone": allowMicrophone,
      "allowContacts": allowContacts,
    };

    await http.put(
      Uri.parse('https://api.junctionverse.com/user/privacy-settings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    await _fetchPrivacySettings();
  }

  Future<void> _handlePermissionToggle({
    required Permission permission,
    required bool newValue,
    required Function(bool) setter,
  }) async {
    if (newValue) {
      final status = await permission.request();
      if (status.isGranted) {
        setter(true);
        await _updatePrivacySettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied')),
        );
      }
    } else {
      setter(false);
      await _updatePrivacySettings();
    }
  }

  Widget buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required VoidCallback onEnable,
    required VoidCallback onDisable,
  }) {
    return Padding(
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
                  onChanged: (bool newValue) async {
                    if (newValue) {
                      onEnable();
                    } else {
                      onDisable();
                    }
                  },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Privacy Settings"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPrivacySettings,
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(24, 32, 24, 16),
                children: [
                  buildToggle(
                    title: "Location Access",
                    subtitle:
                        "Enable precise or approximate location to show nearby listings",
                    value: allowLocation,
                    onEnable: () => _handlePermissionToggle(
                      permission: Permission.locationWhenInUse,
                      newValue: true,
                      setter: (val) => setState(() => allowLocation = val),
                    ),
                    onDisable: () => _handlePermissionToggle(
                      permission: Permission.locationWhenInUse,
                      newValue: false,
                      setter: (val) => setState(() => allowLocation = val),
                    ),
                  ),
                  buildToggle(
                    title: "Camera Access",
                    subtitle:
                        "Use your phone’s camera to click and upload product images directly while posting.",
                    value: allowCamera,
                    onEnable: () => _handlePermissionToggle(
                      permission: Permission.camera,
                      newValue: true,
                      setter: (val) => setState(() => allowCamera = val),
                    ),
                    onDisable: () => _handlePermissionToggle(
                      permission: Permission.camera,
                      newValue: false,
                      setter: (val) => setState(() => allowCamera = val),
                    ),
                  ),
                  buildToggle(
                    title: "Media & Files Access",
                    subtitle:
                        "Use your phone’s camera to click and upload product images directly while posting.",
                    value: allowMedia,
                    onEnable: () => _handlePermissionToggle(
                      permission: Permission.photos,
                      newValue: true,
                      setter: (val) => setState(() => allowMedia = val),
                    ),
                    onDisable: () => _handlePermissionToggle(
                      permission: Permission.photos,
                      newValue: false,
                      setter: (val) => setState(() => allowMedia = val),
                    ),
                  ),
                  buildToggle(
                    title: "Microphone Access",
                    subtitle: "Enable voice notes or voice search",
                    value: allowMicrophone,
                    onEnable: () => _handlePermissionToggle(
                      permission: Permission.microphone,
                      newValue: true,
                      setter: (val) => setState(() => allowMicrophone = val),
                    ),
                    onDisable: () => _handlePermissionToggle(
                      permission: Permission.microphone,
                      newValue: false,
                      setter: (val) => setState(() => allowMicrophone = val),
                    ),
                  ),
                  buildToggle(
                    title: "Contacts Access",
                    subtitle:
                        "Used only if you offer referral via contact sharing.",
                    value: allowContacts,
                    onEnable: () => _handlePermissionToggle(
                      permission: Permission.contacts,
                      newValue: true,
                      setter: (val) => setState(() => allowContacts = val),
                    ),
                    onDisable: () => _handlePermissionToggle(
                      permission: Permission.contacts,
                      newValue: false,
                      setter: (val) => setState(() => allowContacts = val),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
