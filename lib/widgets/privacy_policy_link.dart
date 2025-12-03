import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({super.key});

  Future<void> _launchPrivacyPolicy(BuildContext context) async {
    final Uri url = Uri.parse('https://www.junctionverse.com/privacy-policy');
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open privacy policy. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open privacy policy. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'By continuing, you agree to our ',
            style: TextStyle(fontSize: 12, color: Color(0xFF8A8894)),
          ),
          GestureDetector(
            onTap: () => _launchPrivacyPolicy(context),
            child: const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFF6705),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFFFF6705),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

