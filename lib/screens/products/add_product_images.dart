import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import './select_location.dart';

class AddProductImagesPage extends StatefulWidget {
  final String selectedCategory;
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
  
  // Image upload limits
  static const int maxImages = 6;

  final ImagePicker _picker = ImagePicker();

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectLocationPage(
          selectedCategory: widget.selectedCategory,
          title: widget.title,
          price: widget.price,
          description: widget.description,
          productName: widget.productName,
          yearOfPurchase: widget.yearOfPurchase,
          brandName: widget.brandName,
          usage: widget.usage,
          condition: widget.condition,
          imageNames: imageNames,
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        // Check file size (5MB limit)
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        final maxSize = 5 * 1024 * 1024; // 5MB in bytes
        
        if (fileSize > maxSize) {
          _showErrorDialog(
            'File Too Large',
            'The selected image (${_formatFileSize(fileSize)}) is too large. Please select an image smaller than 5MB.',
          );
          return;
        }
        
        // Check file format
        final extension = pickedFile.path.split('.').last.toLowerCase();
        final allowedFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        
        if (!allowedFormats.contains(extension)) {
          _showErrorDialog(
            'Unsupported Format',
            'The file format ".$extension" is not supported. Please select an image in JPG, PNG, GIF, or WebP format.',
          );
          return;
        }
        
        setState(() {
          imageNames.add(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorDialog(
        'Upload Error',
        'Failed to upload image. Please try again.',
      );
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 32),

            // Uploaded Images
            for (int i = 0; i < imageNames.length; i++) 
              _buildImageItem(imageNames[i], imageIndex: i),

            // "Take a Photo" Option should always be visible
            _buildImageItem("Take a Photo", isAddNew: true),

            const Spacer(),

            AppButton(
              bottomSpacing: 24,
              label: isSubmitting ? 'Submitting...' : 'Next',
              onPressed: (isSubmitting || imageNames.isEmpty) ? null : _goToSelectLocationPage,
            ),
          ],
        ),
      ),
    );
  }
}
