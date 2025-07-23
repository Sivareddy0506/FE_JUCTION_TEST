import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/headding_description.dart';
import 'referral_code_page.dart';

class OTPVerificationSignupPage extends StatefulWidget {
  final String email;

  const OTPVerificationSignupPage({super.key, required this.email});

  @override
  State<OTPVerificationSignupPage> createState() => _OTPVerificationSignupPageState();
}

class _OTPVerificationSignupPageState extends State<OTPVerificationSignupPage> {
  final List<TextEditingController> controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  bool isSubmitting = false;

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    for (final node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    final code = controllers.map((c) => c.text).join();
    if (code.length != 4) return;

    setState(() => isSubmitting = true);

    final uri = Uri.parse('https://api.junctionverse.com/user/verify-code');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': code,
        }),
      );

      if (!mounted) return;
      setState(() => isSubmitting = false);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final token = responseBody['token'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', token);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verified!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReferralCodePage(email: widget.email, otp: code),
          ),
        );
      } else {
        if (!mounted) return;
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? 'Invalid code';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
  }

  Future<void> _resendCode() async {
    final uri = Uri.parse('https://api.junctionverse.com/user/resend-verification-code');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent')),
        );
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? 'Failed to resend code';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeadingWithDescription(
              heading: 'Enter Verification Code',
              description: 'Enter the verification code we just sent to your email address',
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (index) => SizedBox(
                  width: 56,
                  height: 56,
                  child: TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Color(0xFF212121),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Color(0xFF212121),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Didn't receive code? "),
                GestureDetector(
                  onTap: _resendCode,
                  child: const Text(
                    'Resend',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
            const Spacer(),
            AppButton(
              bottomSpacing: 24,
              label: isSubmitting ? 'Verifying...' : 'Verify',
              onPressed: isSubmitting ? null : _verifyOTP,
              backgroundColor: isSubmitting ? const Color(0xFFBDBDBD) : const Color(0xFF262626),
            ),
          ],
        ),
      ),
    );
  }
}
