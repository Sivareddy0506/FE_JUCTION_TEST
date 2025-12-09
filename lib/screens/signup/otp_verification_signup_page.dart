import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/headding_description.dart';
import 'referral_code_page.dart';
import '../../app.dart'; // For SlidePageRoute

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
  bool otpError = false; // when true, borders turn red and snackbar shown
  bool autoMovedFocusOnPasteHandled = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < controllers.length; i++) {
      controllers[i].addListener(() {
        // refresh UI when controllers change (for enabling button / error reset on typing)
        if (otpError && isOtpComplete) {
          // if user filled all digits after an error, clear error (optional)
          setState(() {
            otpError = false;
          });
        } else {
          setState(() {}); // update button enabled state
        }
      });
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

  bool get isOtpComplete => controllers.every((c) => c.text.trim().length == 1);

  Future<void> _verifyOTP() async {
    final code = controllers.map((c) => c.text.trim()).join();
    if (code.length != 4) return;

    setState(() {
      isSubmitting = true;
      otpError = false;
    });

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
          SlidePageRoute(
            page: ReferralCodePage(email: widget.email, otp: code),
          ),
        );
      } else {
        // Wrong OTP handling: show red snackbar + mark fields as error (borders -> red)
        setState(() {
          otpError = true;
        });

        // Use message exactly as requested
        final snack = SnackBar(
          content: const Text('Incorrect OTP. Please double check'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(snack);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isSubmitting = false);

      final snack = SnackBar(
        content: Text('Network error. Please try again.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(snack);
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
      setState(() {
        otpError = false;
        for (final c in controllers) {
          c.clear();
        }
        FocusScope.of(context).requestFocus(focusNodes[0]);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Verification code resent')));
    } else {
      final responseBody = jsonDecode(response.body);
      final errorMessage =
          responseBody['error'] ?? responseBody['message'] ?? 'Failed to resend code';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Network error. Please try again.')));
  }
}


  // Helper to build input decoration depending on error state
  InputDecoration _otpDecoration() {
    final borderColor = otpError ? Colors.red : const Color(0xFF212121);
    final focusedBorderColor = otpError ? Colors.red : const Color(0xFF212121);
    return InputDecoration(
      counterText: '',
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(
          color: focusedBorderColor,
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildOtpBox(int index) {
  return Container(
    width: 56,
    height: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFF9F9F9),
      border: Border.all(
        color: otpError ? Colors.red : const Color(0xFF212121), // fixed variable name
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: TextField(
      controller: controllers[index],
      focusNode: focusNodes[index],
      maxLength: 1,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Color(0xFF212121),
      ),
      decoration: const InputDecoration(
        counterText: '',
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (value) {
        // Handle paste logic
        if (value.length > 1) {
          final chars = value.split('');
          for (int i = 0; i < chars.length && (index + i) < controllers.length; i++) {
            controllers[index + i].text = chars[i];
          }
          for (int i = index; i < controllers.length; i++) {
            if (controllers[i].text.isEmpty) {
              FocusScope.of(context).requestFocus(focusNodes[i]);
              break;
            } else if (i == controllers.length - 1) {
              FocusScope.of(context).unfocus();
            }
          }
          setState(() {});
          return;
        }

        if (value.isNotEmpty) {
          if (index < focusNodes.length - 1) {
            FocusScope.of(context).requestFocus(focusNodes[index + 1]);
          } else {
            FocusScope.of(context).unfocus();
          }
        } else {
          if (index > 0) {
            FocusScope.of(context).requestFocus(focusNodes[index - 1]);
          }
        }

        setState(() {});
      },
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final bool enableVerify = isOtpComplete && !isSubmitting;

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
  mainAxisAlignment: MainAxisAlignment.start, // ✅ Left align
  children: List.generate(
    4,
    (index) => Padding(
      padding: const EdgeInsets.only(right: 12), // space between boxes
      child: _buildOtpBox(index),
    ),
  ),
),

            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Didn't receive code? "),
                GestureDetector(
                  onTap: _resendCode,
                  child: const Text(
                    'Resend',
                    style: TextStyle(color: Color(0xFFFF6705)),
                  ),
                ),
              ],
            ),
            const Spacer(),
            AppButton(
              bottomSpacing: 24,
              label: isSubmitting ? 'Verifying...' : 'Verify',
              onPressed: enableVerify ? _verifyOTP : null,
              backgroundColor: isSubmitting ? const Color(0xFF8C8C8C) : const Color(0xFF262626),
            ),
          ],
        ),
      ),
    );
  }
}
