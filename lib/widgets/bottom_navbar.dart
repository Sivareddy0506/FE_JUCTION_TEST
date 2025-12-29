import 'package:flutter/material.dart';
import 'package:junction/app_state.dart';
import '../screens/products/category_post.dart';
import '../screens/products/home.dart';
import '../services/navigation_manager.dart';
import '../app.dart'; // For SlidePageRoute
import '../utils/feature_lock.dart';

// Wrapper widget that always shows bottom navigation
class BottomNavWrapper extends StatelessWidget {
  final Widget child;
  final String activeItem;
  final Function(String) onTap;

  const BottomNavWrapper({
    super.key,
    required this.child,
    required this.activeItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false, // Don't add bottom safe area since we handle it in BottomNavBar
        child: child,
      ),
      bottomNavigationBar: BottomNavBar(
        activeItem: activeItem,
        onTap: onTap,
      ),
    );
  }
}

// Improved BottomNavBar with responsive icons
class BottomNavBar extends StatelessWidget {
  final String activeItem;
  final Function(String) onTap;

  const BottomNavBar({
    super.key,
    required this.activeItem,
    required this.onTap,
  });

  Widget _buildNavItem(
    BuildContext context,
    String label,
    String iconBaseName,
  ) {
    final isActive = activeItem.toLowerCase() == label.toLowerCase();
    final assetPath = 'assets/$iconBaseName${isActive ? "-active" : ""}.png';

    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.06).clamp(22.0, 32.0); // responsive size
    final fontSize = (screenWidth * 0.03).clamp(11.0, 14.0); // responsive font

    final isOnboarded = AppState.instance.isOnboarded;
    final isLocked = !isOnboarded && (label.toLowerCase() == 'post' || 
                                      label.toLowerCase() == 'jauction' || 
                                      label.toLowerCase() == 'profile');

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Check if feature is locked
          if (isLocked) {
            lockIfNotOnboarded(context);
            return;
          }

          final lowerLabel = label.toLowerCase();

          if (lowerLabel == 'home') {
            // Navigate to home using same pattern as other tabs (no slider)
            final targetRoute = lowerLabel;
            if (!isActive) {
              NavigationManager.setCurrentRoute(targetRoute);
              final targetPage = NavigationManager.getPreservedPage(targetRoute);

              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      targetPage,
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          } else if (lowerLabel == 'post') {
            AppState.instance.isJuction = false; // Default to regular listing
            Navigator.push(
              context,
              SlidePageRoute(
                page: const CategoryPostPage(),
              ),
            );
          } else {
            final targetRoute = lowerLabel;
            if (!isActive) {
              NavigationManager.setCurrentRoute(targetRoute);
              final targetPage = NavigationManager.getPreservedPage(targetRoute);

              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      targetPage,
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: isLocked ? 0.4 : 1.0,
              child: Image.asset(
                assetPath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high, // 🔥 crisp icons
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label[0].toUpperCase() + label.substring(1).toLowerCase(),
              style: TextStyle(
                fontSize: fontSize,
                color: isLocked
                    ? const Color(0xFF8A8894).withOpacity(0.4)
                    : (isActive ? const Color(0xFFFF6705) : const Color(0xFF8A8894)),
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 60 + bottomPadding,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFDDDDDD))),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(context, 'home', 'House'),
                _buildNavItem(context, 'post', 'Plus'),
                _buildNavItem(context, 'jauction', 'Store'),
                _buildNavItem(context, 'profile', 'User'),
              ],
            ),
          ),
          if (bottomPadding > 0) SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}
