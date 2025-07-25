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

  final ImagePicker _picker = ImagePicker();

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
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        imageNames.add(pickedFile.path);
      });
    }
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

  Widget _buildImageItem(String name, {bool isAddNew = false}) {
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
            onTap: isAddNew ? _showImageSourceDialog : null,
            child: Row(
              children: [
                Icon(
                  isAddNew ? Icons.add : Icons.check,
                  color: isAddNew ? Colors.grey : Colors.green,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
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
            const Text(
              "Make sure to have clean background and clear shots of the product",
              style: TextStyle(fontSize: 12, color: Color(0xFF323537)),
            ),
            const SizedBox(height: 32),

            // Uploaded Images
            for (var imageName in imageNames) _buildImageItem(imageName),

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
