import 'package:flutter/material.dart';
import '../../../widgets/custom_appbar.dart';
import 'delete_account.dart';

class ReasonsDeletePage extends StatelessWidget {
  const ReasonsDeletePage({super.key});

  final List<String> reasons = const [
    "I found what I was looking for",
    "I couldn’t find enough product",
    "I had trouble selling my items",
    "I’m concerned about my privacy and data",
    "Not satisfied with the experience",
    "Other",
  ];

  void _navigateToDeleteAccount(BuildContext context, String reason) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeleteAccountPage(selectedReason: reason),
      ),
    );
  }

  Widget _buildReasonItem(BuildContext context, String reason) {
    return GestureDetector(
      onTap: () => _navigateToDeleteAccount(context, reason),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFC9C8D3), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                reason,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF262626),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Image.asset('assets/CaretLeft.png', width: 20, height: 20),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Delete Account"),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Delete my Account",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Help us understand why you're leaving",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 36),
            ...reasons.map((reason) => _buildReasonItem(context, reason)),
          ],
        ),
      ),
    );
  }
}
