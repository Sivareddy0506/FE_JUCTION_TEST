import 'package:flutter/material.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import 'reasons_delete.dart';

class ThinkingDeletePage extends StatelessWidget {
  const ThinkingDeletePage({super.key});

  void _proceed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReasonsDeletePage()),
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
              "Thinking of leaving Junction?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
                height: 1.2, // 24px line height
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "We're sorry to see you go. Deleting your account will permanently remove your data, listings, chats, and wallet balance.",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.black,
                height: 1.33, // 16px line height
              ),
            ),
            const Spacer(),
            AppButton(
              bottomSpacing: 24,
              label: 'Proceed',
              onPressed: () => _proceed(context),
              backgroundColor: const Color(0xFF262626),
            ),
          ],
        ),
      ),
    );
  }
}
