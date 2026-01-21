import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../constants/ui_spacing.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_text.dart';
import '../../widgets/privacy_policy_link.dart';
import '../../widgets/university_autocomplete.dart';
import './otp_verification_non_edu.dart';
import '../../app.dart'; // For SlidePageRoute
import '../../utils/error_handler.dart';

class ManualSignupPage extends StatefulWidget {
  const ManualSignupPage({super.key});

  @override
  State<ManualSignupPage> createState() => _ManualSignupPageState();
}

class _ManualSignupPageState extends State<ManualSignupPage> {
  final _formKey = GlobalKey<FormState>();

  static const int maxFullNameLength = 50;
  static const int maxUniversityNameLength = 100;
  static const int maxHomeAddressLength = 200;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController personalEmailController = TextEditingController();
  final TextEditingController homeAddressController = TextEditingController();
  final TextEditingController collegeNameController = TextEditingController();

  String? fullNameError;
  String? phoneError;
  String? emailError;
  String? universityError;
  String? homeAddressError;
  String? dateError;

  String? enrollmentMonth;
  String? enrollmentYear;
  String? graduationMonth;
  String? graduationYear;
  String? selectedUniversityId; // Store selected university ID

  bool loading = false;

  final List<String> months =
      List.generate(12, (index) => DateFormat('MMMM').format(DateTime(0, index + 1)));

  late final List<String> enrollmentYears =
      List.generate(4, (index) => (DateTime.now().year - index).toString()); // current year to 3 yrs back
  late final List<String> graduationYears =
      List.generate(6, (index) => (DateTime.now().year + index).toString()); // current to 5 yrs ahead

  bool get isFormValid {
    final isNameValid = _validateFullName(fullNameController.text) == null;
    final isPhoneValid = _validatePhone(phoneNumberController.text) == null;
    final isEmailValid = _validateEmail(personalEmailController.text) == null;
    final isAddressValid = _validateHomeAddress(homeAddressController.text) == null;
    final isUniversityValid = _validateUniversity(collegeNameController.text) == null;
    final areDatesValid = _validateDates() == null;

    return fullNameController.text.isNotEmpty &&
        phoneNumberController.text.isNotEmpty &&
        personalEmailController.text.isNotEmpty &&
        homeAddressController.text.isNotEmpty &&
        collegeNameController.text.isNotEmpty &&
        isNameValid &&
        isPhoneValid &&
        isEmailValid &&
        isAddressValid &&
        isUniversityValid &&
        enrollmentMonth != null &&
        enrollmentYear != null &&
        graduationMonth != null &&
        graduationYear != null &&
        areDatesValid;
  }

  // -------------------- VALIDATION METHODS --------------------
  String? _validateFullName(String value) {
    if (value.isEmpty) return null;
    if (value.length > maxFullNameLength) return 'Name cannot exceed $maxFullNameLength characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return 'Name should contain only letters';
    if (value.trim().length < 3) return 'Name must be at least 3 characters';
    final nameParts = value.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (nameParts.length < 2) return 'Please enter your full name (first and last name)';
    return null;
  }

  String? _validatePhone(String value) {
    if (value.isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    final indianMobilePattern = RegExp(r'^(?:\+91|91)?[6-9]\d{9}$');
    if (!indianMobilePattern.hasMatch(cleaned)) {
      final digitsOnly = cleaned.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.isEmpty) return 'Please enter a phone number';
      if (digitsOnly.length < 10) return 'Phone number must be 10 digits';
      if (digitsOnly.length > 10) return 'Phone number should not exceed 10 digits';
      if (!RegExp(r'^[6-9]').hasMatch(digitsOnly)) return 'Phone number must start with 6, 7, 8, or 9';
      return 'Please enter a valid Indian mobile number';
    }
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return null;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email address';
    if (value.length > 100) return 'Email address is too long';
    return null;
  }

  String? _validateUniversity(String value) {
    if (value.isEmpty) return null;
    if (value.length > maxUniversityNameLength) return 'University name cannot exceed $maxUniversityNameLength characters';
    if (value.trim().length < 3) return 'University name must be at least 3 characters';
    if (RegExp(r'^\d+$').hasMatch(value.trim())) return 'Please enter a valid university name';
    return null;
  }

