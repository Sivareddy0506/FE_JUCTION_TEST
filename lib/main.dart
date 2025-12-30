import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'navigation_service.dart';
import 'screens/Chat/chat_page.dart';
import 'services/deep_link_service.dart';
import 'screens/products/product_detail.dart';
import 'screens/services/api_service.dart';
import 'app.dart'; // For SlidePageRoute

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Check if Firebase is already initialized (background handler runs in separate isolate)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  
  const AndroidInitializationSettings initializationSettingsAndroid = 
      AndroidInitializationSettings('@drawable/logo');
  const DarwinInitializationSettings initializationSettingsIOS = 
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat',
    'Chat Notifications',
    description: 'Notifications for new chat messages',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );
  
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  
  RemoteNotification? notification = message.notification;
  
  if (notification != null) {
    try {
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat',
            'Chat Notifications',
            channelDescription: 'Notifications for new chat messages',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            // Removed largeIcon for cleaner notification appearance
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    } catch (e) {
      debugPrint('Error displaying background notification: $e');
    }
  } else if (message.data.isNotEmpty) {
    try {
      final title = message.data['title'] ?? 'New Message';
      final body = message.data['body'] ?? message.data['message'] ?? 'You have a new message';
      
      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat',
            'Chat Notifications',
            channelDescription: 'Notifications for new chat messages',
            importance: Importance.high,
            priority: Priority.high,
            largeIcon: DrawableResourceAndroidBitmap('@drawable/logo'),
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    } catch (e) {
      debugPrint('Error displaying background notification from data: $e');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if Firebase is already initialized to avoid duplicate initialization
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // If initialization fails, try to get the default app
    try {
      Firebase.app();
    } catch (_) {
      // If that also fails, rethrow the original error
      rethrow;
    }
  }

  // Background notification handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notifications initialization
  const AndroidInitializationSettings initializationSettingsAndroid = 
      AndroidInitializationSettings('@drawable/ic_notification');
  const DarwinInitializationSettings initializationSettingsIOS = 
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  void navigateToChat(String? chatId) {
    if (chatId == null || chatId.isEmpty) return;
    
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator != null) {
      navigator.push(
        SlidePageRoute(
          page: ChatPage(chatId: chatId),
        ),
      );
    }
  }
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        try {
          final payload = response.payload!;
          if (payload.contains('chatId')) {
            final chatIdMatch = RegExp(r'chatId[:\s]+([^\s,}]+)').firstMatch(payload);
            if (chatIdMatch != null) {
              navigateToChat(chatIdMatch.group(1));
            }
          }
        } catch (e) {
          debugPrint('Error parsing notification payload: $e');
        }
      }
    },
  );
  
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat',
    'Chat Notifications',
    description: 'Notifications for new chat messages',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );
  
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  // Get FCM token with retry logic (iOS needs APNS token first)
  _getFCMTokenWithRetry();

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    // Only register token if user is logged in
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    if (authToken == null || authToken.isEmpty) {
      debugPrint('📱 [FCM] Ignoring token refresh - user not logged in');
      return;
    }

    await _sendFCMTokenToBackend(newToken);
    
    final userId = prefs.getString('userId');
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (userId != null && firebaseUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving token to Firestore: $e');
      }
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // Check if user is logged in before processing notification
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    if (authToken == null || authToken.isEmpty) {
      debugPrint('📱 [FCM] Ignoring notification - user not logged in');
      return;
    }

    RemoteNotification? notification = message.notification;
    if (notification != null) {
      try {
        await flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'chat',
              'Chat Notifications',
              channelDescription: 'Notifications for new chat messages',
              importance: Importance.high,
              priority: Priority.high,
              showWhen: true,
              largeIcon: DrawableResourceAndroidBitmap('@drawable/logo'),
              icon: '@drawable/ic_notification',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      } catch (e) {
        debugPrint('Error displaying foreground notification: $e');
      }
    }
  });
  
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    // Check if user is logged in before processing notification
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    if (authToken == null || authToken.isEmpty) {
      debugPrint('📱 [FCM] Ignoring notification tap - user not logged in');
      return;
    }

    final chatId = message.data['chatId'];
    if (chatId != null) {
      navigateToChat(chatId);
    }
  });
  
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    // Check if user is logged in before processing initial message
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    if (authToken != null && authToken.isNotEmpty) {
      final chatId = initialMessage.data['chatId'];
      if (chatId != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          navigateToChat(chatId);
        });
      }
    } else {
      debugPrint('📱 [FCM] Ignoring initial message - user not logged in');
    }
  }

  // Optional: OS-level error logging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('FlutterError: ${details.exception}');
  };

  // Initialize deep link service
  final deepLinkService = DeepLinkService();
  deepLinkService.initialize();
  
  // Handle product deep links - SYNCHRONOUS callback (no async)
  deepLinkService.onProductLinkReceived = (productId) {
    _handleProductDeepLink(productId);
  };

  runApp(const MyApp());
  
  // After app is built, check for pending deep links
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkPendingDeepLink();
  });
}

// Static variable to store pending deep link synchronously (no async operations)
String? _pendingProductDeepLink;

