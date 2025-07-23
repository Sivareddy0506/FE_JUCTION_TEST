import 'package:flutter/material.dart';
import '../screens/products/home.dart';
import '../screens/jauction/main.dart';
import '../screens/products/category_post.dart';
import '../screens/jauction/category_post.dart';

class BottomNavBar extends StatelessWidget {
  final String activeItem;
  final Function(String) onTap;

  const BottomNavBar({
    Key? key,
    required this.activeItem,
    required this.onTap,
  }) : super(key: key);

  void _showPostOverlay(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    barrierColor: Colors.black.withOpacity(0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                "Choose the type of Listing",
                style: TextStyle(
                  fontSize: 20,
                  height: 1.4,
                  color: Color(0xFF262626),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildOverlayButton(
                      context,
                      label: 'Regular Listing',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryPostPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOverlayButton(
                      context,
                      label: 'Jauction Listing',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JauctionCategoryPostPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
  );
}


static Widget _buildOverlayButton(BuildContext context,
    {required String label, required VoidCallback onPressed}) {
  return SizedBox(
    height: 40,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF262626), width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF262626),
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}


  Widget _buildNavItem(
      BuildContext context, String label, String iconBaseName) {
    final isActive = activeItem.toLowerCase() == label.toLowerCase();
    final assetPath = 'assets/${iconBaseName}${isActive ? "-active" : ""}.png';

    return Expanded(
      child: GestureDetector(
        onTap: () {
          final lowerLabel = label.toLowerCase();
          if (lowerLabel == 'post') {
            _showPostOverlay(context);
          } else if (lowerLabel == 'home') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (lowerLabel == 'junction') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JauctionHomePage()),
            );
          } else {
            onTap(lowerLabel);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(assetPath, width: 24, height: 24),
            const SizedBox(height: 4),
            Text(
              label[0].toUpperCase() + label.substring(1).toLowerCase(),
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? const Color(0xFFFF6705)
                    : const Color(0xFF8A8894),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFDDDDDD))),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildNavItem(context, 'home', 'House'),
          _buildNavItem(context, 'post', 'Plus'),
          _buildNavItem(context, 'junction', 'Store'),
          _buildNavItem(context, 'profile', 'User'),
        ],
      ),
    );
  }
}
