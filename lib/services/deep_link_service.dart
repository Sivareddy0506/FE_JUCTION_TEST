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
    debugPrint('🔗 Universal Link received: $uri');
    
    // Parse https://share.junctionverse.com/{productId}
    if (uri.scheme == 'https' && uri.host == 'share.junctionverse.com') {
      // Extract productId from path (e.g., /abc-123-def -> abc-123-def)
      final pathSegments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
      
      if (pathSegments.isNotEmpty) {
        final productId = pathSegments.first;
        
        // Validate UUID format
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        
        if (uuidRegex.hasMatch(productId)) {
          if (onProductLinkReceived != null) {
            debugPrint('🔗 ✅ Valid product ID extracted: $productId');
            onProductLinkReceived!(productId);
          } else {
            debugPrint('🔗 ⚠️ Product link callback not set');
          }
        } else {
          debugPrint('🔗 ❌ Invalid product ID format: $productId');
        }
      } else {
        debugPrint('🔗 ❌ No product ID found in URL path');
      }
    } else {
      debugPrint('🔗 ⚠️ Unrecognized Universal Link: ${uri.scheme}://${uri.host}');
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
