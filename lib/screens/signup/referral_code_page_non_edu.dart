import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/form_text.dart';
import '../../widgets/headding_description.dart';
import 'document_verification_page.dart';
import '../../app.dart'; // For SlidePageRoute 

class ReferralCodePage extends StatefulWidget {
  final String email;
  final String otp;

  const ReferralCodePage({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ReferralCodePage> createState() => _ReferralCodePageState();
}

class _ReferralCodePageState extends State<ReferralCodePage> {
  final TextEditingController codeController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> _submitCode() async {
    final code = codeController.text.trim();
    
    if (code.isEmpty) {
      // If empty, proceed with empty referral code (skip scenario)
      Navigator.push(
        context,
        SlidePageRoute(
          page: DocumentVerificationPage(email: widget.email, referralCode: ''),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Validate referral code
      final uri = Uri.parse('https://api.junctionverse.com/user/validate-referral-code');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'referralCode': code}),
      );

      if (!mounted) return;

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['valid'] == true) {
        // Valid referral code - proceed
        Navigator.push(
          context,
          SlidePageRoute(
            page: DocumentVerificationPage(email: widget.email, referralCode: code),
          ),
        );
      } else {
        // Invalid referral code
        setState(() {
          errorMessage = responseBody['error'] ?? 'Invalid referral code';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Invalid referral code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to validate referral code. Please try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to submit referral code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _skip() {
    Navigator.push(
      context,
      SlidePageRoute(
        page: DocumentVerificationPage(email: widget.email, referralCode: ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: true,
        logoAssets: [
          'assets/logo-a.png',
          'assets/logo-b.png',
          'assets/logo-c.png',
          'assets/logo-d.png',
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeadingWithDescription(
              heading: 'Enter Referral Code Non Edu',
              description: 'Do you have a referral code?',
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Referral Code',
              placeholder: 'Enter referral code',
              controller: codeController,
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const Spacer(),
            AppButton(
              bottomSpacing: 60,
              label: isLoading ? 'Verifying...' : 'Submit for Verification',
              onPressed: isLoading ? null : _submitCode,
              backgroundColor:
                  isLoading ? const Color(0xFF8C8C8C) : const Color(0xFF262626),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Center(
                child: TextButton(
                  onPressed: isLoading ? null : _skip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF262626),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}