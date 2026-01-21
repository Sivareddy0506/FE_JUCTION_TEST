import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/ui_spacing.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_button_layout.dart';
import '../../widgets/form_text.dart';
import '../../widgets/university_autocomplete.dart';
import '../../widgets/headding_description.dart';
import '../../app.dart';
import 'eula_acceptance_page.dart';

class EduDetailsPage extends StatefulWidget {
  final String email;
  final String otp;

  const EduDetailsPage({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<EduDetailsPage> createState() => _EduDetailsPageState();
}

class _EduDetailsPageState extends State<EduDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  static const int maxFullNameLength = 50;
  static const int maxUniversityNameLength = 100;
  static const int maxCityLength = 100;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController collegeNameController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();

  String? fullNameError;
  String? phoneError;
  String? universityError;
  String? referralCodeError;

  String? selectedUniversityId;
  bool isLoadingReferralCode = false;
  bool loading = false;

  bool get isFormValid {
    final isNameValid = _validateFullName(fullNameController.text) == null;
    final isPhoneValid = _validatePhone(phoneNumberController.text) == null;
    final isUniversityValid = _validateUniversity(collegeNameController.text) == null;
    
    return fullNameController.text.isNotEmpty &&
        phoneNumberController.text.isNotEmpty &&
        cityController.text.isNotEmpty &&
        collegeNameController.text.isNotEmpty &&
        isNameValid &&
        isPhoneValid &&
        isUniversityValid;
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

  void _onUniversityChanged(String value) {
    setState(() {
      universityError = _validateUniversity(value);
    });
  }

  Future<void> _validateReferralCode(String code) async {
    if (code.isEmpty) {
      setState(() {
        referralCodeError = null;
      });
      return;
    }

    setState(() {
      isLoadingReferralCode = true;
      referralCodeError = null;
    });

    try {
      final uri = Uri.parse('https://api.junctionverse.com/user/validate-referral-code');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'referralCode': code}),
      );

      if (!mounted) return;

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['valid'] == true) {
        setState(() {
          referralCodeError = null;
        });
      } else {
        setState(() {
          referralCodeError = responseBody['error'] ?? 'Invalid referral code';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          referralCodeError = 'Failed to validate referral code. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingReferralCode = false;
        });
      }
    }
  }

  void _submitForm() async {
    final nameValidation = _validateFullName(fullNameController.text);
    final phoneValidation = _validatePhone(phoneNumberController.text);
    final universityValidation = _validateUniversity(collegeNameController.text);
    
    if (nameValidation != null || phoneValidation != null || universityValidation != null) {
      setState(() {
        fullNameError = nameValidation;
        phoneError = phoneValidation;
        universityError = universityValidation;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate referral code if provided
    final referralCode = referralCodeController.text.trim();
    if (referralCode.isNotEmpty && referralCodeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid referral code or remove it'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (!isFormValid) return;

    setState(() => loading = true);

    final payload = {
      "email": widget.email,
      "otp": widget.otp,
      "fullName": fullNameController.text.trim(),
      "phoneNumber": phoneNumberController.text.trim(),
      "city": cityController.text.trim(),
      "university": collegeNameController.text.trim(),
      if (selectedUniversityId != null) "universityId": selectedUniversityId,
      "referralCode": referralCode,
    };

    final uri = Uri.parse('https://api.junctionverse.com/user/complete-edu-onboarding');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        
        // Save userId if returned in response
        try {
          final prefs = await SharedPreferences.getInstance();
          if (responseBody['user'] != null && responseBody['user']['id'] != null) {
            await prefs.setString('userId', responseBody['user']['id']);
            debugPrint('📱 [Signup] User ID saved: ${responseBody['user']['id']}');
          }
        } catch (e) {
          debugPrint('📱 [Signup] ⚠️ Failed to save userId: $e');
        }
        
        Navigator.pushReplacement(
          context,
          FadePageRoute(
            page: EULAAcceptancePage(
              email: widget.email,
              otp: widget.otp,
              isSignupFlow: true,
              isEduFlow: true,
            ),
          ),
        );
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? 'Failed to submit';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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
                    const HeadingWithDescription(
                      heading: 'Personal Information',
                      description: "You're almost there! Fill in your details to personalize your experience.",
                    ),
                    const SizedBox(height: 32),
                    
                    // Full Name field
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
                    
                    // Phone Number field
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
                    
                    // City field (replaces address, no validations)
                    AppTextField(
                      label: 'City *',
                      placeholder: 'Eg: Mumbai',
                      controller: cityController,
                    ),
                    const SizedBox(height: 16),
                    
                    // University Name field
                    UniversityAutocomplete(
                      label: 'College/University *',
                      placeholder: 'Enter or select your college/university',
                      controller: collegeNameController,
                      onChanged: _onUniversityChanged,
                      onUniversitySelected: (universityId, universityName) {
                        setState(() {
                          selectedUniversityId = universityId;
                          universityError = null;
                        });
                      },
                      errorText: universityError,
                      maxLength: maxUniversityNameLength,
                    ),
                    const SizedBox(height: 16),
                    
                    // Referral Code field (optional)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Referral Code (Optional)',
                          placeholder: 'Enter referral code',
                          controller: referralCodeController,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _validateReferralCode(value);
                            } else {
                              setState(() {
                                referralCodeError = null;
                              });
                            }
                          },
                        ),
                        if (isLoadingReferralCode)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Validating...',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        if (referralCodeError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Text(
                              referralCodeError!,
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
          BottomButtonLayout(
            horizontalPadding: 24,
            topPadding: 24,
            button: AppButton(
              bottomSpacing: kSignupFlowButtonBottomSpacing,
              label: loading ? 'Saving...' : 'Save',
              onPressed: (loading || !isFormValid) ? null : _submitForm,
            ),
          ),
        ],
      ),
    );
  }
}
