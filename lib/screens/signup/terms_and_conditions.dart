import 'package:flutter/material.dart';
import '../../widgets/headding_description.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';
import './welcome_page.dart'; 
import '../../app.dart';


class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  bool isChecked = false;

  void _onSubmit() {
    Navigator.pushReplacement(
      context,
      FadePageRoute(page: const WelcomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: CustomAppBar(
        showBackButton: true,
        logoAssets: [
          'assets/logo-a.png',
          'assets/logo-b.png',
          'assets/logo-c.png',
          'assets/logo-d.png',
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeadingWithDescription(
              heading: 'Terms & Conditions',
              description:
                  "You're almost done! Please take a moment to review the Terms & Conditions before proceeding.",
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
     
    _SectionTitle("1. Eligibility"),
    _BulletText("You must be a currently enrolled student at a recognized educational institution."),
    _BulletText("You must be at least 18 years of age or have consent from a parent or legal guardian."),
    const SizedBox(height: 16),

    _SectionTitle("2. Account Registration"),
    _BulletText("You agree to provide accurate and complete information during sign-up."),
    _BulletText("You are responsible for maintaining the confidentiality of your account credentials."),
    _BulletText("Junction reserves the right to suspend or delete accounts that violate these Terms or provide false information."),
    const SizedBox(height: 16),

    _SectionTitle("3. Use of Platform"),
    _BulletText("Junction is a student-exclusive marketplace designed for buying, selling, and auctioning products within the student community."),
    _BulletText("You agree not to use Junction for any unlawful, harmful, or misleading activities."),
    _BulletText("Listings must be accurate, and users must not engage in price manipulation, fake bids, or fraudulent activity."),
    const SizedBox(height: 16),

    _SectionTitle("4. Prohibited Items"),
    _BulletText("Items violating any local, state, or national laws."),
    _BulletText("Dangerous goods, weapons, prescription drugs, or restricted content."),
    _BulletText("Counterfeit items or anything infringing on intellectual property rights."),
    const SizedBox(height: 16),

    _SectionTitle("5. Marketplace & Auction Rules"),
    _BulletText("Listings must include clear descriptions and images."),
    _BulletText("Bids placed in auctions are binding; the highest bidder is expected to complete the transaction."),
    _BulletText("Sellers are responsible for ensuring that items are delivered in the promised condition."),
    _BulletText("Junction is not responsible for returns or refunds. All such matters must be resolved between the buyer and seller (or vendor, where applicable)."),
    const SizedBox(height: 16),

    _SectionTitle("6. Disputes & Feedback"),
    _BulletText("Buyers may raise disputes in case of issues with purchases."),
    _BulletText("Junction will mediate disputes but does not guarantee resolution."),
    _BulletText("Feedback must be truthful and constructive. Abuse of the feedback system is prohibited."),
    const SizedBox(height: 16),

    _SectionTitle("7. Premium Features"),
    _BulletText("Junction may offer optional premium features for a subscription fee (e.g., featured listings, ad-free experience, exclusive vendor drops)."),
    _BulletText("Details of these features and applicable fees will be outlined within the app."),
    const SizedBox(height: 16),

    _SectionTitle("8. Data Privacy"),
    _BulletText("We respect your privacy. Your personal information is handled in accordance with our Privacy Policy."),
    const SizedBox(height: 16),

    _SectionTitle("9. Termination"),
    _BulletText("Junction reserves the right to terminate accounts for breach of Terms, fraud, abuse, or misconduct."),
    _BulletText("Users may delete their account at any time through the app."),
    const SizedBox(height: 16),

    _SectionTitle("10. Changes of Terms"),
    _BulletText("These Terms may be updated from time to time. Users will be notified of significant changes."),
    const SizedBox(height: 16),

    _SectionTitle("11. Governing Laws"),
    _BulletText("These Terms are governed by the laws of the Republic of India, and any disputes shall be subject to the exclusive jurisdiction of the courts located in Hyderabad, Telangana."),
    const SizedBox(height: 16),

    _SectionTitle("12. Intellectual Property"),
    _BulletText("All content on Junction (excluding user-generated content) including logos, branding, design, and software is the intellectual property of Junction and may not be copied or used without permission."),
    _BulletText("Users retain ownership of content they post but grant Junction a limited license to display and promote it within the app."),
    const SizedBox(height: 16),

    _SectionTitle("13. Limitation of Liability"),
    _BulletText("Junction is not liable for any damages or losses resulting from transactions between users, technical issues, or unauthorized access to user accounts."),
    _BulletText("Users transact at their own risk and are encouraged to use the feedback system and report any suspicious activity."),
    const SizedBox(height: 16),

    _SectionTitle("14. Third-Party Services"),
    _BulletText("Some features (e.g., payments or deliveries) may involve third-party services. Users agree to their respective terms when using these features."),
    const SizedBox(height: 16),

    _SectionTitle("15. Community Guidelines"),
    _BulletText("To maintain a safe and respectful environment, users must not engage in harassment, hate speech, spam, or abuse of any kind."),
    _BulletText("Violation of these guidelines may result in warnings, suspensions, or permanent bans."),
    const SizedBox(height: 16),

    _SectionTitle("16. Indemnity"),
    _BulletText("Users agree to indemnify and hold harmless Junction, its team, partners, and affiliates from any claims, liabilities, damages, losses, and expenses arising from or related to their use of the app, including violations of these Terms or applicable laws."),
  
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: isChecked,
                  activeColor: const Color(0xFF262626),

                  onChanged: (val) {
                    setState(() {
                      isChecked = val ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    "I have read and agree to the Terms & Conditions",
                    style: TextStyle(fontSize: 12, color: Color(0xFF212121)),
                  ),
                ),
              ],
            ),
            AppButton(
              bottomSpacing: 40,
              label: 'Done',
              onPressed: isChecked ? _onSubmit : null,
             backgroundColor: isChecked ? const Color(0xFFFF6705) : Colors.grey,

            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF212121),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;

  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 12, color: Color(0xFF212121)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF212121), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
