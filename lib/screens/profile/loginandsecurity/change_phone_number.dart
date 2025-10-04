import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/form_text.dart';
import '../../../widgets/headding_description.dart';
import './verify_phone_otp.dart';
import 'package:flutter/services.dart';

class ChangePhoneNumberPage extends StatefulWidget {
  const ChangePhoneNumberPage({super.key});

  @override
  State<ChangePhoneNumberPage> createState() => _ChangePhoneNumberPageState();
}

class _ChangePhoneNumberPageState extends State<ChangePhoneNumberPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool isValidPhone = false;
  bool isLoading = false;
  String? errorMessage;

  void _validatePhone(String phone) {
  setState(() {
    errorMessage = null;
    
    if (phone.isEmpty) {
      isValidPhone = false;
      return;
    }

    final cleaned = _cleanPhoneNumber(phone);
    
    if (!_isValidIndianMobile(phone)) {
      if (cleaned.length < 10) {
        errorMessage = 'Phone number must be 10 digits';
      } else if (cleaned.length > 10) {
        errorMessage = 'Phone number should not exceed 10 digits';
      } else if (!RegExp(r'^[6-9]').hasMatch(cleaned)) {
        errorMessage = 'Phone number must start with 6, 7, 8, or 9';
      } else {
        errorMessage = 'Please enter a valid Indian mobile number';
      }
      isValidPhone = false;
    } else {
      isValidPhone = true;
    }
  });
}

bool _isValidIndianMobile(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^\d+]'), '');
  
  final RegExp indianMobilePattern = RegExp(r'^(?:\+91|91)?[6-9]\d{9}$');
  
  return indianMobilePattern.hasMatch(cleaned);
}

String _cleanPhoneNumber(String phone) {
  String cleaned = phone.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^\d+]'), '');
  
  if (cleaned.startsWith('+91')) {
    cleaned = cleaned.substring(3);
  } else if (cleaned.startsWith('91') && cleaned.length > 10) {
    cleaned = cleaned.substring(2);
  }
  
  return cleaned;
}

  Future<void> _sendPhoneVerification() async {
    final phone = _cleanPhoneNumber(_phoneController.text.trim());
    
    if (!isValidPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access token not found. Please login again.')),
        );
        setState(() => isLoading = false);
        return;
      }

      final uri = Uri.parse('https://api.junctionverse.com/user/send-phone-otp');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'phoneNumber': phone}),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyPhoneOTPPage(phoneNumber: phone),
          ),
        );
      } else {
        final res = jsonDecode(response.body);
        final error = res['message'] ?? 'Failed to send OTP';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

@override
void dispose() {
  _phoneController.dispose();
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeadingWithDescription(
              heading: 'Enter New Phone Number',
              description: 'Enter your new phone number below. We’ll send you an OTP to verify the change.',
            ),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Phone Number',
              placeholder: 'Eg. 99623187642',
              isMandatory: true,
              keyboardType: TextInputType.phone,
              controller: _phoneController,
              onChanged: _validatePhone,
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            const Spacer(),
            AppButton(
              label: isLoading ? 'Sending...' : 'Send Verification Code',
              bottomSpacing: 30,
              onPressed: isValidPhone && !isLoading ? _sendPhoneVerification : null,
              backgroundColor: isValidPhone && !isLoading
                  ? const Color(0xFF262626)
                  : const Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }
}
