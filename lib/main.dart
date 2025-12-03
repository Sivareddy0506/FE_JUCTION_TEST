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
            largeIcon: DrawableResourceAndroidBitmap('@drawable/logo'),
            icon: '@mipmap/ic_launcher',
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
            icon: '@mipmap/ic_launcher',
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
    await _sendFCMTokenToBackend(newToken);
    
    final prefs = await SharedPreferences.getInstance();
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
              icon: '@mipmap/ic_launcher',
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
  
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final chatId = message.data['chatId'];
    if (chatId != null) {
      navigateToChat(chatId);
    }
  });
  
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final chatId = initialMessage.data['chatId'];
    if (chatId != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        navigateToChat(chatId);
      });
    }
  }

  // Optional: OS-level error logging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('FlutterError: ${details.exception}');
  };

  runApp(const MyApp());
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
