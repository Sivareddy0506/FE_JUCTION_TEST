import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../constants/ui_spacing.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_button_layout.dart';
import '../../widgets/form_text.dart';
import '../../widgets/privacy_policy_link.dart';
import 'manual_signup_page.dart';
import '../login/login_page.dart';
import 'otp_verification_signup_page.dart';
import '../../widgets/headding_description.dart';
import '../../app.dart'; // For SlidePageRoute

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
      isValidEmail = lowerEmail.endsWith('.edu.in') ||
          lowerEmail.endsWith('.ac.in') ||
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
          SlidePageRoute(
            page: OTPVerificationSignupPage(email: email),
          ),
        );
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final errorMessage = responseData['error'] ?? responseData['message'] ?? 'Failed to send code';
        
        // Show error on same page without navigating
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Ensures the button stays visible when keyboard opens
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
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        viewInsets > 0 ? 24 : 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HeadingWithDescription(
                            heading: 'Create Account',
                            description:
                                "Enter your college email. We will send you a confirmation code there.",
                          ),
                          const SizedBox(height: 32),
                          AppTextField(
                            label: 'Email ID',
                            placeholder: 'Enter College Email ID',
                            isMandatory: true,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            onChanged: _checkEmail,
                          ),
                          const SizedBox(height: 12),
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
                                  SlidePageRoute(
                                    page: const ManualSignupPage(),
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
                        ],
                      ),
                    ),
                  ),
                  BottomButtonLayout(
                    useContainer: true,
                    contentAboveButton: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(fontSize: 14, color: Color(0xFF212121)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                SlidePageRoute(page: const LoginPage()),
                              ),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF6705),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const PrivacyPolicyLink(),
                      ],
                    ),
                    button: AppButton(
                      bottomSpacing: 0, // Container handles spacing
                      label: isLoading ? 'Sending...' : 'Send Verification Code',
                      onPressed: isValidEmail && !isLoading ? _sendVerification : null,
                      backgroundColor:
                          isValidEmail ? const Color(0xFF262626) : const Color(0xFF8C8C8C),
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