  String? _validateHomeAddress(String value) {
    if (value.isEmpty) return null;
    if (value.length > maxHomeAddressLength) return 'Address cannot exceed $maxHomeAddressLength characters';
    if (value.trim().length < 10) return 'Address must be at least 10 characters';
    if (!RegExp(r"^[a-zA-Z0-9\s,.\-/'#()]+$").hasMatch(value)) return 'Address contains invalid characters';
    if (RegExp(r"[,.\-/\'#()]{4,}").hasMatch(value)) return 'Please enter a valid address format';
    if (RegExp(r'(.)\1{4,}').hasMatch(value)) return 'Please enter a valid address';
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) return 'Address must contain letters';
    if (!RegExp(r'\d').hasMatch(value)) return 'Address must contain at least one number';
    final words = RegExp(r'[a-zA-Z]{2,}').allMatches(value);
    if (words.length < 2) return 'Please enter a complete address with street number and name';
    return null;
  }

  String? _validateDates() {
    if (enrollmentMonth == null || enrollmentYear == null || graduationMonth == null || graduationYear == null) return null;

    final enrollYear = int.parse(enrollmentYear!);
    final gradYear = int.parse(graduationYear!);
    final currentYear = DateTime.now().year;

    if (enrollYear > currentYear) return 'Enrollment year cannot be in the future';
    if (enrollYear < currentYear - 3) return 'Enrollment year cannot be more than 3 years ago';
    if (gradYear > currentYear + 5) return 'Graduation year cannot be more than 5 years from now';

    final enrollMonthIndex = months.indexOf(enrollmentMonth!) + 1;
    final gradMonthIndex = months.indexOf(graduationMonth!) + 1;

    final enrollDate = DateTime(enrollYear, enrollMonthIndex, 1);
    final gradDate = DateTime(gradYear, gradMonthIndex, 1);

    if (!gradDate.isAfter(enrollDate)) return 'Graduation date must be after enrollment date';

    final monthsDifference = (gradYear - enrollYear) * 12 + (gradMonthIndex - enrollMonthIndex);
    if (monthsDifference < 12) return 'Graduation must be at least 1 year after enrollment';
    if (monthsDifference > 96) return 'Course duration seems too long. Please verify dates';

    return null;
  }

  void _onDateChanged() => setState(() => dateError = _validateDates());
  void _onFullNameChanged(String val) => setState(() => fullNameError = _validateFullName(val));
  void _onPhoneChanged(String val) => setState(() => phoneError = _validatePhone(val));
  void _onEmailChanged(String val) => setState(() => emailError = _validateEmail(val));
  void _onUniversityChanged(String val) => setState(() => universityError = _validateUniversity(val));
  void _onHomeAddressChanged(String val) => setState(() => homeAddressError = _validateHomeAddress(val));

  // -------------------- SUBMIT FORM --------------------
  void _submitForm() async {
    setState(() {
      fullNameError = _validateFullName(fullNameController.text);
      phoneError = _validatePhone(phoneNumberController.text);
      emailError = _validateEmail(personalEmailController.text);
      universityError = _validateUniversity(collegeNameController.text);
      homeAddressError = _validateHomeAddress(homeAddressController.text);
      dateError = _validateDates();
    });

    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors before submitting'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => loading = true);

    final payload = {
      "email": personalEmailController.text,
      "fullName": fullNameController.text,
      "phoneNumber": phoneNumberController.text,
      "homeAddress": homeAddressController.text,
      "university": collegeNameController.text,
      if (selectedUniversityId != null) "universityId": selectedUniversityId,
      "enrollmentYear": int.parse(enrollmentYear!),
      "enrollmentMonth": enrollmentMonth,
      "graduationYear": int.parse(graduationYear!),
      "graduationMonth": graduationMonth,
      "referralCode": "",
      "userType": "student"
    };

    final uri = Uri.parse('https://api.junctionverse.com/user/register-non-edu');

    try {
      final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          SlidePageRoute(page: OtpVerificationNonEduPage(email: personalEmailController.text)),
        );
      } else {
        ErrorHandler.showErrorSnackBar(context, null, response: response);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // -------------------- BUILD --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: true,
        logoAssets: ['assets/logo-a.png','assets/logo-b.png','assets/logo-c.png','assets/logo-d.png'],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              child: Form(
                key: _formKey,
                onChanged: () => setState(() {}),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF262626))),
                    const SizedBox(height: 4),
                    const Text('We just need a few details to keep Junction safe and personalized for you. Your info is always secure with us!', style: TextStyle(fontSize: 12, color: Color(0xFF323537))),
                    const SizedBox(height: 32),
                    const Text('Personal Details', style: TextStyle(fontSize: 14, color: Color(0xFF212121))),
                    const SizedBox(height: 16),
                    _buildTextField('Full Name *', fullNameController, _onFullNameChanged, fullNameError, maxFullNameLength),
                    const SizedBox(height: 16),
                    _buildTextField('Phone Number *', phoneNumberController, _onPhoneChanged, phoneError, null, TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField('Personal Email ID *', personalEmailController, _onEmailChanged, emailError, null, TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildTextField('Address *', homeAddressController, _onHomeAddressChanged, homeAddressError, maxHomeAddressLength, TextInputType.text),
                    const SizedBox(height: 20),
                       const SizedBox(height: 8),
Container(
  height: 1,
  color: Color(0xFFE0E0E0), // light gray border line
),
const SizedBox(height: 16),
                    const Text('University Details', style: TextStyle(fontSize: 14, color: Color(0xFF212121))),
                const SizedBox(height: 16),
                    UniversityAutocomplete(
                      label: 'College Name',
                      placeholder: 'Enter or select your college',
                      controller: collegeNameController,
                      onChanged: _onUniversityChanged,
                      onUniversitySelected: (universityId, universityName) {
                        setState(() {
                          selectedUniversityId = universityId; // Will be null if user manually edited
                          universityError = null;
                        });
                      },
                      errorText: universityError,
                      maxLength: maxUniversityNameLength,
                    ),
                    const SizedBox(height: 16),
                   _buildDualDropdown(
  label: 'Enrollment',
  monthValue: enrollmentMonth,
  yearValue: enrollmentYear,
  onMonthChanged: (val) => setState(() {
    enrollmentMonth = val;
    _onDateChanged();
  }),
  onYearChanged: (val) => setState(() {
    enrollmentYear = val;
    _onDateChanged();
  }),
  isEnrollment: true,
),

const SizedBox(height: 16),

_buildDualDropdown(
  label: 'Graduation',
  monthValue: graduationMonth,
  yearValue: graduationYear,
  onMonthChanged: (val) => setState(() {
    graduationMonth = val;
    _onDateChanged();
  }),
  onYearChanged: (val) => setState(() {
    graduationYear = val;
    _onDateChanged();
  }),
  isEnrollment: false,
),

                    if (dateError != null) Padding(padding: const EdgeInsets.only(top: 8, left: 12), child: Text(dateError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: const PrivacyPolicyLink(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppButton(
              bottomSpacing: kSignupFlowButtonBottomSpacing,
              label: loading ? 'Saving...' : 'Save',
              onPressed: (loading || !isFormValid) ? null : _submitForm,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- HELPERS --------------------
  Widget _buildTextField(String label, TextEditingController controller, ValueChanged<String> onChanged, String? errorText, int? maxLength,
      [TextInputType keyboardType = TextInputType.text, int maxLines = 1]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(label: label,placeholder: label, controller: controller, onChanged: onChanged, keyboardType: keyboardType),
        if (errorText != null)
          Padding(padding: const EdgeInsets.only(top: 4, left: 12), child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 12))),
        if (maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 12),
            child: Text('${controller.text.length}/$maxLength', style: TextStyle(fontSize: 11, color: controller.text.length > maxLength ? Colors.red : Colors.grey[600])),
          ),
      ],
    );
  }
Widget _buildDualDropdown({
  required String label,
  required String? monthValue,
  required String? yearValue,
  required ValueChanged<String?> onMonthChanged,
  required ValueChanged<String?> onYearChanged,
  required bool isEnrollment,
}) {
  const borderColor = Color(0xFF212121);
  final yearsList = isEnrollment ? enrollmentYears : graduationYears;

  return Row(
    children: [
      // Left dropdown (Month) with inline label
      Expanded(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DropdownButtonFormField<String>(
              value: monthValue,
              decoration: _dropdownDecoration('', borderColor),
              items: months
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: onMonthChanged,
            ),
            Positioned(
              left: 12,
              top: -8,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '* $label',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(width: 16),

      // Right dropdown (Year)
      Expanded(
        child: DropdownButtonFormField<String>(
          value: yearValue,
          decoration: _dropdownDecoration('', borderColor),
          items: yearsList
              .map((y) => DropdownMenuItem(value: y, child: Text(y)))
              .toList(),
          onChanged: onYearChanged,
        ),
      ),
    ],
  );
}

InputDecoration _dropdownDecoration(String hint, Color borderColor) {
  return InputDecoration(
    hintText: hint.isNotEmpty ? hint : null,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1),
      borderRadius: BorderRadius.circular(6),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1),
      borderRadius: BorderRadius.circular(6),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}
}
