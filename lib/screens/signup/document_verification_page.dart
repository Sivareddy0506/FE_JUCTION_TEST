import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/headding_description.dart';
import './verification_submitted.dart';

class DocumentVerificationPage extends StatefulWidget {
  final String email;
  const DocumentVerificationPage({super.key, required this.email});

  @override
  State<DocumentVerificationPage> createState() => _DocumentVerificationPageState();
}

class _DocumentVerificationPageState extends State<DocumentVerificationPage> {
  final picker = ImagePicker();
  bool isLoading = false;

  final Map<String, File?> uploadedFiles = {
    'selfie': null,
    'collegeId': null,
    'aadhaar': null,
    'otherDocs': null,
  };

  Future<File?> compressImage(File file) async {
    final dir = Directory.systemTemp;
    final targetPath = '${dir.path}/${p.basename(file.path)}_compressed.jpg';

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
    );

    return result != null ? File(result.path) : null;
  }

  Future<void> _handlePickedFile(
    XFile? picked,
    String key,
    BuildContext context,
    Function setState,
    Function setStateBottom,
  ) async {
    if (picked != null) {
      File file = File(picked.path);
      file = (await compressImage(file)) ?? file;

      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 3) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size must not exceed 3MB')),
          );
        }
      } else {
        setState(() => uploadedFiles[key] = file);
        setStateBottom(() {});
      }
    }
  }

  void _showUploadSheet(String key, String label) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: StatefulBuilder(
            builder: (context, setStateBottom) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(color: Color(0xFFE3E3E3)),
                const Text(
                  "Note: Please upload a clear picture of your valid student ID, ensuring the ID is fully visible and legible.",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () async {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Take a Photo'),
                              onTap: () async {
                                Navigator.pop(context);
                                final picked = await picker.pickImage(source: ImageSource.camera);
                                await _handlePickedFile(picked, key, context, setState, setStateBottom);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Choose from Gallery'),
                              onTap: () async {
                                Navigator.pop(context);
                                final picked = await picker.pickImage(source: ImageSource.gallery);
                                await _handlePickedFile(picked, key, context, setState, setStateBottom);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: uploadedFiles[key] == null
                      ? Container(
                          width: double.infinity,
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade600),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/camera.png'),
                              const SizedBox(height: 10),
                              const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Click here',
                                      style: TextStyle(color: Color(0xFFFF6705), fontWeight: FontWeight.w500),
                                    ),
                                    TextSpan(text: ' to take the picture'),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Color(0xFF8A8894)),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 19),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image.asset('assets/Files.png'),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.45,
                                    child: Text(
                                      p.basename(uploadedFiles[key]!.path),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() => uploadedFiles[key] = null);
                                  setStateBottom(() {});
                                },
                                child: Image.asset('assets/X.png'),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 8),
                const Text('JPG, PNG, PDF files up to 3MB', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 20),

                AppButton(
                  label: isLoading ? 'Uploading...' : 'Upload',
                  onPressed: uploadedFiles[key] != null
                      ? () {
                          Navigator.pop(context);
                        }
                      : null,
                  backgroundColor: uploadedFiles[key] != null
                      ? const Color(0xFF262626)
                      : const Color(0xFFA3A3A3),
                ),
                const SizedBox(height: 10),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

 Future<void> _submitAll() async {
  setState(() => isLoading = true);

  final uri = Uri.parse("https://api.junctionverse.com/user/upload-verification-docs");
  final request = http.MultipartRequest('POST', uri);
  request.fields['email'] = widget.email;

  for (var entry in uploadedFiles.entries) {
    if (entry.value != null) {
      request.files.add(http.MultipartFile.fromBytes(
        entry.key,
        entry.value!.readAsBytesSync(),
        filename: p.basename(entry.value!.path),
      ));
    }
  }

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  setState(() => isLoading = false);

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification submitted.')),
    );

    // Navigate to verification_submitted.dart
    if (context.mounted) {
      Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const VerificationSubmittedPage()),
);

    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: ${response.body}')),
    );
  }
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeadingWithDescription(
              heading: 'Document Verification',
              description: 'Please upload the following document for us to verify.',
            ),
            const SizedBox(height: 40),

            ...uploadedFiles.keys.map((key) {
              final label = switch (key) {
                'selfie' => '* Selfie',
                'collegeId' => '* College ID',
                'aadhaar' => '* Aadhar Card',
                _ => 'Additional Documents',
              };

              final isUploaded = uploadedFiles[key] != null;

              return InkWell(
                onTap: () => _showUploadSheet(key, label),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFC9C8D3))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                      Image.asset(
                        isUploaded ? 'assets/tick-green.png' : 'assets/CaretRight.png',
                        height: 20,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Spacer(),

            AppButton(
              bottomSpacing: 20,
              label: isLoading ? 'Submitting...' : 'Submit for Verification',
              onPressed: uploadedFiles.values.where((f) => f != null).length >= 3 && !isLoading
                  ? _submitAll
                  : null,
              backgroundColor: uploadedFiles.values.where((f) => f != null).length >= 3
                  ? const Color(0xFF262626)
                  : const Color(0xFFA3A3A3),
            ),
          ],
        ),
      ),
    );
  }
}
