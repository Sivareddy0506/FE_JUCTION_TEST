import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/headding_description.dart';
import '../profile/user_profile.dart';
import '../signup/verification_submitted.dart';
import '../signup/verification_rejected.dart';
import '../../app.dart'; // For SlidePageRoute
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
  bool isResending = false;
  bool hasError = false;
  String errorMessage = '';
  DateTime? _lastResendTime;
  static const Duration _resendCooldown = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    _lastResendTime = DateTime.now();
    for (final controller in controllers) {
      controller.addListener(() => setState(() {}));
    }
  }

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

  bool get _isOTPComplete => controllers.every((c) => c.text.length == 1);

  void _clearOTPFields() {
    for (final controller in controllers) {
      controller.clear();
    }
    FocusScope.of(context).requestFocus(focusNodes[0]);
  }

  Future<void> _verifyOTP() async {
    final code = controllers.map((c) => c.text).join();
    if (code.length != 4) return;

    setState(() {
      isSubmitting = true;
      hasError = false;
      errorMessage = '';
    });

    final uri = Uri.parse('https://api.junctionverse.com/user/auth/verify-login-otp');

    try {
      final payload = {'email': widget.email, 'otp': code};

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      setState(() => isSubmitting = false);

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = responseBody['token'];
        final user = responseBody['user'];
        final userId = user?['id'] ?? '';

        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unexpected response. Please try again.")),
          );
          return;
        }

        final bool isOnboarded = user['isOnboarded'] ?? false;
        final String userStatus = user['userStatus'] ?? '';
        final String fullName = user['fullName'] ?? 'User';

        if (!isOnboarded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User not onboarded. Please signup first.")),
          );
          return;
        }

        // Save token and user info
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', token);
          await prefs.setString('userId', userId);
          await prefs.setString('fullName', fullName);
        }

        if (userStatus == 'Active') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLogin', true);

          final customTokenResponse = await http.post(
            Uri.parse('https://api.junctionverse.com/user/firebase/createcustomtoken'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userId': userId}),
          );

          if (customTokenResponse.statusCode == 200) {
            final customToken = jsonDecode(customTokenResponse.body)['token'];
            await FirebaseAuth.instance.signInWithCustomToken(customToken);
            await prefs.setString('firebaseUserId', FirebaseAuth.instance.currentUser?.uid ?? '');
            await prefs.setString('firebaseToken', customToken);

            Navigator.pushAndRemoveUntil(
              context,
              SlidePageRoute(page: const UserProfilePage()),
              (Route<dynamic> route) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to login. Please try again.')),
            );
          }
        } else if (userStatus == 'Pending' || userStatus == 'Submitted') {
          Navigator.pushReplacement(
            context,
            SlidePageRoute(page: const VerificationSubmittedPage()),
          );
        } else if (userStatus == 'Rejected') {
          Navigator.pushReplacement(
            context,
            SlidePageRoute(page: const VerificationRejectedPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Unhandled user status: $userStatus")),
          );
        }
      } else {
        _clearOTPFields();
        setState(() {
          hasError = true;
          errorMessage = 'Incorrect OTP. Please double check';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSubmitting = false;
        hasError = true;
        errorMessage = 'Network error. Please try again.';
      });
    }
  }

  Future<void> _resendCode() async {
    if (_lastResendTime != null) {
      final timeSinceLastResend = DateTime.now().difference(_lastResendTime!);
      if (timeSinceLastResend < _resendCooldown) {
        final remainingSeconds = (_resendCooldown - timeSinceLastResend).inSeconds;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please wait $remainingSeconds seconds before resending')),
        );
        return;
      }
    }

    if (isResending) return;
    setState(() => isResending = true);

    final uri = Uri.parse('https://api.junctionverse.com/user/resend-verification-code');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (!mounted) return;
      setState(() => isResending = false);

      if (response.statusCode == 200) {
        _lastResendTime = DateTime.now();
        _clearOTPFields();
        setState(() {
          hasError = false;
          errorMessage = '';
        });

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
    } catch (_) {
      if (!mounted) return;
      setState(() => isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
  }

 Widget _buildOtpBox(int index) {
  final borderColor = hasError ? Colors.red : const Color(0xFF212121);
  final focusedBorderColor = hasError ? Colors.red : const Color(0xFF212121);

  return SizedBox(
    width: 56,
    height: 56,
    child: TextField(
      controller: controllers[index],
      focusNode: focusNodes[index],
      maxLength: 1,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.0, // prevents extra vertical padding
      ),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.zero, // removes default padding
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), // slightly larger for clean edges
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: focusedBorderColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
      ),
      onChanged: (value) {
        if (hasError && value.isNotEmpty) {
          setState(() {
            hasError = false;
            errorMessage = '';
          });
        }
        if (value.isNotEmpty && index < 3) {
          FocusScope.of(context).requestFocus(focusNodes[index + 1]);
        } else if (value.isEmpty && index > 0) {
          FocusScope.of(context).requestFocus(focusNodes[index - 1]);
        }
      },
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeadingWithDescription(
              heading: 'Enter Verification Code',
              description: 'Enter the verification code we just sent to your email address',
            ),
            const SizedBox(height: 32),

            // OTP boxes row (left-aligned)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(
                4,
                (index) => Padding(
                  padding: EdgeInsets.only(right: index == 3 ? 0 : 12),
                  child: _buildOtpBox(index),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Text("Didn't receive code? "),
                GestureDetector(
                  onTap: isResending ? null : _resendCode,
                  child: Text(
                    isResending ? 'Resending...' : 'Resend',
                    style: TextStyle(
                      color: isResending ? Colors.grey : const Color(0xFFFF6705),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            if (hasError)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  errorMessage.isNotEmpty ? errorMessage : 'Incorrect OTP. Please double check',
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            AppButton(
              bottomSpacing: 24,
              label: isSubmitting ? 'Verifying...' : 'Verify',
              onPressed: (!_isOTPComplete || isSubmitting) ? null : _verifyOTP,
              backgroundColor: (!_isOTPComplete || isSubmitting)
                  ? const Color(0xFF8C8C8C)
                  : const Color(0xFFFF6705), // orange button
            ),
          ],
        ),
      ),
    );
  }
}
