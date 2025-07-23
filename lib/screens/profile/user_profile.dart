import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/bottom_navbar.dart';
import 'account_settings_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String name = '';
  String university = '';
  String location = '';
  String profileImage = '';
  bool isLoading = true;
  int selectedTabIndex = 0;

  final List<String> tabs = [
    'Active Listings',
    'About',
    'Purchases',
    'Sold',
    'Favorites'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) return;

      final uri = Uri.parse('https://api.junctionverse.com/user/profile');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];

        setState(() {
          name = user['fullName'] ?? '';
          university = user['university'] ?? '';
          final fullAddress = user['homeAddress'] ?? '';
          final parts = fullAddress.split(',');
          location = parts.length >= 2 ? parts[parts.length - 3].trim() : fullAddress;
          profileImage = user['selfieUrl'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Choose Image Source"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Gallery"),
          ),
        ],
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) return;

    final uri = Uri.parse('https://api.junctionverse.com/user/update-profile-image');
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('profileImage', pickedFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      final updatedUser = data['user'];

      setState(() {
        profileImage = updatedUser['selfieUrl'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile image')),
      );
    }
  }

  Color _generateColorFromName(String name) {
    final hash = name.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromRGBO(r, g, b, 1);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _generateColorFromName(name);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                fit: StackFit.expand,
                children: [
                  profileImage.isNotEmpty
                      ? Image.network(profileImage, fit: BoxFit.cover)
                      : Container(color: backgroundColor),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 48),
                            Stack(
                              children: [
                                profileImage.isNotEmpty
                                    ? CircleAvatar(
                                        radius: 36,
                                        backgroundImage: NetworkImage(profileImage),
                                      )
                                    : CircleAvatar(
                                        radius: 36,
                                        backgroundColor: backgroundColor,
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _updateProfileImage,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: Image.asset('assets/edit.png', width: 16, height: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
                                );
                              },
                              icon: Image.asset('assets/settings.png', width: 24, height: 24),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFFF9F9F9),
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          height: 36 / 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/univ.png', width: 14),
                          const SizedBox(width: 4),
                          Text(
                            university,
                            style: const TextStyle(
                              color: Color(0xFFE3E3E3),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              height: 16 / 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Image.asset('assets/loc.png', width: 14),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              color: Color(0xFFE3E3E3),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              height: 16 / 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 40,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: tabs.length,
                                  itemBuilder: (context, index) {
                                    return _buildTab(
                                      tabs[index],
                                      selectedTabIndex == index,
                                      () => setState(() => selectedTabIndex = index),
                                    );
                                  },
                                ),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('No items to display', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        activeItem: 'Profile',
        onTap: (selected) => print("Tapped on $selected"),
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF262626) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E3E3)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF212121),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
