import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../widgets/custom_appbar.dart';
import '../../widgets/app_button.dart';

import './personalinfo/personalinfo.dart';
import './loginandsecurity/login_security.dart';
import './address/address.dart';
import './privacy/privacy.dart';
import './notification/notification.dart';
import './wallet/wallet.dart';
import './referrals/referrals.dart';
import './crewclash/crewclash.dart';
import './faq/faq.dart';
import './terms/terms.dart';
import './support/support.dart';
import './report/report.dart';
import '../products/home.dart'; // Adjust this import if path is different

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
            Image.asset('assets/CaretLeft.png', width: 20, height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    const url = 'https://api.junctionverse.com/user/auth/logout';
    final token = await _getToken(); // Replace with your token logic

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Clear local storage/session if needed here

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()), // Adjust as needed
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  Future<String> _getToken() async {
    // TODO: Replace with your secure token fetch (e.g., SharedPreferences)
    return 'your_actual_token';
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
                      MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.login,
                    title: "Login & Security",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.location_on_outlined,
                    title: "Manage Address",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddressPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.shield_outlined,
                    title: "Privacy Settings",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.notifications_outlined,
                    title: "Notification Preferences",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationPage()),
                    ),
                  ),

                  _buildSectionTitle("Payments and Transactions"),
                  _buildSettingItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Manage Wallet",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WalletPage()),
                    ),
                  ),

                  _buildSectionTitle("Marketing"),
                  _buildSettingItem(
                    icon: Icons.group_outlined,
                    title: "Referrals",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReferralsPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.groups_2_outlined,
                    title: "Crew Clash",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CrewClashPage()),
                    ),
                  ),

                  _buildSectionTitle("Help and Support"),
                  _buildSettingItem(
                    icon: Icons.help_outline,
                    title: "FAQ",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FaqPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.article_outlined,
                    title: "Terms & Conditions",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.headset_mic_outlined,
                    title: "Contact Support",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportPage()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.report_gmailerrorred_outlined,
                    title: "Report Issue",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportPage()),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // LOGOUT BUTTON
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
