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
    final screenWidth = MediaQuery.of(context).size.width;

    // 🔧 Responsive sizes
    final logoSize = (screenWidth * 0.07).clamp(24.0, 40.0); // Logos
    final iconContainerSize = (screenWidth * 0.1).clamp(36.0, 48.0); // Circle container
    final iconSize = iconContainerSize * 0.55; // Inner image size

    return Row(
      children: [
        // Logos
        ...logoAssets.map(
          (asset) => Padding(
            padding: const EdgeInsets.only(right: 12),
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

        // Notification Icon with orange dot
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            );
          },
          child: Stack(
            children: [
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                margin: const EdgeInsets.only(right: 8),
                padding: EdgeInsets.all(iconContainerSize * 0.2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Image.asset(
                  'assets/Notification.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Positioned(
                right: iconContainerSize * 0.2,
                top: iconContainerSize * 0.2,
                child: Container(
                  width: iconContainerSize * 0.2,
                  height: iconContainerSize * 0.2,
                  decoration: const BoxDecoration(
                    color: const Color(0xFFFF6705),

                    shape: BoxShape.circle,
                  ),
                ),
              ),
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
            width: iconContainerSize,
            height: iconContainerSize,
            margin: const EdgeInsets.only(right: 8),
            padding: EdgeInsets.all(iconContainerSize * 0.2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Image.asset(
              'assets/Chat.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ],
    );
  }
}
