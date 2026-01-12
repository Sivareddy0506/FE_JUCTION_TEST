import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/listing_progress_indicator.dart';
import '../../../utils/image_compression.dart';
import './location_selection_page.dart';
import '../../../app.dart'; 

class AddProductImagesPage extends StatefulWidget {
  final String selectedCategory;
  final String selectedSubCategory;
  final String title;
  final String price;
  final String description;
  final String productName;
  final String yearOfPurchase;
  final String brandName;
  final String usage;
  final String condition;

  const AddProductImagesPage({
    super.key,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.title,
    required this.price,
    required this.description,
    required this.productName,
    required this.yearOfPurchase,
    required this.brandName,
    required this.usage,
    required this.condition,
  });

  @override
  State<AddProductImagesPage> createState() => _AddProductImagesPageState();
}

class _AddProductImagesPageState extends State<AddProductImagesPage> {
  final List<String> imageNames = [];
  bool isSubmitting = false;
  String? fileSizeError; // Error message for file size
  
  // Image upload limits
  static const int maxImages = 6;
  static const int maxTotalSize = 20 * 1024 * 1024; // 20MB total in bytes

  final ImagePicker _picker = ImagePicker();

  // Calculate total size of all uploaded images
  Future<int> _getTotalSize() async {
    int total = 0;
    for (String path in imageNames) {
      final file = File(path);
      if (await file.exists()) {
        total += await file.length();
      }
    }
    return total;
  }

  // Helper method to get user-friendly image name
  String _getImageDisplayName(int index) {
    return "Image ${index + 1}";
  }

  // Check if image limit is reached
  bool get _isImageLimitReached => imageNames.length >= maxImages;

  // Helper method to format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _goToSelectLocationPage() {
    // Navigate to LocationSelectionPage with all product data
    // LocationSelectionPage will handle navigation to ReviewListingPage
    Navigator.push(
      context,
      SlidePageRoute(
        page: LocationSelectionPage(
          isForPostListing: true,
          imageUrls: imageNames,
          title: widget.title,
          price: widget.price,
          age: widget.yearOfPurchase,
          usage: widget.usage,
          condition: widget.condition,
          description: widget.description,
          selectedCategory: widget.selectedCategory,
          selectedSubCategory: widget.selectedSubCategory,
          productName: widget.productName,
          yearOfPurchase: widget.yearOfPurchase,
          brandName: widget.brandName,
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => fileSizeError = null); // Clear previous error
      
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 100); // Pick at full quality first
      if (pickedFile != null) {
        // Check file format first
        final extension = pickedFile.path.split('.').last.toLowerCase();
        final allowedFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        
        if (!allowedFormats.contains(extension)) {
          setState(() {
            fileSizeError = 'The file format ".$extension" is not supported. Please select an image in JPG, PNG, GIF, or WebP format.';
          });
          return;
        }
        
        // Compress image to ensure it's under 5MB
        final compressedFile = await ImageCompression.compressImageToFit(pickedFile.path);
        if (compressedFile == null) {
          setState(() {
            fileSizeError = 'Failed to process image. Please try again.';
          });
          return;
        }
        
        final fileSize = await compressedFile.length();
        
        // Check total size (20MB total limit)
        final currentTotal = await _getTotalSize();
        if (currentTotal + fileSize > maxTotalSize) {
          // Clean up compressed file
          await compressedFile.delete();
          setState(() {
            fileSizeError = 'Total upload size (${ImageCompression.formatFileSize(currentTotal + fileSize)}) exceeds 20MB limit. Please remove some images or select smaller files.';
          });
          return;
        }
        
        setState(() {
          imageNames.add(compressedFile.path);
          fileSizeError = null; // Clear error on success
        });
      }
    } catch (e) {
      setState(() {
        fileSizeError = 'Failed to upload image. Please try again.';
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.camera);
                    },
                    bottomSpacing: 16,
                  ),
                  AppButton(
                    label: 'Upload from device',
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFF262626),
                    borderColor: const Color(0xFF262626),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
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

  Widget _buildImageItem(String name, {bool isAddNew = false, int? imageIndex}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: isAddNew && !_isImageLimitReached ? _showImageSourceDialog : null,
            child: Row(
              children: [
                Icon(
                  isAddNew ? Icons.add : Icons.check,
                  color: isAddNew 
                    ? (_isImageLimitReached ? Colors.grey.shade400 : Colors.grey)
                    : Colors.green,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: Text(
                    isAddNew ? name : _getImageDisplayName(imageIndex!),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isAddNew && _isImageLimitReached 
                        ? Colors.grey.shade400 
                        : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isAddNew)
            GestureDetector(
              onTap: () {
                setState(() {
                  imageNames.remove(name);
                });
              },
              child: const Icon(Icons.close, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Place a Listing"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: const ListingProgressIndicator(currentStep: 3),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Add Product Images",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF262626)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: const Text(
                          "Make sure to have clean background and clear shots of the product",
                          style: TextStyle(fontSize: 12, color: Color(0xFF323537)),
                        ),
                      ),
                      Text(
                        "${imageNames.length}/$maxImages",
                        style: TextStyle(
                          fontSize: 12,
                          color: _isImageLimitReached ? const Color(0xFFFF6705) : const Color(0xFF323537),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Show total size info
                  FutureBuilder<int>(
                    future: _getTotalSize(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && imageNames.isNotEmpty) {
                        final totalSize = snapshot.data!;
                        final totalSizeMB = totalSize / (1024 * 1024);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Total size: ${_formatFileSize(totalSize)} / ${_formatFileSize(maxTotalSize)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: totalSize > maxTotalSize ? Colors.red : const Color(0xFF323537),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 32),

                  // Uploaded Images
                  for (int i = 0; i < imageNames.length; i++) 
                    _buildImageItem(imageNames[i], imageIndex: i),

                  // "Add images" Option should always be visible
                  _buildImageItem("Add images", isAddNew: true),

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

                  const SizedBox(height: 24),

                  // Check total size before allowing navigation
                  FutureBuilder<int>(
                    future: _getTotalSize(),
                    builder: (context, snapshot) {
                      final totalSize = snapshot.data ?? 0;
                      final exceedsLimit = totalSize > maxTotalSize;
                      return AppButton(
                        bottomSpacing: 24,
                        label: isSubmitting ? 'Submitting...' : 'Next',
                        onPressed: (isSubmitting || imageNames.isEmpty || exceedsLimit) ? null : _goToSelectLocationPage,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
