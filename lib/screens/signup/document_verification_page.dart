import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/headding_description.dart';
import '../../utils/image_compression.dart';
import './verification_submitted.dart';
import '../../app.dart'; // For SlidePageRoute

class DocumentVerificationPage extends StatefulWidget {
  final String email;
  final String referralCode;
  const DocumentVerificationPage({super.key, required this.email, this.referralCode = ''});

  @override
  State<DocumentVerificationPage> createState() => _DocumentVerificationPageState();
}

class _DocumentVerificationPageState extends State<DocumentVerificationPage> {
  final picker = ImagePicker();
  bool isLoading = false;
  String? fileSizeError; // Error message for file size
  
  // File size limits
  static const int maxTotalSize = 20 * 1024 * 1024; // 20MB total in bytes

  final Map<String, File?> uploadedFiles = {
    'selfie': null,
    'collegeId': null,
    'aadhaar': null,
    'otherDocs': null,
  };
  final Map<String, bool> _consentGiven = {};

  // Calculate total size of all uploaded files
  Future<int> _getTotalSize() async {
    int total = 0;
    for (var file in uploadedFiles.values) {
      if (file != null && await file.exists()) {
        total += await file.length();
      }
    }
    return total;
  }

  // Format file size helper
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }


  bool _requiresConsent(String key) => key == 'aadhaar';

  Future<void> _handlePickedFile(
    XFile? picked,
    String key,
    BuildContext context,
    Function setState,
    Function setStateBottom,
  ) async {
    if (picked != null) {
      // Compress image to ensure it's under 5MB
      final compressedFile = await ImageCompression.compressImageToFit(picked.path);
      if (compressedFile == null) {
        if (context.mounted) {
          setState(() {
            fileSizeError = 'Failed to process image. Please try again.';
          });
          setStateBottom(() {});
        }
        return;
      }

      final fileSize = await compressedFile.length();

      // Check total size (20MB total limit)
      final currentTotal = await _getTotalSize();
      // Get the previous file size if replacing
      final previousFile = uploadedFiles[key];
      int previousSize = 0;
      if (previousFile != null && await previousFile.exists()) {
        previousSize = await previousFile.length();
      }
      final newTotal = currentTotal - previousSize + fileSize;

      if (newTotal > maxTotalSize) {
        if (context.mounted) {
          setState(() {
            fileSizeError = 'Total upload size (${ImageCompression.formatFileSize(newTotal)}) exceeds 20MB limit. Please remove some files or select smaller files.';
          });
          setStateBottom(() {});
        }
        return;
      }

      setState(() {
        uploadedFiles[key] = compressedFile;
        fileSizeError = null; // Clear error on success
      });
      setStateBottom(() {});
    }
  }

  Future<void> _takePicture(String key, String label) async {
    // Check consent first if required
    if (_requiresConsent(key) && !(_consentGiven[key] ?? false)) {
      // Show consent dialog first
      final consentGiven = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(label),
          content: CheckboxListTile(
            value: _consentGiven[key] ?? false,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I agree to share these documents with JunctionVerse for verification purposes.',
              style: TextStyle(fontSize: 14),
            ),
            onChanged: (value) {
              setState(() {
                _consentGiven[key] = value ?? false;
              });
              Navigator.pop(context, value ?? false);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _consentGiven[key] ?? false),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      
      if (consentGiven != true) {
        return; // User didn't provide consent or cancelled
      }
    }
    
    // Directly open camera
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100, // High quality for verification documents
    );
    
    if (picked != null) {
      await _handlePickedFile(picked, key, context, setState, () {});
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
                  "Note: Please take a clear picture of your valid student ID, ensuring the ID is fully visible and legible.",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),

                if (_requiresConsent(key))
                  CheckboxListTile(
                    value: _consentGiven[key] ?? false,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I agree to share these documents with JunctionVerse for verification purposes.',
                      style: TextStyle(fontSize: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _consentGiven[key] = value ?? false;
                      });
                      setStateBottom(() {});
                    },
                  ),

                GestureDetector(
                  onTap: () async {
                    if (_requiresConsent(key) && !(_consentGiven[key] ?? false)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please provide consent before taking a picture of this document.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    await _takePicture(key, label);
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
                                      text: 'Tap here',
                                      style: TextStyle(color: Color(0xFFFF6705), fontWeight: FontWeight.w500),
                                    ),
                                    TextSpan(text: ' to take a picture'),
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
                                  setState(() {
                                    uploadedFiles[key] = null;
                                    fileSizeError = null; // Clear error when removing file
                                  });
                                  setStateBottom(() {});
                                },
                                child: Image.asset('assets/X.png'),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 8),
                const Text('JPG, PNG files up to 5MB each (Camera only for security)', style: TextStyle(fontSize: 14)),
                
                // Show total size info
                FutureBuilder<int>(
                  future: _getTotalSize(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final totalSize = snapshot.data!;
                      final uploadedCount = uploadedFiles.values.where((f) => f != null).length;
                      if (uploadedCount > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Total size: ${_formatFileSize(totalSize)} / ${_formatFileSize(maxTotalSize)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: totalSize > maxTotalSize ? Colors.red : const Color(0xFF8A8894),
                            ),
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
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
                
                const SizedBox(height: 20),

                AppButton(
                  label: isLoading ? 'Uploading...' : 'Done',
                  onPressed: uploadedFiles[key] != null && (! _requiresConsent(key) || (_consentGiven[key] ?? false))
                      ? () {
                          Navigator.pop(context);
                        }
                      : null,
                  backgroundColor: uploadedFiles[key] != null
                      ? ((!_requiresConsent(key) || (_consentGiven[key] ?? false))
                          ? const Color(0xFF262626)
                          : const Color(0xFF8C8C8C))
                      : const Color(0xFF8C8C8C),
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

 Future<void> _submitAll() async {
   // Check total size before submitting
   final totalSize = await _getTotalSize();
   if (totalSize > maxTotalSize) {
     setState(() {
       fileSizeError = 'Total upload size (${_formatFileSize(totalSize)}) exceeds 20MB limit. Please remove some files or select smaller files.';
     });
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text('Total upload size exceeds 20MB limit. Please reduce file sizes.'),
         backgroundColor: Colors.red,
       ),
     );
     return;
   }

  if (_requiresConsent('aadhaar') && uploadedFiles['aadhaar'] != null && !(_consentGiven['aadhaar'] ?? false)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please provide consent before submitting your ID document.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
 
   setState(() => isLoading = true);
   String? errorMessage;

   try {
     // Get auth token for JWT authentication (requireVerified middleware)
     final prefs = await SharedPreferences.getInstance();
     final authToken = prefs.getString('authToken');
     
     final uri = Uri.parse("https://api.junctionverse.com/user/upload-verification-docs");
     final request = http.MultipartRequest('POST', uri);
     request.fields['email'] = widget.email;
     
     // Add referral code if provided
     if (widget.referralCode.isNotEmpty) {
       request.fields['userReferralCode'] = widget.referralCode;
     }
     
     // Add JWT token for authentication (requireVerified middleware)
     if (authToken != null && authToken.isNotEmpty) {
       request.headers['Authorization'] = 'Bearer $authToken';
     }

     // Read files asynchronously and add to request
     int totalRequestSize = request.fields['email']!.length; // Start with email field size
     debugPrint('DocumentVerification: Starting file upload. Email field size: ${totalRequestSize} bytes');
     
     for (var entry in uploadedFiles.entries) {
       if (entry.value != null) {
         final fileBytes = await entry.value!.readAsBytes();
         final fileName = p.basename(entry.value!.path);
         
         // Estimate multipart overhead (~150-200 bytes per file for headers + boundaries)
         final estimatedOverhead = 200;
         final estimatedMultipartSize = fileBytes.length + estimatedOverhead;
         totalRequestSize += estimatedMultipartSize;
         
         debugPrint('DocumentVerification: Adding file ${entry.key} - ${(fileBytes.length / 1024 / 1024).toStringAsFixed(2)}MB, estimated multipart size: ${(estimatedMultipartSize / 1024 / 1024).toStringAsFixed(2)}MB');
         
         // Determine content type based on file extension
         String? contentType;
         final extension = p.extension(fileName).toLowerCase();
         if (extension == '.jpg' || extension == '.jpeg') {
           contentType = 'image/jpeg';
         } else if (extension == '.png') {
           contentType = 'image/png';
         } else if (extension == '.pdf') {
           contentType = 'application/pdf';
         }
         
        request.files.add(http.MultipartFile.fromBytes(
          entry.key,
          fileBytes,
          filename: fileName,
          contentType: contentType != null ? MediaType.parse(contentType) : null,
        ));
       }
     }
     
     debugPrint('DocumentVerification: Total estimated request size: ${(totalRequestSize / 1024 / 1024).toStringAsFixed(2)}MB');
     debugPrint('DocumentVerification: Sending request to ${request.url}');
     debugPrint('DocumentVerification: Number of files: ${request.files.length}');
     debugPrint('DocumentVerification: Request headers: ${request.headers}');

     debugPrint('DocumentVerification: Calling request.send()...');
     final streamedResponse = await request.send().timeout(
       const Duration(minutes: 5),
       onTimeout: () {
         debugPrint('DocumentVerification: Request timeout after 5 minutes');
         throw TimeoutException('Upload request timed out after 5 minutes');
       },
     );
     debugPrint('DocumentVerification: Request sent successfully. Status code: ${streamedResponse.statusCode}');
     debugPrint('DocumentVerification: Response headers: ${streamedResponse.headers}');
     
     final response = await http.Response.fromStream(streamedResponse);
     debugPrint('DocumentVerification: Response body length: ${response.body.length} bytes');
     debugPrint('DocumentVerification: Response status: ${response.statusCode}');
     debugPrint('DocumentVerification: Response body (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

     setState(() => isLoading = false);

     if (response.statusCode == 200) {
       // FCM token registration removed from document verification flow
       // Token will be registered after user logs in (see otp_verification_login.dart)
       // This prevents duplicate tokens and ensures proper cleanup
       
      if (context.mounted) {
        // Navigate to verification_submitted.dart
        Navigator.pushReplacement(
          context,
          SlidePageRoute(page: const VerificationSubmittedPage()),
        );
      }
     } else {
       errorMessage = 'Upload failed';
       String responseBody = response.body;
       
       // Parse error message
       if (response.statusCode == 413) {
         errorMessage = 'File size too large. Please ensure each file is under 5MB and total size is reasonable.';
       } else if (responseBody.isNotEmpty) {
         try {
           final errorJson = jsonDecode(responseBody);
           errorMessage = errorJson['error'] ?? errorJson['message'] ?? responseBody;
         } catch (e) {
           errorMessage = responseBody.length > 100 ? '${responseBody.substring(0, 100)}...' : responseBody;
         }
       }
       
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Failed: $errorMessage (Status: ${response.statusCode})'),
             backgroundColor: Colors.red,
             duration: const Duration(seconds: 5),
           ),
         );
       }
     }
   } catch (e, stackTrace) {
     setState(() => isLoading = false);
     
     debugPrint('DocumentVerification: Exception caught during upload');
     debugPrint('DocumentVerification: Exception type: ${e.runtimeType}');
     debugPrint('DocumentVerification: Exception message: ${e.toString()}');
     debugPrint('DocumentVerification: Stack trace: $stackTrace');
     
     // Check if it's a timeout or connection error
     if (e is TimeoutException) {
       errorMessage = 'Upload request timed out. Please check your internet connection and try again.';
     } else if (e is SocketException) {
       errorMessage = 'Network error: Unable to connect to server. Please check your internet connection.';
     } else if (e is HttpException) {
       errorMessage = 'HTTP error: ${e.message}';
     } else {
       errorMessage = 'Upload failed: ${e.toString()}';
     }
     
     if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(errorMessage),
           backgroundColor: Colors.red,
           duration: const Duration(seconds: 5),
         ),
       );
     }
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
                'aadhaar' => '* Aadhar or Govt ID',
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
              bottomSpacing: 60,
              label: isLoading ? 'Submitting...' : 'Submit for Verification',
              onPressed: uploadedFiles.values.where((f) => f != null).length >= 3 && !isLoading
                  ? _submitAll
                  : null,
              backgroundColor: uploadedFiles.values.where((f) => f != null).length >= 3
                  ? const Color(0xFF262626)
                  : const Color(0xFF8C8C8C),
            ),
          ],
        ),
      ),
    );
  }
}
