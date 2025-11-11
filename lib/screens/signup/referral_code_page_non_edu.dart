import 'package:flutter/material.dart';
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

  Future<void> _submitCode() async {
    final code = codeController.text.trim();
    setState(() => isLoading = true);

    try {
      if (!mounted) return;
      Navigator.push(
        context,
        SlidePageRoute(
          page: DocumentVerificationPage(email: widget.email),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit referral code')),
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
        page: DocumentVerificationPage(email: widget.email),
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
            const Spacer(),
            AppButton(
              bottomSpacing: 10,
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