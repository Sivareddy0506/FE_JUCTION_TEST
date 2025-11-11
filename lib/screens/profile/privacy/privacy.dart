import 'package:flutter/material.dart';
import '../../../app.dart';
import '../../../widgets/custom_appbar.dart';
import 'privacy_settings.dart';
import 'thinking_delete.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  Widget _buildPrivacyItem({
    required BuildContext context,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8894),
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Center(
              child: Image.asset('assets/CaretRight.png', width: 20, height: 20),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Privacy Settings"),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: ListView(
          children: [
            _buildPrivacyItem(
              context: context,
              title: "App Permissions",
              description:
                  "Manage access to location, camera, storage (Android/iOS dependent)",
              onTap: () {
                Navigator.push(
                  context,
                  SlidePageRoute(page: const PrivacySettingsPage()),
                );
              },
            ),
            _buildPrivacyItem(
              context: context,
              title: "Download My Data",
              description:
                  "Request a copy of your profile, listings, and transaction history.",
              onTap: () {
                // Future implementation
              },
            ),
            _buildPrivacyItem(
              context: context,
              title: "Delete My Account",
              description:
                  "Permanently delete your account and all associated data from Junction.",
              onTap: () {
                Navigator.push(
                  context,
                  SlidePageRoute(page: const ThinkingDeletePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
