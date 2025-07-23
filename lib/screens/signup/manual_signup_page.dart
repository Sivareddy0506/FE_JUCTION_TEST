import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_text.dart';
import './otp_verification_non_edu.dart';

class ManualSignupPage extends StatefulWidget {
  const ManualSignupPage({super.key});

  @override
  State<ManualSignupPage> createState() => _ManualSignupPageState();
}

class _ManualSignupPageState extends State<ManualSignupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController personalEmailController = TextEditingController();
  final TextEditingController homeAddressController = TextEditingController();
  final TextEditingController collegeNameController = TextEditingController();

  String? enrollmentMonth;
  String? enrollmentYear;
  String? graduationMonth;
  String? graduationYear;

  final List<String> months =
      List.generate(12, (index) => DateFormat('MMMM').format(DateTime(0, index + 1)));
  final List<String> years = List.generate(21, (index) => (DateTime.now().year - index).toString());

  bool get isFormValid =>
      fullNameController.text.isNotEmpty &&
      phoneNumberController.text.isNotEmpty &&
      personalEmailController.text.isNotEmpty &&
      homeAddressController.text.isNotEmpty &&
      collegeNameController.text.isNotEmpty &&
      enrollmentMonth != null &&
      enrollmentYear != null &&
      graduationMonth != null &&
      graduationYear != null;

  void _submitForm() async {
    final payload = {
      "email": personalEmailController.text,
      "fullName": fullNameController.text,
      "phoneNumber": phoneNumberController.text,
      "homeAddress": homeAddressController.text,
      "university": collegeNameController.text,
      "enrollmentYear": int.parse(enrollmentYear!),
      "enrollmentMonth": enrollmentMonth,
      "graduationYear": int.parse(graduationYear!),
      "graduationMonth": graduationMonth,
      "referralCode": "",
      "userType": "student"
    };

    final uri = Uri.parse('https://api.junctionverse.com/user/register-non-edu');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationNonEduPage(email: personalEmailController.text),
          ),
        );
      } else {
        final responseBody = jsonDecode(response.body);
        final error = responseBody['message'] ?? 'Something went wrong';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Secure your spot',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF262626))),
                      const SizedBox(height: 4),
                      const Text('Get verified in minutes.', style: TextStyle(fontSize: 12, color: Color(0xFF323537))),
                      const SizedBox(height: 32),
                      const Text('Personal Details', style: TextStyle(fontSize: 14, color: Color(0xFF212121))),
                      const SizedBox(height: 16),
                      AppTextField(label: 'Full Name *', placeholder: 'Eg: Eric John', controller: fullNameController),
                      const SizedBox(height: 16),
                      AppTextField(label: 'Phone Number *', placeholder: 'Eg: 99999 99999', controller: phoneNumberController),
                      const SizedBox(height: 16),
                      AppTextField(label: 'Personal Email ID *', placeholder: 'ericjohn@example.com', controller: personalEmailController),
                      const SizedBox(height: 16),
                      AppTextField(label: 'Home Address *', placeholder: 'Eg: Mannuthy, Thrissur, Kerala 680651', controller: homeAddressController),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text('University Details', style: TextStyle(fontSize: 14, color: Color(0xFF212121))),
                      const SizedBox(height: 16),
                      AppTextField(label: 'College Name *', placeholder: 'Eg: Christ University', controller: collegeNameController),
                      const SizedBox(height: 16),
                      _buildDualDropdown(
                        label: 'Enrollment',
                        monthValue: enrollmentMonth,
                        yearValue: enrollmentYear,
                        onMonthChanged: (val) => setState(() => enrollmentMonth = val),
                        onYearChanged: (val) => setState(() => enrollmentYear = val),
                      ),
                      const SizedBox(height: 16),
                      _buildDualDropdown(
                        label: 'Graduation',
                        monthValue: graduationMonth,
                        yearValue: graduationYear,
                        onMonthChanged: (val) => setState(() => graduationMonth = val),
                        onYearChanged: (val) => setState(() => graduationYear = val),
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Save',
                        onPressed: isFormValid ? _submitForm : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDualDropdown({
    required String label,
    required String? monthValue,
    required String? yearValue,
    required ValueChanged<String?> onMonthChanged,
    required ValueChanged<String?> onYearChanged,
  }) {
    const borderColor = Color(0xFF212121);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF212121))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: monthValue,
                decoration: InputDecoration(
                  hintText: 'Month',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: onMonthChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: yearValue,
                decoration: InputDecoration(
                  hintText: 'Year',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: onYearChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
