import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_text.dart';
import '../signup/signup_page.dart';
import '../../widgets/headding_description.dart';
import './otp_verification_login.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  bool isValidEmail = false;
  bool isLoading = false;

  void _checkEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    setState(() {
      isValidEmail = emailRegex.hasMatch(email);
    });
  }

  Future<void> _login() async {
  final email = _emailController.text.trim();
  if (!isValidEmail) return;

  setState(() => isLoading = true);

  final uri = Uri.parse('https://api.junctionverse.com/user/auth/login');
  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: '{"email": "$email"}',
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code sent!')),
      );

      // Navigate to OTP Verification page after a slight delay (optional)
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerificationLoginPage(email: email),
        ),
      );
    } else {
      // Show error from response body or fallback message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${response.body.isNotEmpty ? response.body : 'Failed to send verification code'}'),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Network error: $e')),
    );
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}


  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
              heading: 'Log In',
              description:
                  "Enter your registered Email ID.",
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
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'New here?',
                  style: TextStyle(fontSize: 14, color: Color(0xFF212121)),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    );
                  },
                  child: const Text(
                    'Create an account',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              bottomSpacing: 30,
              label: isLoading ? 'Sending...' : 'Send Verification Code',
              onPressed: isValidEmail && !isLoading ? _login : null,
              backgroundColor: isValidEmail
                  ? const Color(0xFF262626)
                  : const Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }
}
