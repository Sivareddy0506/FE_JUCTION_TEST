import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/headding_description.dart';
import './referral_code_page_non_edu.dart';
import '../../app.dart'; // For SlidePageRoute

class OtpVerificationNonEduPage extends StatefulWidget {
  final String email;

  const OtpVerificationNonEduPage({super.key, required this.email});

  @override
  State<OtpVerificationNonEduPage> createState() => _OTPVerificationNonEduPageState();
}

class _OTPVerificationNonEduPageState extends State<OtpVerificationNonEduPage> {
  final List<TextEditingController> controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  bool isSubmitting = false;
  bool _hasError = false;
  String _errorMessage = '';

  bool get _isCodeComplete {
    return controllers.every((c) => c.text.trim().isNotEmpty) && !isSubmitting;
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

  String get _currentCode => controllers.map((c) => c.text.trim()).join();

  Future<void> _verifyOTP() async {
    final code = _currentCode;
    if (code.length != 4) return;

    setState(() {
      isSubmitting = true;
      _hasError = false;
      _errorMessage = '';
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
        // Wrong OTP or other server error
        String message = 'Incorrect OTP. Please double check';
        try {
          final responseBody = jsonDecode(response.body);
          final serverMsg = responseBody['message'] as String?;
          if (serverMsg != null && serverMsg.isNotEmpty) message = serverMsg;
        } catch (_) {}

        setState(() {
          _hasError = true;
          _errorMessage = message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSubmitting = false;
        _hasError = true;
        _errorMessage = 'Network error. Please try again.';
      });

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
      setState(() {
        _hasError = false;
        _errorMessage = '';
        for (final c in controllers) {
          c.clear();
        }
      });
      FocusScope.of(context).requestFocus(focusNodes[0]);
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

Widget _buildOtpBox(int index) {
  final borderColor = _hasError ? Colors.red : const Color(0xFFE0E0E0);
  final focusedBorderColor = _hasError ? Colors.red : const Color(0xFF212121);

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
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xFF212121),
      ),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: focusedBorderColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onChanged: (value) {
        if (_hasError && value.isNotEmpty) {
          setState(() {
            _hasError = false;
            _errorMessage = '';
          });
        }

        if (value.isNotEmpty) {
          if (index < focusNodes.length - 1) {
            FocusScope.of(context).requestFocus(focusNodes[index + 1]);
          } else {
            FocusScope.of(context).unfocus();
          }
        } else if (index > 0) {
          FocusScope.of(context).requestFocus(focusNodes[index - 1]);
        }

        setState(() {});
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

            // OTP boxes
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

            // Resend option
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

            // Error banner
            if (_hasError)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _errorMessage.isNotEmpty ? _errorMessage : 'Incorrect OTP. Please double check',
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            AppButton(
              bottomSpacing: 24,
              label: isSubmitting ? 'Verifying...' : 'Verify',
              onPressed: _isCodeComplete ? _verifyOTP : null,
              backgroundColor: _isCodeComplete ? const Color(0xFF262626) : const Color(0xFF8C8C8C),
            ),
          ],
        ),
      ),
    );
  }
}
