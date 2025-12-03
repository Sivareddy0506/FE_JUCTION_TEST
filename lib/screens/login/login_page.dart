import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_text.dart';
import '../../widgets/privacy_policy_link.dart';
import '../signup/signup_page.dart';
import '../../widgets/headding_description.dart';
import './otp_verification_login.dart';
import '../../app.dart'; // For SlidePageRoute
import '../../utils/error_handler.dart';

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

      if (response.statusCode == 200) {
        ErrorHandler.showSuccessSnackBar(context, 'Verification code sent!');
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.push(
          context,
          SlidePageRoute(
            page: OTPVerificationLoginPage(email: email),
          ),
        );
      } else {
        ErrorHandler.showErrorSnackBar(context, null, response: response);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        showBackButton: true,
        logoAssets: const [
          'assets/logo-a.png',
          'assets/logo-b.png',
          'assets/logo-c.png',
          'assets/logo-d.png',
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewInsets = MediaQuery.of(context).viewInsets.bottom;
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          if (!isValidEmail && _emailController.text.isNotEmpty)
                            const Text(
                              'Please enter a valid email address.',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 16,
                      bottom: viewInsets > 0 ? viewInsets + 16 : 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'New here? ',
                              style: TextStyle(fontSize: 14, color: Color(0xFF212121)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  SlidePageRoute(page: const SignupPage()),
                                );
                              },
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
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
                        const SizedBox(height: 12),
                        const PrivacyPolicyLink(),
                        AppButton(
                          label: isLoading ? 'Sending...' : 'Send Verification Code',
                          onPressed: isValidEmail && !isLoading ? _login : null,
                          backgroundColor:
                              isValidEmail ? const Color(0xFF262626) : const Color(0xFF8C8C8C),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

}
