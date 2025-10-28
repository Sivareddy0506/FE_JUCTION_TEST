import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OtherUserProfilePage extends StatefulWidget {
  final String userId;

  const OtherUserProfilePage({super.key, required this.userId});

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  String name = '';
  String university = '';
  String location = '';
  String profileImage = '';

  int selectedTabIndex = 0;
  bool isLoadingProfile = true;
  bool isLoadingActiveListings = true;

  List<dynamic> activeListings = [];

  final List<String> tabs = [
    'Active Listings',
    'About',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadActiveListings();
  }

  Future<void> _loadProfile() async {
    try {
      final uri = Uri.parse('https://api.junctionverse.com/ratings/others/${widget.userId}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          name = data['name'] ?? '';
          university = data['university'] ?? '';
          location = data['location'] ?? '';
          profileImage = data['selfieUrl'] ?? '';
          isLoadingProfile = false;
        });
      } else {
        setState(() => isLoadingProfile = false);
      }
    } catch (e) {
      setState(() => isLoadingProfile = false);
    }
  }

  Future<void> _loadActiveListings() async {
    try {
      final uri = Uri.parse('https://api.junctionverse.com/product/others/active?userId=${widget.userId}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          activeListings = decoded is List ? decoded : (decoded['products'] ?? []);
          isLoadingActiveListings = false;
        });
      } else {
        setState(() => isLoadingActiveListings = false);
      }
    } catch (e) {
      setState(() => isLoadingActiveListings = false);
    }
  }

  String getReadableLocation(String fullAddress) {
    if (fullAddress.isEmpty) return '';
    final parts = fullAddress.split(',').map((p) => p.trim()).toList();
    final filtered = parts.where((p) => !RegExp(r'^\d').hasMatch(p)).toList();
    if (filtered.length >= 3) {
      return '${filtered[filtered.length - 3]}, ${filtered[filtered.length - 2]}, ${filtered[filtered.length - 1]}';
    } else if (filtered.length >= 2) {
      return '${filtered[filtered.length - 2]}, ${filtered[filtered.length - 1]}';
    } else {
      return filtered.join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            profileImage.isNotEmpty
                ? Image.network(profileImage, fit: BoxFit.cover)
                : Container(color: Colors.transparent),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
            Column(
              children: [
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: profileImage.isNotEmpty
                        ? Image.network(profileImage, fit: BoxFit.cover, width: 72, height: 72)
                        : Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '',
                            style: const TextStyle(fontSize: 24, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(university, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 2),
                Text(getReadableLocation(location), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: tabs.length,
                            itemBuilder: (context, index) {
                              final isActive = selectedTabIndex == index;
                              return GestureDetector(
                                onTap: () => setState(() => selectedTabIndex = index),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isActive ? const Color(0xFF262626) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE3E3E3)),
                                  ),
                                  child: Text(
                                    tabs[index],
                                    style: TextStyle(
                                      color: isActive ? Colors.white : const Color(0xFF212121),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: selectedTabIndex == 0
                              ? _buildActiveListingsView()
                              : _buildAboutView(),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveListingsView() {
    if (isLoadingActiveListings) {
      return const Center(child: CircularProgressIndicator());
    }
    if (activeListings.isEmpty) {
      return const Center(child: Text("No active listings"));
    }
    return ListView.builder(
      itemCount: activeListings.length,
      itemBuilder: (context, index) {
        final item = activeListings[index];
        return ListTile(
          title: Text(item['title'] ?? ''),
          subtitle: Text(item['price'].toString()),
        );
      },
    );
  }

  Widget _buildAboutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          "$name is a student at $university.\n\nLocation: ${getReadableLocation(location)}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
        ),
      ),
    );
  }
}
