import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import 'success_delete.dart';

class DeleteAccountPage extends StatefulWidget {
  final String selectedReason;

  const DeleteAccountPage({super.key, required this.selectedReason});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _feedbackController = TextEditingController();
  bool isSubmitting = false;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> _submitIssue() async {
    setState(() => isSubmitting = true);

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication failed")),
      );
      setState(() => isSubmitting = false);
      return;
    }

    final url = Uri.parse("https://api.junctionverse.com/user/delete");

    final payload = {
      "reasonForDeletion": {
        "reason": widget.selectedReason,
        "description": _feedbackController.text.trim()
      }
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    setState(() => isSubmitting = false);

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ReportedSuccessPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete account")),
      );
    }
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
            Text(
              widget.selectedReason,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Do You have any additional feedback for us? (optional)",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 36),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF262626)),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextFormField(
                controller: _feedbackController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: "Your feedback...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const Spacer(),
            AppButton(
              bottomSpacing: 24,
              label: isSubmitting ? 'Deleting...' : 'Delete My Account',
              onPressed: isSubmitting ? null : _submitIssue,
              backgroundColor: const Color(0xFF262626),
            ),
          ],
        ),
      ),
    );
  }
}
