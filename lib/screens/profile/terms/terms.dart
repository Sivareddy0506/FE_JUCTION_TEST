import 'package:flutter/material.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/bottom_navbar.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  Widget _buildTerm(String heading, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.33,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.33,
                          color: Color(0xFF505050))),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF505050),
                        height: 1.33,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Terms & Conditions"),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTerm("1. Eligibility", [
                        "You must be a currently enrolled student at a recognized educational institution.",
                        "You must be at least 18 years of age or have consent from a parent or legal guardian.",
                      ]),
                      _buildTerm("2. Account Registration", [
                        "You agree to provide accurate and complete information during sign-up.",
                        "You are responsible for maintaining the confidentiality of your account credentials.",
                        "Junction reserves the right to suspend or delete accounts that violate these Terms or provide false information.",
                      ]),
                      _buildTerm("3. Use of Platform", [
                        "Junction is a student-exclusive marketplace designed for buying, selling, and auctioning products within the student community.",
                        "You agree not to use Junction for any unlawful, harmful, or misleading activities.",
                        "Listings must be accurate, and users must not engage in price manipulation, fake bids, or fraudulent activity.",
                      ]),
                      _buildTerm("4. Prohibited Items", [
                        "Items violating any local, state, or national laws.",
                        "Dangerous goods, weapons, prescription drugs, or restricted content.",
                        "Counterfeit items or anything infringing on intellectual property rights.",
                      ]),
                      _buildTerm("5. Marketplace & Auction Rules", [
                        "Listings must include clear descriptions and images.",
                        "Bids placed in auctions are binding; the highest bidder is expected to complete the transaction.",
                        "Sellers are responsible for ensuring that items are delivered in the promised condition.",
                        "Junction is not responsible for returns or refunds. All such matters must be resolved between the buyer and seller (or vendor, where applicable).",
                      ]),
                      _buildTerm("6. Disputes & Feedback", [
                        "Buyers may raise disputes in case of issues with purchases.",
                        "Junction will mediate disputes but does not guarantee resolution.",
                        "Feedback must be truthful and constructive. Abuse of the feedback system is prohibited.",
                      ]),
                      _buildTerm("7. Premium Features", [
                        "Junction may offer optional premium features for a subscription fee (e.g., featured listings, ad-free experience, exclusive vendor drops).",
                        "Details of these features and applicable fees will be outlined within the app.",
                      ]),
                      _buildTerm("8. Data Privacy", [
                        "We respect your privacy. Your personal information is handled in accordance with our Privacy Policy.",
                      ]),
                      _buildTerm("9. Termination", [
                        "Junction reserves the right to terminate accounts for breach of Terms, fraud, abuse, or misconduct.",
                        "Users may delete their account at any time through the app.",
                      ]),
                      _buildTerm("10. Changes of Terms", [
                        "These Terms may be updated from time to time. Users will be notified of significant changes.",
                      ]),
                      _buildTerm("11. Governing Laws", [
                        "These Terms are governed by the laws of the Republic of India, and any disputes shall be subject to the exclusive jurisdiction of the courts located in Hyderabad, Telangana.",
                      ]),
                      _buildTerm("12. Intellectual Property", [
                        "All content on Junction (excluding user-generated content) including logos, branding, design, and software is the intellectual property of Junction and may not be copied or used without permission.",
                        "Users retain ownership of content they post but grant Junction a limited license to display and promote it within the app.",
                      ]),
                      _buildTerm("13. Limitation of Liability", [
                        "Junction is not liable for any damages or losses resulting from transactions between users, technical issues, or unauthorized access to user accounts.",
                        "Users transact at their own risk and are encouraged to use the feedback system and report any suspicious activity.",
                      ]),
                      _buildTerm("14. Third-Party Services", [
                        "Some features (e.g., payments or deliveries) may involve third-party services. Users agree to their respective terms when using these features.",
                      ]),
                      _buildTerm("15. Community Guidelines", [
                        "To maintain a safe and respectful environment, users must not engage in harassment, hate speech, spam, or abuse of any kind.",
                        "Violation of these guidelines may result in warnings, suspensions, or permanent bans.",
                      ]),
                      _buildTerm("16. Indemnity", [
                        "Users agree to indemnify and hold harmless Junction, its team, partners, and affiliates from any claims, liabilities, damages, losses, and expenses arising from or related to their use of the app, including violations of these Terms or applicable laws.",
                      ]),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        activeItem: 'Profile',
        onTap: (selected) => print("Tapped on $selected"),
      ),
    );
  }
}
