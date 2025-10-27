import 'dart:convert';
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
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;

      bool isSuccess = response.statusCode == 200;
      String message;

      if (isSuccess) {
        message = 'Verification code sent!';
      } else {
        try {
          final data = jsonDecode(response.body);
          message = data['error'] ?? 'Failed to send verification code';
        } catch (_) {
          message = 'Failed to send verification code';
        }
      }

      // Show SnackBar with proper color
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.black : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      if (isSuccess) {
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationLoginPage(email: email),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 24.0;

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
      body: SafeArea(
        child: Column(
          children: [
           Expanded(
  child: SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HeadingWithDescription(
          heading: 'Log In',
          description: "Enter your registered Email ID.",
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
        const SizedBox(height: 8),
        // Inline error message for invalid email
        if (!isValidEmail && _emailController.text.isNotEmpty)
          const Text(
            'Please enter a valid email address.',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        const SizedBox(height: 40),
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
        const SizedBox(height: 24), // ✅ reduced gap to 24px
      ],
    ),
  ),
),
Padding(
  padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
  child: AppButton(
    label: isLoading ? 'Sending...' : 'Send Verification Code',
    onPressed: isValidEmail && !isLoading ? _login : null,
    backgroundColor: isValidEmail ? const Color(0xFF262626) : const Color(0xFFA3A3A3),
  ),
),

          
          ],
        ),
      ),
    );
  }
}
