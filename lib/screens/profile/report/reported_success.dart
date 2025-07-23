import 'package:flutter/material.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../profile/account_settings_page.dart';

class ReportedSuccessPage extends StatelessWidget {
  const ReportedSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: false,
        logoAssets: [
          'assets/logo-a.png',
          'assets/logo-b.png',
          'assets/logo-c.png',
          'assets/logo-d.png',
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Center(
              child: Image.asset(
                'assets/ProductManual.png',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Issue Reported Successfully",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Thanks for letting us know we’ve received your report and will look into it.",
              style: TextStyle(
                fontSize: 14,
                height: 1.43, // 20px line height / 14px font size
                color: Color(0xFF262626),
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            AppButton(
              bottomSpacing: 24,
              label: "Return to Settings",
              backgroundColor: Colors.orange,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
