import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ShareService {
  // App Store and Play Store URLs
  static const String appStoreUrl = 'https://apps.apple.com/in/app/junctionverse/id6755690478';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.junction&pcampaignid=web_share';

  static Future<void> shareProduct({
    required String productId,
    required String productTitle,
    String? productImageUrl,
  }) async {
    // Generate deep link URL
    final deepLink = 'junction://product/$productId';
    
    // Create share message with instructions
    final message = '''
Check out this listing on Junction: $productTitle

🔗 Open in app: $deepLink

📱 Instructions:
• If you don't have the Junction app installed, download it from:
  - iOS: $appStoreUrl
  - Android: $playStoreUrl

• Complete signup before viewing products to access all features.

• Once installed and signed up, click the link above to view this product directly in the app.
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
        await Clipboard.setData(ClipboardData(text: deepLink));
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
    final deepLink = 'junction://product/$productId';
    
    final message = '''
$productTitle

$deepLink

Download Junction app:
iOS: $appStoreUrl
Android: $playStoreUrl

Complete signup to view products.
''';

    try {
      await Share.share(message, subject: productTitle);
    } catch (e) {
      debugPrint('Error sharing product: $e');
    }
  }
}
