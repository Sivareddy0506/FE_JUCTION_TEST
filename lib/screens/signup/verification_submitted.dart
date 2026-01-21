import 'package:flutter/material.dart';
import '../../constants/ui_spacing.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../login/login_page.dart';
import '../../app.dart'; 
class VerificationSubmittedPage extends StatelessWidget {
  const VerificationSubmittedPage({super.key});

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
                'assets/verificationsubmitted.png',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Verification Submitted",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Our team is reviewing your application.\nTill then you can continue browsing Junction.",
              style: TextStyle(
                fontSize: 14,
                height: 1.43,
                color: Color(0xFF262626),
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            AppButton(
              bottomSpacing: kSignupFlowButtonBottomSpacing,
              label: "Continue",
             backgroundColor: const Color(0xFFFF6705),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  SlidePageRoute(
                    page: const LoginPage(),
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
