import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/form_text.dart';
import '../../../widgets/headding_description.dart';
import './verify_phone_otp.dart';

class ChangePhoneNumberPage extends StatefulWidget {
  const ChangePhoneNumberPage({super.key});

  @override
  State<ChangePhoneNumberPage> createState() => _ChangePhoneNumberPageState();
}

class _ChangePhoneNumberPageState extends State<ChangePhoneNumberPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool isValidPhone = false;
  bool isLoading = false;

  void _checkPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    setState(() {
      isValidPhone = cleaned.length >= 10 && cleaned.length <= 12;
    });
  }

  Future<void> _sendPhoneVerification() async {
    final phone = _phoneController.text.trim();
    if (!isValidPhone) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken'); // fixed from accessToken

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access token not found')),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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
              onChanged: _checkPhone,
            ),
            const Spacer(),
            AppButton(
              label: isLoading ? 'Sending...' : 'Send Verification Code',
              bottomSpacing: 30,
              onPressed: () {
                if (!isLoading && isValidPhone) {
                  _sendPhoneVerification();
                }
              },
              backgroundColor: isValidPhone ? const Color(0xFF262626) : const Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }
}
