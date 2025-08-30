import 'package:flutter/material.dart';
import 'package:junction/app_state.dart';
import '../screens/products/home.dart';
import '../screens/jauction/main.dart';
import '../screens/products/category_post.dart';
//import '../screens/jauction/category_post.dart';
import '../screens/profile/user_profile.dart';
import '../services/navigation_manager.dart';

// Wrapper widget that always shows bottom navigation
class BottomNavWrapper extends StatelessWidget {
  final Widget child;
  final String activeItem;
  final Function(String) onTap;

  const BottomNavWrapper({
    Key? key,
    required this.child,
    required this.activeItem,
    required this.onTap,
  }) : super(key: key);

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

// Improved BottomNavBar with better navigation handling
class BottomNavBar extends StatelessWidget {
  final String activeItem;
  final Function(String) onTap;

  const BottomNavBar({
    Key? key,
    required this.activeItem,
    required this.onTap,
  }) : super(key: key);

  // TODO: Uncomment when restoring jauction functionality
  // void _showPostOverlay(BuildContext context) {
  // showModalBottomSheet(
  //   context: context,
  //   isScrollControlled: true,
  //   barrierColor: Colors.black.withOpacity(0.5),
  //   shape: const RoundedRectangleBorder(
  //     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //   ),
  //   builder: (_) {
  //     return Padding(
  //       padding: const EdgeInsets.all(24.0),
  //       child: SingleChildScrollView(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const SizedBox(height: 12),
  //             const Text(
  //               "Choose the type of Listing",
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 height: 1.4,
  //                 color: Color(0xFF262626),
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //             const SizedBox(height: 24),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: _buildOverlayButton(
  //                     context,
  //                     label: 'Regular Listing',
  //                     onPressed: () {
  //                       AppState.instance.isJuction = false;
  //                       Navigator.of(context).pop();
  //                       Navigator.push(
  //                         context,
  //                         MaterialPageRoute(
  //                           builder: (_) => const CategoryPostPage(),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Expanded(
  //                   child: _buildOverlayButton(
  //                     context,
  //                     label: 'Jauction Listing',
  //                     onPressed: () {
  //                       AppState.instance.isJuction = true;

  //                       Navigator.of(context).pop();
  //                       Navigator.push(
  //                         context,
  //                         MaterialPageRoute(
  //                           builder: (_) => const CategoryPostPage(),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 24),
  //           ],
  //         ),
  //       ),
  //     );
  //   },
  // );
  // }

// TODO: Uncomment when restoring jauction functionality
// static Widget _buildOverlayButton(BuildContext context,
//     {required String label, required VoidCallback onPressed}) {
//   return SizedBox(
//     height: 40,
//     child: OutlinedButton(
//       style: OutlinedButton.styleFrom(
//         side: const BorderSide(color: Color(0xFF262626), width: 1),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//       onPressed: onPressed,
//       child: Text(
//         label,
//         style: const TextStyle(
//           fontSize: 12,
//           color: Color(0xFF262626),
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     ),
//   );
// }

 Widget _buildNavItem(
    BuildContext context, String label, String iconBaseName) {
  final isActive = activeItem.toLowerCase() == label.toLowerCase();
  final assetPath = 'assets/${iconBaseName}${isActive ? "-active" : ""}.png';

  return Expanded(
    child: GestureDetector(
      onTap: () {
        final lowerLabel = label.toLowerCase();
        if (lowerLabel == 'post') {
          // TODO: Uncomment when restoring jauction functionality
          // _showPostOverlay(context);
          
          // Current implementation - directly navigate to CategoryPostPage
          AppState.instance.isJuction = false; // Default to regular listing
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CategoryPostPage(),
            ),
          );
        } else {
          // Use NavigationManager to preserve page states
          final targetRoute = lowerLabel.toLowerCase();
          
          // Only navigate if we're not already on the target page
          if (!isActive) {
            NavigationManager.setCurrentRoute(targetRoute);
            final targetPage = NavigationManager.getPreservedPage(targetRoute);
            
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => targetPage,
                transitionDuration: Duration.zero, // No animation to prevent flickering
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
    // Get system navigation bar height to ensure proper spacing
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      height: 60 + bottomPadding, // Add system navigation bar height
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFDDDDDD))),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Main navigation bar content
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
          // Add padding for system navigation bar
          if (bottomPadding > 0)
            SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}
