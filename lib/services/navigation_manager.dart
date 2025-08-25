import 'package:flutter/material.dart';
import '../screens/products/home.dart';
import '../screens/profile/user_profile.dart';
import '../screens/jauction/main.dart';

/// Navigation Manager for preserving page states during navigation
class NavigationManager {
  static final NavigationManager _instance = NavigationManager._internal();
  factory NavigationManager() => _instance;
  NavigationManager._internal();

  // Preserved page instances
  static final Map<String, Widget> _preservedPages = {};
  static final Map<String, dynamic> _preservedStates = {};
  static String _currentRoute = '';

  /// Get or create a preserved page instance
  static Widget getPreservedPage(String route) {
    if (_preservedPages.containsKey(route)) {
      debugPrint('NavigationManager: Returning preserved page for $route');
      return _preservedPages[route]!;
    }

    // Create new page instance
    Widget page;
    switch (route.toLowerCase()) {
      case 'home':
        page = const HomePage();
        break;
      case 'profile':
        page = const UserProfilePage();
        break;
      case 'junction':
        page = const JauctionHomePage();
        break;
      default:
        page = const HomePage(); // Default fallback
    }

    _preservedPages[route] = page;
    debugPrint('NavigationManager: Created new preserved page for $route');
    return page;
  }

  /// Preserve current page state
  static void preserveCurrentState(String route, dynamic state) {
    _preservedStates[route] = state;
    debugPrint('NavigationManager: Preserved state for $route');
  }

  /// Get preserved state for a route
  static dynamic getPreservedState(String route) {
    return _preservedStates[route];
  }

  /// Clear preserved page and state
  static void clearPreservedPage(String route) {
    _preservedPages.remove(route);
    _preservedStates.remove(route);
    debugPrint('NavigationManager: Cleared preserved page and state for $route');
  }

  /// Clear all preserved pages and states
  static void clearAllPreserved() {
    _preservedPages.clear();
    _preservedStates.clear();
    debugPrint('NavigationManager: Cleared all preserved pages and states');
  }

  /// Set current route
  static void setCurrentRoute(String route) {
    _currentRoute = route;
  }

  /// Get current route
  static String get currentRoute => _currentRoute;

  /// Check if page is preserved
  static bool isPagePreserved(String route) {
    return _preservedPages.containsKey(route);
  }

  /// Get all preserved routes
  static List<String> get preservedRoutes => _preservedPages.keys.toList();

  /// Get navigation statistics
  static Map<String, dynamic> getNavigationStats() {
    return {
      'currentRoute': _currentRoute,
      'preservedPages': _preservedPages.length,
      'preservedStates': _preservedStates.length,
      'preservedRoutes': preservedRoutes,
    };
  }
}
