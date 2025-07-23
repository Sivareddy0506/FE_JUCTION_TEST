import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_text.dart';
import 'terms_and_conditions.dart';
import '../../widgets/headding_description.dart';

class EduDetailsPage extends StatefulWidget {
  final String email;
  final String otp;
  final String referralCode;

  const EduDetailsPage({
    super.key,
    required this.email,
    required this.otp,
    required this.referralCode,
  });

  @override
  State<EduDetailsPage> createState() => _EduDetailsPageState();
}

class _EduDetailsPageState extends State<EduDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController homeAddressController = TextEditingController();
  final TextEditingController collegeNameController = TextEditingController();

  String? enrollmentMonth;
  String? enrollmentYear;
  String? graduationMonth;
  String? graduationYear;

  final List<String> months = List.generate(12, (index) => DateFormat('MMMM').format(DateTime(0, index + 1)));
  final List<String> years = List.generate(21, (index) => (DateTime.now().year - index).toString());

  bool loading = false;

  bool get isFormValid =>
      fullNameController.text.isNotEmpty &&
      phoneNumberController.text.isNotEmpty &&
      homeAddressController.text.isNotEmpty &&
      collegeNameController.text.isNotEmpty &&
      enrollmentMonth != null &&
      enrollmentYear != null &&
      graduationMonth != null &&
      graduationYear != null;

  void _submitForm() async {
    if (!isFormValid) return;

    setState(() => loading = true);

    final payload = {
      "email": widget.email,
      "otp": widget.otp,
      "fullName": fullNameController.text,
      "phoneNumber": phoneNumberController.text,
      "homeAddress": homeAddressController.text,
      "university": collegeNameController.text,
      "enrollmentYear": int.parse(enrollmentYear!),
      "enrollmentMonth": enrollmentMonth,
      "graduationYear": int.parse(graduationYear!),
      "graduationMonth": graduationMonth,
      "referralCode": widget.referralCode,
    };

    final uri = Uri.http('34.237.61.93:3000', '/user/complete-edu-onboarding');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HeadingWithDescription(
                        heading: 'Personal Information',
                        description: 'You’re almost there! Fill in your details to personalize your experience.',
                      ),
                      const SizedBox(height: 32),
                      const Text('Personal Details', style: TextStyle(fontSize: 14, color: Color(0xFF212121))),
                      const SizedBox(height: 16),
                      AppTextField(label: 'Full Name *', placeholder: 'Eg: Eric John', controller: fullNameController),
                      const SizedBox(height: 16),
                      AppTextField(label: 'Phone Number *', placeholder: 'Eg: 99999 99999', controller: phoneNumberController),
                      const SizedBox(height: 16),
                      AppTextField(label: 'Home Address *', placeholder: 'Eg: 123 Main Street', controller: homeAddressController),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text('University Details', style: TextStyle(fontSize: 14, color: Color(0xFF212121))),
                      const SizedBox(height: 16),
                      AppTextField(label: 'University Name *', placeholder: 'Eg: XYZ University', controller: collegeNameController),
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
                        bottomSpacing: 30,
                        label: loading ? 'Saving...' : 'Save',
                        onPressed: loading ? null : _submitForm,
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
                border: OutlineInputBorder(
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
                border: OutlineInputBorder(
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
      )
    ],
  );
}

}
