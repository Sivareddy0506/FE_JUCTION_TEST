import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/Notifications/notifications_screen.dart';
import '../../screens/Chat/chats_list_page.dart';
import '../app.dart'; // For SlidePageRoute
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../utils/feature_lock.dart';

class LogoAndIconsWidget extends StatefulWidget {
  const LogoAndIconsWidget({super.key});

  @override
  State<LogoAndIconsWidget> createState() => _LogoAndIconsWidgetState();
}

class _LogoAndIconsWidgetState extends State<LogoAndIconsWidget> {
  bool hasNotifications = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> logoAssets = const [
    'assets/logo-a.png',
    'assets/logo-b.png',
    'assets/logo-c.png',
    'assets/logo-d.png',
  ];

  @override
  void initState() {
    super.initState();
    _checkNotifications();
  }
  
  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<void> _checkNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return;

      final uri = Uri.parse('https://api.junctionverse.com/api/notifications/user/received');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final notifications = data['notifications'] as List?;
        if (mounted) {
          setState(() {
            hasNotifications = notifications != null && notifications.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint('LogoAndIconsWidget: Error checking notifications: $e');
    }
  }
  
  // Stream to check for unread messages across all chats in real-time
  Stream<bool> _getHasNewChatsStream() {
    if (currentUserId.isEmpty) {
      return Stream.value(false);
    }
    
    // Create a stream controller to combine multiple streams
    final controller = StreamController<bool>.broadcast();
    StreamSubscription? chatsSubscription;
    Timer? periodicTimer;
    
    // Function to check for unread messages
    Future<void> checkUnreadMessages() async {
      try {
        // Get all chats where user is a participant
        final chatsSnapshot = await _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .get();
        
        if (chatsSnapshot.docs.isEmpty) {
          if (!controller.isClosed) {
            controller.add(false);
          }
          return;
        }
        
        // Check each chat for unread messages
        for (var chatDoc in chatsSnapshot.docs) {
          final chatId = chatDoc.id;
          
          try {
            // Check for unread messages where receiverId is current user
            final unreadMessagesSnapshot = await _firestore
                .collection('messages')
                .doc(chatId)
                .collection('messages')
                .where('receiverId', isEqualTo: currentUserId)
                .where('isRead', isEqualTo: false)
                .limit(1)
                .get();
            
            if (unreadMessagesSnapshot.docs.isNotEmpty) {
              if (!controller.isClosed) {
                controller.add(true); // Found at least one unread message
              }
              return;
            }
          } catch (e) {
            debugPrint('Error checking unread messages for chat $chatId: $e');
            // Continue checking other chats even if one fails
          }
        }
        
        if (!controller.isClosed) {
          controller.add(false); // No unread messages found
        }
      } catch (e) {
        debugPrint('Error in checkUnreadMessages: $e');
        if (!controller.isClosed) {
          controller.add(false);
        }
      }
    }
    
    // Listen to chat changes
    chatsSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((_) {
          checkUnreadMessages();
        });
    
    // Also create a periodic check to catch message read updates
    // This ensures we detect when messages are marked as read (which doesn't change chat docs)
    periodicTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      checkUnreadMessages();
    });
    
    // Initial check
    checkUnreadMessages();
    
    // Clean up when stream is closed
    controller.onCancel = () {
      chatsSubscription?.cancel();
      periodicTimer?.cancel();
    };
    
    return controller.stream.distinct(); // Only emit when value changes
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 🔧 Responsive sizes
    final logoSize = (screenWidth * 0.06).clamp(22.0, 36.0); // Reduced from 0.07 to 0.06 to make logo narrower
    final iconContainerSize = (screenWidth * 0.1).clamp(36.0, 48.0);

    return Row(
      children: [
        // Add 16px left padding to align logo with search bar content
        const SizedBox(width: 16),
        // Logos
        ...logoAssets.map(
          (asset) => Padding(
            padding: const EdgeInsets.only(right: 10), // Reduced spacing from 12 to 10
            child: Image.asset(
              asset,
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),

        const Spacer(),

        // Notification Icon
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              SlidePageRoute(page: const NotificationPage()),
            ).then((_) => _checkNotifications());
          },
          child: Image.asset(
            hasNotifications
                ? 'assets/Notification.png'
                : 'assets/Nonotification.png',
            width: iconContainerSize,
            height: iconContainerSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),

        // ✅ Add 8px space
        const SizedBox(width: 8),

        // Chat Icon with real-time unread message detection
        StreamBuilder<bool>(
          stream: _getHasNewChatsStream(),
          initialData: false,
          builder: (context, snapshot) {
            final hasNewChats = snapshot.data ?? false;
            return GestureDetector(
              onTap: () {
                if (lockIfNotOnboarded(context)) return;
                Navigator.push(
                  context,
                  SlidePageRoute(page: ChatListPage()),
                );
              },
              child: Image.asset(
                hasNewChats
                    ? 'assets/chats.png'
                    : 'assets/Chat.png',
                width: iconContainerSize,
                height: iconContainerSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            );
          },
        ),
      ],
    );
  }
}
