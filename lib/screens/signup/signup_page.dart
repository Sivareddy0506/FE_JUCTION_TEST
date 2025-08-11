import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_text.dart';
import 'manual_signup_page.dart';
import '../login/login_page.dart';
import 'package:junction/screens/signup/otp_verification_signup_page.dart';
import '../../widgets/headding_description.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  bool isValidEmail = false;
  bool isLoading = false;

  void _checkEmail(String email) {
    final lowerEmail = email.toLowerCase();
    setState(() {
      isValidEmail = lowerEmail.endsWith('.cc') ||
          lowerEmail.endsWith('.edu') ||
          lowerEmail.endsWith('@junctionverse.com');
    });
  }

  Future<void> _sendVerification() async {
    final email = _emailController.text.trim();
    if (!isValidEmail || isLoading) return;

    setState(() => isLoading = true);

    try {
      final uri = Uri.parse('https://api.junctionverse.com/user/register-edu');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationSignupPage(email: email),
          ),
        );
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ?? 'Failed to send code';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
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
            const SizedBox(height: 16),
            const HeadingWithDescription(
              heading: 'Create Account',
              description:
                  "Enter your college email. We will send you a confirmation code there.",
            ),
            const SizedBox(height: 32),
            AppTextField(
              label: 'College Email',
              placeholder: 'Enter your college email',
              isMandatory: true,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              onChanged: _checkEmail,
            ),
            const SizedBox(height: 12),

            /// "No College Email? Verify Manually"
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'No College Email? ',
                  style: TextStyle(fontSize: 14, color: Color(0xFF212121)),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManualSignupPage(),
                    ),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text(
                    'Verify Manually',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6705),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            /// "Already have an account? Log In"
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(fontSize: 14, color: Color(0xFF212121)),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Send Verification Button
            AppButton(
              label: isLoading ? 'Sending...' : 'Send Verification Code',
              bottomSpacing: 30,
              onPressed: isValidEmail && !isLoading ? _sendVerification : null,
              backgroundColor:
                  isValidEmail ? const Color(0xFF262626) : const Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }
}
