import 'package:flutter/material.dart';
import '../app_state.dart';

/// Cooldown tracker to prevent snackbar spam
DateTime? _lastSnackbarShown;
const _snackbarCooldown = Duration(seconds: 2);

/// Checks if user is onboarded. If not, shows a snackbar (with cooldown) and returns true (locked).
/// Returns false if user is onboarded (not locked).
bool lockIfNotOnboarded(BuildContext context) {
  final isOnboarded = AppState.instance.isOnboarded;
  if (isOnboarded) return false;

  // Cooldown check: only show snackbar if cooldown has passed
  final now = DateTime.now();
  if (_lastSnackbarShown != null && now.difference(_lastSnackbarShown!) < _snackbarCooldown) {
    return true; // Still locked, but don't show another snackbar
  }

  // Clear any existing snackbars and show new one
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Verification pending – complete student approval to use this feature'),
      duration: Duration(seconds: 3),
    ),
  );
  
  _lastSnackbarShown = now;
  return true;
}

