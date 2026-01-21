import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/ui_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_button_layout.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/headding_description.dart';
import '../profile/user_profile.dart';
import '../signup/verification_submitted.dart';
import '../signup/verification_rejected.dart';
import '../signup/eula_acceptance_page.dart';
import '../../app.dart'; // For SlidePageRoute
import '../services/chat_service.dart';
import '../products/product_detail.dart';
import '../../app_state.dart';
import '../products/home.dart';
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

      debugPrint('Verifying OTP for email: ${widget.email}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('OTP verification timed out');
        },
      );
      
      debugPrint('OTP verification response status: ${response.statusCode}');

      if (!mounted) return;

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = responseBody['token'];
        final user = responseBody['user'];
        final userId = user?['id'] ?? '';

        if (user == null) {
          if (!mounted) return;
          setState(() => isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unexpected response. Please try again.")),
          );
          return;
        }

        final bool isOnboarded = user['isOnboarded'] ?? false;
        final bool isVerified = user['isVerified'] ?? false;
        final String userStatus = user['userStatus'] ?? '';
        final String fullName = user['fullName'] ?? 'User';
        final bool eulaAccepted = user['eulaAccepted'] ?? false;

        // Save token and user info
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', token);
          await prefs.setString('userId', userId);
          await prefs.setString('fullName', fullName);
          // Save user status to SharedPreferences for cold start restoration
          await prefs.setBool('isVerified', isVerified);
          await prefs.setBool('isOnboarded', isOnboarded);
          // Save isOnboarded to AppState
          AppState.instance.setIsOnboarded(isOnboarded);
        }
        // Verified but not onboarded users get partial access
        if (isVerified) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLogin', true);

          // Only set up Firebase for onboarded users (chat requires onboarding)
          if (isOnboarded) {
            debugPrint('Creating Firebase custom token for userId: $userId');
            final customTokenResponse = await http.post(
              Uri.parse('https://api.junctionverse.com/user/firebase/createcustomtoken'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'userId': userId}),
            ).timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Firebase token creation timed out');
              },
            );

            debugPrint('Custom token response status: ${customTokenResponse.statusCode}');
            
            if (customTokenResponse.statusCode == 200) {
            final customToken = jsonDecode(customTokenResponse.body)['token'];
            await FirebaseAuth.instance.signInWithCustomToken(customToken);
            await prefs.setString('firebaseUserId', FirebaseAuth.instance.currentUser?.uid ?? '');
            await prefs.setString('firebaseToken', customToken);
            
            // Initialize ChatService userId cache
            await ChatService.initializeUserId();

            // Register FCM token after successful login
            try {
              debugPrint('📱 [FCM] Getting FCM token after login...');
              final fcmToken = await FirebaseMessaging.instance.getToken();
              if (fcmToken != null) {
                debugPrint('📱 [FCM] FCM token retrieved: ${fcmToken.substring(0, 20)}...');
                
                // Register with backend
                try {
                  final fcmResponse = await http.post(
                    Uri.parse('https://api.junctionverse.com/user/fcm-token'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({'token': fcmToken}),
                  ).timeout(const Duration(seconds: 10));
                  
                  debugPrint('📱 [FCM] Backend registration status: ${fcmResponse.statusCode}');
                } catch (e) {
                  debugPrint('📱 [FCM] ⚠️ Failed to register FCM token with backend: $e');
                  // Don't block login if FCM registration fails
                }
                
                // Replace all old FCM tokens with current token in Firestore
                // This ensures only 1 active token per device, preventing duplicate notifications
                try {
                  final firebaseUser = FirebaseAuth.instance.currentUser;
                  if (firebaseUser != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .set({
                      'fcmTokens': [fcmToken], // Replace entire array with single current token
                    }, SetOptions(merge: true));
                    debugPrint('📱 [FCM] ✅ FCM token replaced in Firestore after login (removed old tokens)');
                  } else {
                    debugPrint('📱 [FCM] ⚠️ Firebase Auth not signed in, skipping Firestore save');
                  }
                } catch (e) {
                  debugPrint('📱 [FCM] ⚠️ Failed to save FCM token to Firestore: $e');
                  // Don't block login if Firestore save fails
                }
              } else {
                debugPrint('📱 [FCM] ⚠️ FCM token is null');
              }
            } catch (e) {
              debugPrint('📱 [FCM] ⚠️ Error getting FCM token after login: $e');
              // Don't block login if FCM token retrieval fails
            }

            // Check for pending deep link
            final pendingProductId = prefs.getString('pendingProductDeepLink');
            
            // Check if user has accepted EULA
            if (!eulaAccepted) {
              // Show EULA screen before entering app
              Navigator.pushAndRemoveUntil(
                context,
                SlidePageRoute(
                  page: const EULAAcceptancePage(isSignupFlow: false),
                ),
                (Route<dynamic> route) => false,
              );
            } else {
              // EULA already accepted, proceed to app
              // Always redirect to HomePage (for both onboarded and non-onboarded verified users)
              if (pendingProductId != null && pendingProductId.isNotEmpty) {
                // Clear pending deep link
                await prefs.remove('pendingProductDeepLink');
                
                // Navigate to home page first
                Navigator.pushAndRemoveUntil(
                  context,
                  SlidePageRoute(page: const HomePage()),
                  (Route<dynamic> route) => false,
                );
                
                // Navigate to product after a short delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.push(
                      context,
                      SlidePageRoute(
                        page: ProductDetailPage(productId: pendingProductId),
                      ),
                    );
                  }
                });
              } else {
                // No pending deep link, go to home page
                Navigator.pushAndRemoveUntil(
                  context,
                  SlidePageRoute(page: const HomePage()),
                  (Route<dynamic> route) => false,
                );
              }
            }
          } else {
            final errorBody = customTokenResponse.body;
            debugPrint('Firebase custom token creation failed: ${customTokenResponse.statusCode}');
            debugPrint('Error response: $errorBody');
            
            if (!mounted) return;
            setState(() => isSubmitting = false);
            
            String errorMsg = 'Failed to login. Please try again.';
            try {
              final errorData = jsonDecode(errorBody);
              errorMsg = errorData['message'] ?? errorMsg;
            } catch (_) {
              // If parsing fails, use default message
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg)),
            );
          }
          } else {
            // Verified but not onboarded - skip Firebase setup, go directly to home
            final prefs = await SharedPreferences.getInstance();
            final pendingProductId = prefs.getString('pendingProductDeepLink');
            
            // Check if user has accepted EULA
            if (!eulaAccepted) {
              Navigator.pushAndRemoveUntil(
                context,
                SlidePageRoute(
                  page: const EULAAcceptancePage(isSignupFlow: false),
                ),
                (Route<dynamic> route) => false,
              );
            } else {
              if (pendingProductId != null && pendingProductId.isNotEmpty) {
                await prefs.remove('pendingProductDeepLink');
                Navigator.pushAndRemoveUntil(
                  context,
                  SlidePageRoute(page: const HomePage()),
                  (Route<dynamic> route) => false,
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.push(
                      context,
                      SlidePageRoute(
                        page: ProductDetailPage(productId: pendingProductId),
                      ),
                    );
                  }
                });
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  SlidePageRoute(page: const HomePage()),
                  (Route<dynamic> route) => false,
                );
              }
            }
          }
        } else {
          // User is not verified - show verification screens
          if (userStatus == 'Pending' || userStatus == 'Submitted') {
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
            // Unknown status - default to verification submitted page
            Navigator.pushReplacement(
              context,
              SlidePageRoute(page: const VerificationSubmittedPage()),
            );
          }
        }
        // On success, don't reset isSubmitting - let navigation happen while button is in loading state
        // This provides better UX feedback
      } else {
        // OTP verification failed - reset loading state
        if (!mounted) return;
        _clearOTPFields();
        setState(() {
          isSubmitting = false;
          hasError = true;
          errorMessage = 'Incorrect OTP. Please double check';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSubmitting = false;
        hasError = true;
      });
      
      // Provide more specific error messages
      String errorMsg = 'Network error. Please try again.';
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        errorMsg = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('TimeoutException') || 
                 e.toString().contains('timeout')) {
        errorMsg = 'Request timed out. Please try again.';
      } else if (e.toString().contains('FormatException')) {
        errorMsg = 'Invalid response from server. Please try again.';
      }
      
      debugPrint('Login error: $e');
      setState(() {
        errorMessage = errorMsg;
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

            BottomButtonLayout(
              button: AppButton(
                bottomSpacing: kSignupFlowButtonBottomSpacing, // Button handles spacing when useContainer=false
                label: isSubmitting ? 'Verifying...' : 'Verify',
                onPressed: (!_isOTPComplete || isSubmitting) ? null : _verifyOTP,
                backgroundColor: (!_isOTPComplete || isSubmitting)
                    ? const Color(0xFF8C8C8C)
                    : const Color(0xFFFF6705),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
