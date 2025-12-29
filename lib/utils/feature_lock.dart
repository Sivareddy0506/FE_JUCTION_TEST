import 'package:flutter/material.dart';
import '../app_state.dart';

/// Checks if user is onboarded. If not, shows a snackbar and returns true (locked).
/// Returns false if user is onboarded (not locked).
bool lockIfNotOnboarded(BuildContext context) {
  final isOnboarded = AppState.instance.isOnboarded;
  if (isOnboarded) return false;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Verification pending – complete student approval to use this feature'),
      duration: Duration(seconds: 3),
    ),
  );
  return true;
}

