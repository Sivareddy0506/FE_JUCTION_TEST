import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../login/login_page.dart';
import '../products/home.dart';
import '../services/chat_service.dart';
import '../../app.dart';
import '../../app_state.dart';

class WelcomePage extends StatefulWidget {
  final bool isFromSignup;
  
  const WelcomePage({
    super.key,
    this.isFromSignup = false,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return; // ✅ Guard against context use after disposal

      if (widget.isFromSignup) {
        // User just completed signup - they're already verified and onboarded
        // Perform full login setup (matching otp_verification_login.dart flow)
        await _performFullLoginSetup();
      } else {
        // Default behavior - navigate to login
        Navigator.pushReplacement(
          context,
          SlidePageRoute(page: const LoginPage()),
        );
      }
    });
  }

  /// Performs full login setup matching the login flow
  /// This ensures Firebase, Chat, and all features work correctly after signup
  Future<void> _performFullLoginSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final userId = prefs.getString('userId');

    // 1. Save verification status to SharedPreferences
    await prefs.setBool('isVerified', true);
    await prefs.setBool('isOnboarded', true);
    await prefs.setBool('isLogin', true); // ✅ Set login flag (was missing)

    // 2. Update AppState
    AppState.instance.setUserStatus(
      isVerified: true,
      isOnboarded: true,
    );

    // 3. Setup Firebase Authentication (required for chat)
    if (userId != null) {
      await _setupFirebaseAuth(prefs, userId);
    }

    // 4. Register FCM token (after Firebase is set up)
    if (token != null && userId != null) {
      await _registerFCMToken(token, userId);
    }

    if (!mounted) return;

    // 5. Navigate to home (clear navigation stack)
    Navigator.pushAndRemoveUntil(
      context,
      SlidePageRoute(page: HomePage()),
      (Route<dynamic> route) => false,
    );
  }

  /// Sets up Firebase Authentication with custom token
  /// This is required for chat functionality to work
  Future<void> _setupFirebaseAuth(SharedPreferences prefs, String userId) async {
    try {
      debugPrint('🔥 [Firebase] Creating custom token for userId: $userId');
      
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

      debugPrint('🔥 [Firebase] Custom token response status: ${customTokenResponse.statusCode}');

      if (customTokenResponse.statusCode == 200) {
        final customToken = jsonDecode(customTokenResponse.body)['token'];
        
        // Sign in to Firebase with custom token
        await FirebaseAuth.instance.signInWithCustomToken(customToken);
        debugPrint('🔥 [Firebase] ✅ Signed in with custom token');
        
        // Save Firebase credentials to SharedPreferences
        await prefs.setString('firebaseUserId', FirebaseAuth.instance.currentUser?.uid ?? '');
        await prefs.setString('firebaseToken', customToken);
        
        // Initialize ChatService userId cache (required for chat to work)
        await ChatService.initializeUserId();
        debugPrint('🔥 [Firebase] ✅ ChatService initialized');
      } else {
        debugPrint('🔥 [Firebase] ⚠️ Failed to create custom token: ${customTokenResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('🔥 [Firebase] ⚠️ Error setting up Firebase Auth: $e');
      // Don't block signup flow if Firebase setup fails
      // User can still browse, but chat won't work until they re-login
    }
  }

  /// Registers FCM token with backend and Firestore
  Future<void> _registerFCMToken(String token, String userId) async {
    try {
      debugPrint('📱 [FCM] Getting FCM token after signup...');
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
          // Don't block signup flow if FCM registration fails
        }
        
        // Save to Firestore (now works because Firebase is signed in)
        try {
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .set({
              'fcmTokens': [fcmToken],
            }, SetOptions(merge: true));
            debugPrint('📱 [FCM] ✅ FCM token saved to Firestore after signup');
          } else {
            debugPrint('📱 [FCM] ⚠️ Firebase Auth not signed in, skipping Firestore save');
          }
        } catch (e) {
          debugPrint('📱 [FCM] ⚠️ Failed to save FCM token to Firestore: $e');
        }
      } else {
        debugPrint('📱 [FCM] ⚠️ FCM token is null');
      }
    } catch (e) {
      debugPrint('📱 [FCM] ⚠️ Error getting FCM token after signup: $e');
      // Don't block signup flow
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/welcomeboard.png',
                width: 270,
                height: 173,
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome Aboard!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Everything looks great, let’s get browsing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
