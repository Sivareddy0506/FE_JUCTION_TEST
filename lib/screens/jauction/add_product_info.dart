import 'package:flutter/material.dart';
import '../../../widgets/custom_appbar.dart';

class AddProductInfoPage extends StatefulWidget {
  final String selectedCategory;

  const AddProductInfoPage({super.key, required this.selectedCategory});

  @override
  State<AddProductInfoPage> createState() => _AddProductInfoPageState();
}

class _AddProductInfoPageState extends State<AddProductInfoPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    // Validate or pass to next step
    if (title.isNotEmpty && description.isNotEmpty) {
      // Proceed to next step
      print("Title: $title\nDescription: $description");

      // Example: Navigator.push(...)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Add Product Info"),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Category: ${widget.selectedCategory}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8A8894),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Product Title",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
              ),
            ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Enter title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Product Description",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
              ),
            ),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Enter description",
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6705),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _onContinue,
                child: const Text(
                  "Continue",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
