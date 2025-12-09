import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import '../../widgets/custom_appbar.dart';
import '../../widgets/app_button.dart';

import './personalinfo/personalinfo.dart';
import './loginandsecurity/login_security.dart' as security;
import './address/address.dart';
import './privacy/privacy.dart';
import './notification/notification.dart';
//import './wallet/wallet.dart';
import './referrals/referrals.dart';
import './faq/faq.dart';
import './terms/terms.dart';
import './report/report.dart';
import '../login/login_page.dart' as auth;
import '../../services/profile_service.dart'; // for cache clearing
import '../../app.dart'; // For SlidePageRoute

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE3E3E3))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Image.asset('assets/CaretRight.png', width: 20, height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    const url = 'https://api.junctionverse.com/user/auth/logout';
    final token = await _getToken();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Delete FCM token before clearing preferences
        await _deleteFCMToken(token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await ProfileService.clearProfileCache(); // <-- fix: clear cached profile on logout
        // Also clear other relevant single-user caches if any

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            SlidePageRoute(page: const auth.LoginPage()),
            (route) => false,
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logout failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  /// Delete FCM token from backend and Firestore on logout
  Future<void> _deleteFCMToken(String authToken) async {
    try {
      // Get current FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        debugPrint('📱 [FCM] No FCM token to delete');
        return;
      }

      // Delete from backend (DELETE endpoint - may need to be created)
      try {
        final response = await http.delete(
          Uri.parse('https://api.junctionverse.com/user/fcm-token'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'token': fcmToken}),
        );

        if (response.statusCode == 200 || response.statusCode == 404) {
          debugPrint('📱 [FCM] ✅ FCM token deleted from backend');
        } else {
          debugPrint('📱 [FCM] ⚠️ Failed to delete FCM token from backend: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('📱 [FCM] ⚠️ Error deleting FCM token from backend: $e');
        // Continue even if backend deletion fails
      }

      // Delete from Firestore
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (userId != null && firebaseUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'fcmTokens': FieldValue.arrayRemove([fcmToken]),
          });
          debugPrint('📱 [FCM] ✅ FCM token removed from Firestore');
        } catch (e) {
          debugPrint('📱 [FCM] ⚠️ Error removing token from Firestore: $e');
        }
      }

      // Delete the token from Firebase Messaging
      try {
        await FirebaseMessaging.instance.deleteToken();
        debugPrint('📱 [FCM] ✅ FCM token deleted from Firebase');
      } catch (e) {
        debugPrint('📱 [FCM] ⚠️ Error deleting token from Firebase: $e');
      }
    } catch (e) {
      debugPrint('📱 [FCM] ⚠️ Error in FCM token deletion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Settings"),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSectionTitle("General"),
                  _buildSettingItem(
                    icon: Icons.person_outline,
                    title: "Personal Information",
                    onTap: () => Navigator.push(
                      context,
                      SlidePageRoute(page: const PersonalInfoPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.login,
                    title: "Login & Security",
                    onTap: () => Navigator.push(
                      context,
                      SlidePageRoute(page: const security.LoginPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.location_on_outlined,
                    title: "Manage Address",
                    onTap: () => Navigator.push(
                      context,
                      SlidePageRoute(page: const AddressPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.shield_outlined,
                    title: "Privacy Settings",
                    onTap: () => Navigator.push(
                      context,
                      SlidePageRoute(page: const PrivacyPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.notifications_outlined,
                    title: "Notification Preferences",
                    onTap: () => Navigator.push(
                      context,
                      SlidePageRoute(page: const NotificationPage()),
                    ),
                  ),
                  // _buildSectionTitle("Payments and Transactions"),
                  // _buildSettingItem(
                  //   icon: Icons.account_balance_wallet_outlined,
                  //   title: "Manage Wallet",
                  //   onTap: () => Navigator.push(
                  //     context,
                  //     SlidePageRoute(page: const WalletPage()),
                  //   ),
                  // ),
                  _buildSectionTitle("Marketing"),
                  _buildSettingItem(
                    icon: Icons.group_outlined,
                    title: "Referrals",
                    onTap: () => Navigator.push(
                      context,
                      SlidePageRoute(page: const ReferralsPage()),
                    ),
                  ),
                  // _buildSettingItem(
                  //   icon: Icons.groups_2_outlined,
                  //   title: "Crew Clash",
                  //   onTap: () => Navigator.push(
                  //     context,
                  //     SlidePageRoute(page: const CrewClashPage()),
                  //   ),
                  // ),
                  _buildSectionTitle("Help and Support"),
                  _buildSettingItem(
                    icon: Icons.help_outline,
                    title: "FAQ",
                    onTap: () => Navigator.push(
                      context,
                      SlidePageRoute(page: const FaqPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.article_outlined,
                    title: "Terms & Conditions",
                    onTap: () => Navigator.push(
                      context,
                      SlidePageRoute(page: const TermsPage()),
                    ),
                  ),
                  // _buildSettingItem(
                  //   icon: Icons.headset_mic_outlined,
                  //   title: "Contact Support",
                  //   onTap: () => Navigator.push(
                  //     context,
                  //     SlidePageRoute(page: const SupportPage()),
                  //   ),
                  // ),
                  _buildSettingItem(
                    icon: Icons.report_gmailerrorred_outlined,
                    title: "Report Issue",
                    onTap: () => Navigator.push(
                      context,
                      SlidePageRoute(page: const ReportPage()),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppButton(
                label: "Logout",
                onPressed: () => _logout(context),
                bottomSpacing: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