// Handle product deep links
// CRITICAL: Navigation must be SYNCHRONOUS for iOS Universal Links
// iOS requires navigation to happen immediately (< 50ms) or it falls back to Safari
void _handleProductDeepLink(String productId) {
  try {
    debugPrint('🔗 Handling product deep link: $productId');
    
    // CRITICAL: Get navigator IMMEDIATELY (synchronous, no async operations)
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('🔗 ⚠️ Navigator not available - storing for later');
      // Store productId synchronously (no async SharedPreferences)
      _pendingProductDeepLink = productId;
      // Also store in SharedPreferences for persistence across app restarts (async, non-blocking)
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('pendingProductDeepLink', productId);
      });
      return;
    }
    
    // Validate productId format (synchronous, fast)
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    
    if (!uuidRegex.hasMatch(productId)) {
      debugPrint('🔗 ❌ Invalid product ID format: $productId');
      // Navigate to error screen to consume the Universal Link
      navigator.push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Invalid product link')),
          ),
        ),
      );
      return;
    }

    // NAVIGATE IMMEDIATELY - this must happen synchronously
    // Pass productId only, ProductDetailPage will fetch product data asynchronously
    navigator.push(
      SlidePageRoute(
        page: ProductDetailPage(productId: productId),
      ),
    );
    
    debugPrint('🔗 ✅ Navigated immediately to product: $productId');
    // ProductDetailPage will handle loading data asynchronously
  } catch (e) {
    debugPrint('🔗 ❌ Error handling product deep link: $e');
    // Always navigate even on error to consume the Universal Link
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Unable to open product. Please try again.')),
          ),
        ),
      );
    }
  }
}

// Check for pending deep link after app initializes
void _checkPendingDeepLink() {
  // First check synchronous storage
  if (_pendingProductDeepLink != null) {
    final productId = _pendingProductDeepLink;
    _pendingProductDeepLink = null; // Clear immediately
    debugPrint('🔗 Processing pending deep link from memory: $productId');
    _handleProductDeepLink(productId!);
    return;
  }
  
  // Also check SharedPreferences (async, but navigator should be ready now)
  SharedPreferences.getInstance().then((prefs) {
    final pendingProductId = prefs.getString('pendingProductDeepLink');
    if (pendingProductId != null && pendingProductId.isNotEmpty) {
      debugPrint('🔗 Processing pending deep link from storage: $pendingProductId');
      prefs.remove('pendingProductDeepLink'); // Clear
      _handleProductDeepLink(pendingProductId);
    }
  });
}

void _showDeepLinkError(String message) {
  // Show error after a delay to ensure app is ready
  Future.delayed(const Duration(milliseconds: 1000), () {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator != null && navigator.context.mounted) {
      ScaffoldMessenger.of(navigator.context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  });
}

void _showDeepLinkErrorWithNavigation(String message) {
  // CRITICAL: Always navigate to ensure Universal Link is "consumed"
  // iOS requires navigation to happen, otherwise it falls back to Safari
  Future.delayed(const Duration(milliseconds: 500), () {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator != null) {
      // Pop to root first to ensure we're on a valid screen
      navigator.popUntil((route) => route.isFirst);
      
      // Show error message
      if (navigator.context.mounted) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      debugPrint('🔗 ✅ Universal Link consumed - navigated to root screen');
    } else {
      debugPrint('🔗 ⚠️ Navigator not available for error navigation');
    }
  });
}

// Helper function to get FCM token with retry (handles iOS APNS token delay)
Future<void> _getFCMTokenWithRetry({int retryCount = 0}) async {
  try {
    // Wait a bit for APNS token to be set (iOS only, harmless on Android)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      _sendFCMTokenToBackend(token);
    }
  } catch (e) {
    debugPrint('Error getting FCM token (attempt ${retryCount + 1}): $e');
    // Retry up to 2 more times
    if (retryCount < 2) {
      Future.delayed(const Duration(seconds: 3), () {
        _getFCMTokenWithRetry(retryCount: retryCount + 1);
      });
    }
  }
}

Future<void> _sendFCMTokenToBackend(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    
    if (authToken == null || authToken.isEmpty) {
      return;
    }

    final response = await http.post(
      Uri.parse('https://api.junctionverse.com/user/fcm-token'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      final userId = prefs.getString('userId');
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (userId != null && firebaseUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set({
            'fcmTokens': FieldValue.arrayUnion([token]),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error saving token to Firestore: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('Error sending FCM token to backend: $e');
  }
}

/// Delete FCM token from backend and Firestore on logout
Future<void> _deleteFCMToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    
    if (authToken == null || authToken.isEmpty) {
      debugPrint('📱 [FCM] No auth token, skipping FCM token deletion');
      return;
    }

    // Get current FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      debugPrint('📱 [FCM] No FCM token to delete');
      return;
    }

    // Delete from backend (we'll need to create this endpoint)
    try {
      final response = await http.delete(
        Uri.parse('https://api.junctionverse.com/user/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200 || response.statusCode == 404) {
        debugPrint('📱 [FCM] ✅ FCM token deleted from backend');
      } else {
        debugPrint('📱 [FCM] ⚠️ Failed to delete FCM token from backend: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('📱 [FCM] ⚠️ Error deleting FCM token from backend: $e');
      // Continue even if backend deletion fails
    }

    // Delete from Firestore
    final userId = prefs.getString('userId');
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (userId != null && firebaseUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
        debugPrint('📱 [FCM] ✅ FCM token removed from Firestore');
      } catch (e) {
        debugPrint('📱 [FCM] ⚠️ Error removing token from Firestore: $e');
      }
    }

    // Delete the token from Firebase Messaging (optional, but good practice)
    try {
      await FirebaseMessaging.instance.deleteToken();
      debugPrint('📱 [FCM] ✅ FCM token deleted from Firebase');
    } catch (e) {
      debugPrint('📱 [FCM] ⚠️ Error deleting token from Firebase: $e');
    }
  } catch (e) {
    debugPrint('📱 [FCM] ⚠️ Error in FCM token deletion: $e');
  }
}
