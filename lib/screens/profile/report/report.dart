import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import '../../../utils/image_compression.dart';
import './reported_success.dart';
import '../../../app.dart'; // For SlidePageRoute

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
  String? fileSizeError; // Error message for file size

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
    final source = await _showImageSourceDialog();
    if (source == null) return;
    
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      // Compress image to ensure it's under 5MB
      final compressedFile = await ImageCompression.compressImageToFit(pickedFile.path);
      if (compressedFile == null) {
        setState(() {
          fileSizeError = 'Failed to process image. Please try again.';
          screenshot = null;
        });
        return;
      }
      
      setState(() {
        screenshot = compressedFile;
        fileSizeError = null; // Clear error on success
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Add Photo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Take a Photo',
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFF262626),
                  borderColor: const Color(0xFF262626),
                  onPressed: () => Navigator.pop(context, ImageSource.camera),
                  bottomSpacing: 16,
                ),
                AppButton(
                  label: 'Upload from device',
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFF262626),
                  borderColor: const Color(0xFF262626),
                  onPressed: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
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
      Navigator.pushReplacement(context, SlidePageRoute(page: const ReportedSuccessPage()));
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
    hintStyle: const TextStyle(color: Color(0xFF8A8894), fontSize: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFF262626), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFF262626), width: 1),
    ),
  ),
  style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
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
                  borderRadius: BorderRadius.circular(6),
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
                            Text('JPG, PNG files up to 5MB', style: TextStyle(fontSize: 14, color: Color(0xFF8A8894)))
                          ],
                        )
                      : Image.file(screenshot!, fit: BoxFit.cover),
                ),
              ),
            ),
            
            // File size error message
            if (fileSizeError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileSizeError!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
