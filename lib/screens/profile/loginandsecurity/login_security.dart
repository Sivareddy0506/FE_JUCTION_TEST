import 'package:flutter/material.dart';
import '../../../widgets/custom_appbar.dart';
import './change_phone_number.dart'; // Import the new page

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Widget _buildLoginItem({
    required String iconPath,
    required String title,
    required String description,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(iconPath, width: 24, height: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF262626),
                          ),
                        ),
                      ),
                      Image.asset('assets/CaretRight.png', width: 20, height: 20),
                    ],
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Login & Security"),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ListView(
          children: [
            _buildLoginItem(
              iconPath: 'assets/phoneicon.png',
              title: "Change Phone Number",
              description: "Re-Verification Required",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePhoneNumberPage()),
                );
              },
            ),
            _buildLoginItem(
              iconPath: 'assets/IdentificationBadge.png',
              title: "Campus ID",
              description: "1243121-2523",
              onTap: () {
                // Placeholder for future navigation
              },
            ),
          ],
        ),
      ),
    );
  }
}
