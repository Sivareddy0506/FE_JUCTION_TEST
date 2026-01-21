import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/ui_spacing.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import './manual_signup_page.dart';
import '../../app.dart'; // For SlidePageRoute
class VerificationRejectedPage extends StatefulWidget {
  const VerificationRejectedPage({super.key});

  @override
  State<VerificationRejectedPage> createState() => _VerificationRejectedPageState();
}

class _VerificationRejectedPageState extends State<VerificationRejectedPage> {
  String rejectedReason = "Fetching reason...";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRejectedReason();
  }

  Future<void> fetchRejectedReason() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        setState(() {
          rejectedReason = "Unauthorized access";
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reason = data['rejectedReason'] ?? "Verification failed. Please try again.";
        setState(() {
          rejectedReason = reason;
          isLoading = false;
        });
      } else {
        setState(() {
          rejectedReason = "Failed to fetch reason";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        rejectedReason = "Something went wrong while fetching profile.";
        isLoading = false;
      });
    }
  }

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
                'assets/verification-unsuccess.png',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isLoading ? "Loading..." : rejectedReason,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Your application was not approved.\nPlease try signing up again with accurate information.",
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
              label: "Go to Signup",
             backgroundColor: const Color(0xFFFF6705),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  SlidePageRoute(
                    page: const ManualSignupPage(),
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
