import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ShareService {
  // Web URL base for product sharing
  static const String shareBaseUrl = 'https://share.junctionverse.com';

  static Future<void> shareProduct({
    required String productId,
    required String productTitle,
    String? productImageUrl,
  }) async {
    // Generate Universal Link URL
    final productUrl = '$shareBaseUrl/$productId';
    
    // Create share message - web page handles app opening and store redirects
    final message = '''
Check out this listing on Junction: $productTitle

$productUrl
''';

    try {
      await Share.share(
        message,
        subject: 'Check out this listing: $productTitle',
      );
    } catch (e) {
      debugPrint('Error sharing product: $e');
      // Fallback: Copy to clipboard
      try {
        await Clipboard.setData(ClipboardData(text: productUrl));
        debugPrint('Link copied to clipboard as fallback');
      } catch (clipboardError) {
        debugPrint('Error copying to clipboard: $clipboardError');
      }
    }
  }

  // Alternative: Share with just the link (simpler message)
  static Future<void> shareProductSimple({
    required String productId,
    required String productTitle,
  }) async {
    final productUrl = '$shareBaseUrl/$productId';
    
    final message = '''
$productTitle

$productUrl
''';

    try {
      await Share.share(message, subject: productTitle);
    } catch (e) {
      debugPrint('Error sharing product: $e');
    }
  }
}
