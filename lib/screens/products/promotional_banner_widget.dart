import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/promotional_banner.dart';
import '../profile/crewclash/crewclash.dart';
import '../../app.dart';
import 'registration_webview.dart';

class PromotionalBannerWidget extends StatelessWidget {
  final PromotionalBanner banner;

  const PromotionalBannerWidget({
    super.key,
    required this.banner,
  });

  /// Parse hex color string to Color object
  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.white;
    try {
      // Remove # if present and parse hex
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse(hex, radix: 16) + 0xFF000000);
    } catch (e) {
      debugPrint('Error parsing color: $colorHex - $e');
      return Colors.white;
    }
  }

  /// Handle button press based on action type
  void _handleButtonPress(BuildContext context) {
    // Priority 1: If registrationUrl is set, open in WebView
    if (banner.registrationUrl != null && banner.registrationUrl!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationWebView(
            url: banner.registrationUrl!,
            title: banner.title,
          ),
        ),
      );
      return;
    }

    // Priority 2: Handle actionType and actionUrl
    if (banner.actionType == 'navigate' && banner.actionUrl != null) {
      // Navigate to internal route
      // For now, we'll handle specific routes
      if (banner.actionUrl == '/crew-clash' || banner.actionUrl == 'crew-clash') {
        Navigator.push(
          context,
          SlidePageRoute(page: const CrewClashPage()),
        );
      } else {
        // Generic navigation - can be extended for other routes
        debugPrint('Navigating to: ${banner.actionUrl}');
        // You can add more route handling here
      }
    } else if (banner.actionType == 'external_link' && banner.actionUrl != null) {
      // Open external URL
      launchUrl(
        Uri.parse(banner.actionUrl!),
        mode: LaunchMode.externalApplication,
      ).catchError((e) {
        debugPrint('Error launching URL: $e');
      });
    } else if (banner.actionType == 'webview' && banner.actionUrl != null) {
      // Open actionUrl in WebView
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationWebView(
            url: banner.actionUrl!,
            title: banner.title,
          ),
        ),
      );
    }
    // If actionType is 'none' or null, do nothing
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(banner.bgColor);
    final textColor = _parseColor(banner.textColor);
    // Use punchy orange as default button color, or use banner.buttonColor if specified
    final buttonColor = banner.buttonColor != null && banner.buttonColor!.isNotEmpty
        ? _parseColor(banner.buttonColor)
        : const Color(0xFFFF6705); // Punchy orange

    return Container(
      margin: EdgeInsets.zero, // No vertical margin - spacing handled by parent SizedBox
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        image: banner.imageUrl != null && banner.imageUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(banner.imageUrl!),
                fit: BoxFit.cover,
                opacity: 0.3, // Overlay effect for text readability
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  banner.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle!,
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (banner.buttonText != null && banner.buttonText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: ElevatedButton(
                onPressed: () => _handleButtonPress(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  banner.buttonText!,
                  style: TextStyle(
                    color: bgColor, // Use background color for button text (contrast)
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

