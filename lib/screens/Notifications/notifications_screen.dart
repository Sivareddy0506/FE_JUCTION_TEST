
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../widgets/custom_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/app_button.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final String targetType;
  final List<String> targetIds;
  final String sentById;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.imageUrl,
    required this.targetType,
    required this.targetIds,
    required this.sentById,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      imageUrl: json['imageUrl'],
      targetType: json['targetType'],
      targetIds: List<String>.from(json['targetIds']),
      sentById: json['sentById'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'imageUrl': imageUrl,
        'targetType': targetType,
        'targetIds': targetIds,
        'sentById': sentById,
        'createdAt': createdAt.toIso8601String(),
      };
}


class NotificationGroup {
  final String title;
  final List<NotificationModel> notifications;

  NotificationGroup({
    required this.title,
    required this.notifications,
  });
}


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {

  bool isLoading = true;
  List<NotificationGroup> notificationGroups = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _getNotifications();
  }

  Future<void> _getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      print(token);
      if (token == null) return;

      setState(() {
        isLoading = true;
        errorMessage = null;
      }); 

      final uri = Uri.parse('https://api.junctionverse.com/api/notifications/user/received');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final notifications = (data['notifications'] as List)
             .map((json) => NotificationModel.fromJson(json))
             .toList();
        final groups = groupNotificationsByDate(notifications);
        setState(() {
          notificationGroups = groups;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load notifications';
      });
    }
  }


List<NotificationGroup> groupNotificationsByDate(List<NotificationModel> notifications) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(Duration(days: 1));

  // Sort notifications by date descending
  notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Map<String, List<NotificationModel>> groupedMap = {};

  for (var notification in notifications) {
    final createdDate = DateTime(notification.createdAt.year, notification.createdAt.month, notification.createdAt.day);

    String key;
    if (createdDate == today) {
      key = 'Today';
    } else if (createdDate == yesterday) {
      key = 'Yesterday';
    } else {
      key = DateFormat('E, d MMM').format(createdDate); // Example: Sun, 27 Jul
    }

    if (!groupedMap.containsKey(key)) {
      groupedMap[key] = [];
    }
    groupedMap[key]!.add(notification);
  }

  // Convert map to list
  List<NotificationGroup> groupedList = groupedMap.entries
      .map((entry) => NotificationGroup(title: entry.key, notifications: entry.value))
      .toList();

  // Optional: Sort groups by date (descending)
  groupedList.sort((a, b) {
    DateTime getGroupDate(String title) {
      if (title == 'Today') return today;
      if (title == 'Yesterday') return yesterday;
      return DateFormat('E, d MMM').parse(title);
    }

    return getGroupDate(b.title).compareTo(getGroupDate(a.title));
  });

  return groupedList;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Notifications"),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _getNotifications,
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavBar(
        activeItem: 'Home',
        onTap: (selected) => print("Tapped on $selected"),
      ),
    );
  }

Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: const Color(0xFFFF6705),

        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Retry',
              onPressed: _getNotifications,
              backgroundColor: const Color(0xFFFF6705),
              textColor: Colors.white,
            ),
          ],
        ),
      );
    }

    if (notificationGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notificationGroups.length,
        itemBuilder: (context, groupIndex) {
          final group = notificationGroups[groupIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  group.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ...group.notifications.map((notification) {
                return NotificationTile(notification: notification);
              }),
            ],
          );
        },
      );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const NotificationTile({super.key, required this.notification});

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }

  Widget _buildAvatar() {
    if (notification.imageUrl?.isNotEmpty ?? false) {
      return CircleAvatar(
        backgroundImage: NetworkImage(notification.imageUrl ?? ''),
        radius: 20,
      );
    } else {
      final initials = notification.title.trim().isNotEmpty
          ? notification.title.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
          : '?';
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.purple[100],
        child: Text(
          initials,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildAvatar(),
      title: Text(
        notification.message,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Text(
        _getTimeAgo(notification.createdAt),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }
}
