import 'package:flutter/material.dart';
import 'core/themes.dart';
import 'screens/home_screen.dart';
import 'navigation_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Junction',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      navigatorKey: NavigationService.navigatorKey,
      home: const HomeScreen(),
    );
  }
}

/// Smooth horizontal slide transition (right to left) - most commonly used in modern apps
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({required Widget page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from right to left
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

/// Fade transition for modal-like screens
class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({required Widget page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
            opacity: animation.drive(
              CurveTween(curve: Curves.easeInOut),
            ),
            child: child,
          ),
        );
}
