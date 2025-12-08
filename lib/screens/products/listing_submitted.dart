import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../profile/user_profile.dart';
import '../../app.dart'; // For SlidePageRoute

class ListingSubmittedPage extends StatelessWidget {
  const ListingSubmittedPage({super.key});

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
                'assets/SubmitListingSuccess.png',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Your listing has been submitted",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "We're reviewing your item to ensure it meets our guidelines. You'll be notified as soon as it's live.",
              style: TextStyle(
                fontSize: 14,
                height: 1.43,
                color: Color(0xFF262626),
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            AppButton(
              bottomSpacing: 24,
              label: "Return to Profile",
              backgroundColor: const Color(0xFFFF6705),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  SlidePageRoute(page: const UserProfilePage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

