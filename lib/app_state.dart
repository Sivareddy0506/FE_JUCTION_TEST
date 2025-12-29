import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  static AppState? _instance;

  AppState._();

  static AppState get instance => _instance ??= AppState._();
  bool isJuction = false;
  String auctionDate = "";
  String listingDuration = "";
  bool _isOnboarded = false;
  bool _isVerified = false;

  bool get isOnboarded => _isOnboarded;
  bool get isVerified => _isVerified;

  void setIsOnboarded(bool value) {
    if (_isOnboarded != value) {
      _isOnboarded = value;
      notifyListeners();
    }
  }

  void setIsVerified(bool value) {
    if (_isVerified != value) {
      _isVerified = value;
      notifyListeners();
    }
  }

  void setUserStatus({required bool isVerified, required bool isOnboarded}) {
    bool changed = false;
    if (_isVerified != isVerified) {
      _isVerified = isVerified;
      changed = true;
    }
    if (_isOnboarded != isOnboarded) {
      _isOnboarded = isOnboarded;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }
}