import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import './reported_success.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController descriptionController = TextEditingController();
  String selectedIssue = 'General app issue';
  File? screenshot;
  bool isSubmitting = false;

  final List<String> issues = [
    'Product Listing',
    'Transaction',
    'Auction',
    'Chats',
    'General app issue',
    'Other'
  ];

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        screenshot = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitIssue() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) return;

    setState(() => isSubmitting = true);

    final uri = Uri.parse('https://api.junctionverse.com/user/report-issue');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['issueTitle'] = selectedIssue;
    request.fields['issueDescription'] = descriptionController.text;

    if (screenshot != null) {
      request.files.add(await http.MultipartFile.fromPath('screenshots', screenshot!.path));
    }

    final response = await request.send();
    setState(() => isSubmitting = false);

    if (response.statusCode == 200) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportedSuccessPage()));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit issue.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Report Issue"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report an Issue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Spotted something wrong? Help us keep Junction safe and clean by reporting issues directly',
                style: TextStyle(fontSize: 14, color: Color(0xFF8A8894))),

            const SizedBox(height: 24),
            const Text('What is this related to ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: issues.map((issue) {
                final isSelected = selectedIssue == issue;
                return ChoiceChip(
                  label: Text(issue),
                  selected: isSelected,
                  onSelected: (_) => setState(() => selectedIssue = issue),
                  selectedColor: const Color(0xFFFF6705),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCCCCCC)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            const Text('Please describe the issue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 32),
            const Text('Upload screenshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF999999), width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: screenshot == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_outlined, size: 32, color: Color(0xFF8A8894)),
                            SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                text: 'Click here',
                                style: TextStyle(color: Color(0xFFFF6705), fontWeight: FontWeight.w500),
                                children: [TextSpan(text: ' to upload the document', style: TextStyle(color: Color(0xFF8A8894)))],
                              ),
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text('JPG, PNG files up to 2MB', style: TextStyle(fontSize: 14, color: Color(0xFF8A8894)))
                          ],
                        )
                      : Image.file(screenshot!, fit: BoxFit.cover),
                ),
              ),
            ),

            const SizedBox(height: 32),
            AppButton(
              bottomSpacing: 24,
              label: isSubmitting ? 'Submitting...' : 'Submit',
              onPressed: isSubmitting ? null : _submitIssue,
              backgroundColor: const Color(0xFFFF6705),
            )
          ],
        ),
      ),
    );
  }
}
