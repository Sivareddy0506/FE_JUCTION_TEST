import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../screens/Notifications/notifications_screen.dart';
import '../../screens/Chat/chats_list_page.dart';
class LogoAndIconsWidget extends StatelessWidget {
  const LogoAndIconsWidget({super.key});

  final List<String> logoAssets = const [
    'assets/logo-a.png',
    'assets/logo-b.png',
    'assets/logo-c.png',
    'assets/logo-d.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Logos
        ...logoAssets.map(
          (asset) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(asset, width: 28, height: 28),
          ),
        ),

        const Spacer(),

        // Notification Icon with orange dot
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage()));
          },
          child: Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Image.asset('assets/Notification.png'),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
        ),

        // Chat Icon
        GestureDetector(
          onTap: () {
            Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatListPage()),
);
          },
          child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Image.asset('assets/Chat.png'),
        )
        ),
      ],
    );
  }
}
