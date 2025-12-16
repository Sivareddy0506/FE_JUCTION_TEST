import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  // Callback for handling deep links
  Function(String productId)? onProductLinkReceived;

  void initialize() {
    // Handle initial link (if app opened via deep link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }).catchError((err) {
      debugPrint('Deep link initial link error: $err');
    });

    // Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (err) => debugPrint('Deep link stream error: $err'),
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');
    
    // Parse junction://product/{productId}
    if (uri.scheme == 'junction' && uri.host == 'product') {
      final productId = uri.pathSegments.isNotEmpty 
          ? uri.pathSegments.first 
          : null;
      
      if (productId != null && onProductLinkReceived != null) {
        onProductLinkReceived!(productId);
      } else {
        debugPrint('Deep link: Invalid product ID or callback not set');
      }
    } else {
      debugPrint('Deep link: Unrecognized scheme or host: ${uri.scheme}://${uri.host}');
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
