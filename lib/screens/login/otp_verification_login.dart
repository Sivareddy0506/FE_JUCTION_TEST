import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/headding_description.dart';
import '../profile/user_profile.dart';
import '../signup/verification_submitted.dart';
import '../signup/verification_rejected.dart';

class OTPVerificationLoginPage extends StatefulWidget {
  final String email;

  const OTPVerificationLoginPage({super.key, required this.email});

  @override
  State<OTPVerificationLoginPage> createState() => _OTPVerificationLoginPageState();
}

class _OTPVerificationLoginPageState extends State<OTPVerificationLoginPage> {
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
  if (code.length != 4) {
    print("OTP code is not complete: $code");
    return;
  }

  print("Verifying OTP for email: ${widget.email}");
  print("Entered OTP: $code");

  setState(() => isSubmitting = true);

  final uri = Uri.parse('https://api.junctionverse.com/user/auth/verify-login-otp');

  try {
    final payload = {
      'email': widget.email,
      'otp': code,
    };
    print("Sending payload: $payload");

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = responseBody['token'];
      final user = responseBody['user'];

      if (user == null) {
        print("User object is missing in response.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unexpected response. Please try again.")),
        );
        return;
      }

      final bool isOnboarded = user['isOnboarded'] ?? false;
      final String userStatus = user['userStatus'] ?? '';
      final String fullName = user['fullName'] ?? 'User';

      if (!isOnboarded) {
        print("User is not onboarded. Blocking login.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User not onboarded. Please signup first."),
          ),
        );
        return;
      }

      // Save token
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);
        print("Token saved to SharedPreferences");
      }

      // Navigate based on userStatus
      if (userStatus == 'Active') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLogin', true);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserProfilePage()),
              (Route<dynamic> route) => false, // removes all previous routes
        );
      } else if (userStatus == 'Pending' || userStatus == 'Submitted') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerificationSubmittedPage()),
        );
      } else if (userStatus == 'Rejected') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerificationRejectedPage()),
        );
      } else {
        print("⚠️ Unknown userStatus: $userStatus");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unhandled user status: $userStatus")),
        );
      }
    } else {
      final errorMessage = responseBody['message'] ?? 'Invalid code';
      print("Error from server: $errorMessage");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  } catch (e) {
    print("Exception occurred during OTP verification: $e");
    if (!mounted) return;
    setState(() => isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network error. Please try again.')),
    );
  }
}


  Future<void> _resendCode() async {
    final uri = Uri.parse('https://api.junctionverse.com/user/resend-verification-code');

    print("Resending OTP for email: ${widget.email}");

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      print("Resend Response status: ${response.statusCode}");
      print("Resend Response body: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent')),
        );
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? 'Failed to resend code';
        print("Error while resending OTP: $errorMessage");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print("Exception occurred while resending OTP: $e");
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
