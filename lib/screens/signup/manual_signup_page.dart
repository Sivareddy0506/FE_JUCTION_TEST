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

  bool loading = false;

  final List<String> months =
      List.generate(12, (index) => DateFormat('MMMM').format(DateTime(0, index + 1)));
  final List<String> years = List.generate(21, (index) => (DateTime.now().year - index).toString());

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

  String? _validateFullName(String value) {
    if (value.isEmpty) return null;

    if (value.length > maxFullNameLength) {
      return 'Name cannot exceed $maxFullNameLength characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name should contain only letters';
    }
    
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    
    final nameParts = value.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (nameParts.length < 2) {
      return 'Please enter your full name (first and last name)';
    }
    
    return null;
  }

  String? _validatePhone(String value) {
    if (value.isEmpty) return null;
    
    if (RegExp(r'[^\d+\s]').hasMatch(value)) {
      return 'Phone number can only contain digits';
    }
    
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    
    final RegExp indianMobilePattern = RegExp(r'^(?:\+91|91)?[6-9]\d{9}$');
    
    if (!indianMobilePattern.hasMatch(cleaned)) {
      final digitsOnly = cleaned.replaceAll(RegExp(r'[^\d]'), '');
      
      if (digitsOnly.isEmpty) {
        return 'Please enter a phone number';
      } else if (digitsOnly.length < 10) {
        return 'Phone number must be 10 digits';
      } else if (digitsOnly.length > 10) {
        return 'Phone number should not exceed 10 digits';
      } else if (!RegExp(r'^[6-9]').hasMatch(digitsOnly)) {
        return 'Phone number must start with 6, 7, 8, or 9';
      } else {
        return 'Please enter a valid Indian mobile number';
      }
    }
    
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return null;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    if (value.length > 100) {
      return 'Email address is too long';
    }
    
    return null;
  }

  String? _validateUniversity(String value) {
    if (value.isEmpty) return null;
    
    if (value.length > maxUniversityNameLength) {
      return 'University name cannot exceed $maxUniversityNameLength characters';
    }

    if (value.trim().length < 3) {
      return 'University name must be at least 3 characters';
    }
    
    if (RegExp(r'^\d+$').hasMatch(value.trim())) {
      return 'Please enter a valid university name';
    }
    
    return null;
  }

  String? _validateHomeAddress(String value) {
    if (value.isEmpty) return null;
    
    if (value.length > maxHomeAddressLength) {
      return 'Address cannot exceed $maxHomeAddressLength characters';
    }
    
    if (value.trim().length < 10) {
      return 'Address must be at least 10 characters';
    }
    
    // Allow only letters, numbers, spaces, and common address punctuation
    if (!RegExp(r"^[a-zA-Z0-9\s,.\-/'#()]+$").hasMatch(value)) {
      return 'Address contains invalid characters';
    }
    
    // Check for excessive repetition of special characters
    if (RegExp(r"[,.\-/\'#()]{4,}").hasMatch(value)) {
      return 'Please enter a valid address format';
    }
    
    // Check for excessive repetition of any single character
    if (RegExp(r'(.)\1{4,}').hasMatch(value)) {
      return 'Please enter a valid address';
    }
    
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Address must contain letters';
    }
    
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Address must contain at least one number';
    }
    
    // Ensure there are actual words
    final words = RegExp(r'[a-zA-Z]{2,}').allMatches(value);
    if (words.length < 2) {
      return 'Please enter a complete address with street number and name';
    }
    
    return null;
  }

  String? _validateDates() {
    if (enrollmentMonth == null || enrollmentYear == null || 
        graduationMonth == null || graduationYear == null) {
      return null;
    }
    
    final enrollMonthIndex = months.indexOf(enrollmentMonth!) + 1;
    final gradMonthIndex = months.indexOf(graduationMonth!) + 1;
    
    final enrollYear = int.parse(enrollmentYear!);
    final gradYear = int.parse(graduationYear!);
    
    final enrollDate = DateTime(enrollYear, enrollMonthIndex, 1);
    final gradDate = DateTime(gradYear, gradMonthIndex, 1);
    
    if (gradDate.isBefore(enrollDate) || gradDate.isAtSameMomentAs(enrollDate)) {
      return 'Graduation date must be after enrollment date';
    }
    
    final monthsDifference = (gradYear - enrollYear) * 12 + (gradMonthIndex - enrollMonthIndex);
    if (monthsDifference < 12) {
      return 'Graduation must be at least 1 year after enrollment';
    }
    
    if (monthsDifference > 96) {
      return 'Course duration seems too long. Please verify dates';
    }
    
    return null;
  }

  void _onDateChanged() {
    setState(() {
      dateError = _validateDates();
    });
  }

  void _onHomeAddressChanged(String value) {
    setState(() {
      homeAddressError = _validateHomeAddress(value);
    });
  }

  void _onFullNameChanged(String value) {
    setState(() {
      fullNameError = _validateFullName(value);
    });
  }

  void _onPhoneChanged(String value) {
    setState(() {
      phoneError = _validatePhone(value);
    });
  }

  void _onEmailChanged(String value) {
    setState(() {
      emailError = _validateEmail(value);
    });
  }

  void _onUniversityChanged(String value) {
    setState(() {
      universityError = _validateUniversity(value);
    });
  }

  void _submitForm() async {
    final nameValidation = _validateFullName(fullNameController.text);
    final phoneValidation = _validatePhone(phoneNumberController.text);
    final emailValidation = _validateEmail(personalEmailController.text);
    final universityValidation = _validateUniversity(collegeNameController.text);
    final addressValidation = _validateHomeAddress(homeAddressController.text);
    final datesValidation = _validateDates();
    
    if (nameValidation != null || phoneValidation != null || emailValidation != null ||
        addressValidation != null || universityValidation != null || datesValidation != null) {
      setState(() {
        fullNameError = nameValidation;
        phoneError = phoneValidation;
        emailError = emailValidation;
        homeAddressError = addressValidation;
        universityError = universityValidation;
        dateError = datesValidation;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (!isFormValid) return;

    setState(() => loading = true);

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
                    const Text('Secure your spot',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF262626))),
                    const SizedBox(height: 4),
                    const Text('Get verified in minutes.', style: TextStyle(fontSize: 12, color: Color(0xFF323537))),
                    const SizedBox(height: 32),
                    const Text('Personal Details', style: TextStyle(fontSize: 14, color: Color(0xFF212121))),
                    const SizedBox(height: 16),
                    
                    // Full Name field with validation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Full Name *',
                          placeholder: 'Eg: Eric John',
                          controller: fullNameController,
                          onChanged: _onFullNameChanged,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (fullNameError != null)
                                Expanded(
                                  child: Text(
                                    fullNameError!,
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              Text(
                                '${fullNameController.text.length}/$maxFullNameLength',
                                style: TextStyle(
                                  color: fullNameController.text.length > maxFullNameLength
                                      ? Colors.red
                                      : Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Number field with validation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Phone Number *',
                          placeholder: 'Eg: 9999999999',
                          controller: phoneNumberController,
                          keyboardType: TextInputType.phone,
                          onChanged: _onPhoneChanged,
                        ),
                        if (phoneError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Text(
                              phoneError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Email field with validation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Personal Email ID *',
                          placeholder: 'ericjohn@example.com',
                          controller: personalEmailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: _onEmailChanged,
                        ),
                        if (emailError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Text(
                              emailError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Home Address field with validation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Home Address *',
                          placeholder: 'Eg: 123 Main Street, City Name',
                          controller: homeAddressController,
                          onChanged: _onHomeAddressChanged,
                          maxLines: 3,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (homeAddressError != null)
                                Expanded(
                                  child: Text(
                                    homeAddressError!,
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              Text(
                                '${homeAddressController.text.length}/$maxHomeAddressLength',
                                style: TextStyle(
                                  color: homeAddressController.text.length > maxHomeAddressLength
                                      ? Colors.red
                                      : Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('University Details', style: TextStyle(fontSize: 14, color: Color(0xFF212121))),
                    const SizedBox(height: 16),
                    
                    // College Name field with validation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'College Name *',
                          placeholder: 'Eg: Christ University',
                          controller: collegeNameController,
                          onChanged: _onUniversityChanged,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (universityError != null)
                                Expanded(
                                  child: Text(
                                    universityError!,
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              Text(
                                '${collegeNameController.text.length}/$maxUniversityNameLength',
                                style: TextStyle(
                                  color: collegeNameController.text.length > maxUniversityNameLength
                                      ? Colors.red
                                      : Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Enrollment date
                    _buildDualDropdown(
                      label: 'Enrollment',
                      monthValue: enrollmentMonth,
                      yearValue: enrollmentYear,
                      onMonthChanged: (val) {
                        setState(() {
                          enrollmentMonth = val;
                          _onDateChanged();
                        });
                      },
                      onYearChanged: (val) {
                        setState(() {
                          enrollmentYear = val;
                          _onDateChanged();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Graduation date with validation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDualDropdown(
                          label: 'Graduation',
                          monthValue: graduationMonth,
                          yearValue: graduationYear,
                          onMonthChanged: (val) {
                            setState(() {
                              graduationMonth = val;
                              _onDateChanged();
                            });
                          },
                          onYearChanged: (val) {
                            setState(() {
                              graduationYear = val;
                              _onDateChanged();
                            });
                          },
                        ),
                        if (dateError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              dateError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: AppButton(
              bottomSpacing: 0,
              label: loading ? 'Saving...' : 'Save',
              onPressed: (loading || !isFormValid) ? null : _submitForm,
            ),
          ),
        ],
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
        ),
      ],
    );
  }
}