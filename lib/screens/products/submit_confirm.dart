import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';

class PostGuidelinesPage extends StatefulWidget {
  final String selectedCategory;
  final String title;
  final String description;
  final String productName;
  final String yearOfPurchase;
  final String usage;
  final String condition;
  final String brand;
  final String price;
  final String location;
  final List<File> images; // image files

  const PostGuidelinesPage({
    super.key,
    required this.selectedCategory,
    required this.title,
    required this.description,
    required this.productName,
    required this.yearOfPurchase,
    required this.usage,
    required this.condition,
    required this.brand,
    required this.price,
    required this.location,
    required this.images,
  });

  @override
  State<PostGuidelinesPage> createState() => _PostGuidelinesPageState();
}

class _PostGuidelinesPageState extends State<PostGuidelinesPage> {
  bool isSubmitting = false;
  bool isConfirmed = false;

  Future<void> _submitListing() async {
    if (!isConfirmed) return;

    setState(() => isSubmitting = true);

    final uri = Uri.parse("https://api.junctionverse.com/product/products");
    final request = http.MultipartRequest("POST", uri)
      ..headers['Authorization'] = 'Bearer {{token}}';

    request.fields['name'] = widget.productName;
    request.fields['title'] = widget.title;
    request.fields['description'] = widget.description;
    request.fields['category'] = widget.selectedCategory;
    request.fields['condition'] = widget.condition;
    request.fields['brand'] = widget.brand;
    request.fields['yearOfPurchase'] = widget.yearOfPurchase;
    request.fields['usage'] = widget.usage;
    request.fields['price'] = widget.price;
    request.fields['isAuction'] = 'false';
    request.fields['location'] = widget.location;
    request.fields['notes'] = 'Charger included';

    for (File image in widget.images) {
      final mimeType = lookupMimeType(image.path)?.split('/') ?? ['image', 'jpeg'];
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        image.path,
        contentType: MediaType(mimeType[0], mimeType[1]),
      ));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushNamed(context, '/product_submitted');
      } else {
        debugPrint('❌ Submission failed: ${response.statusCode}');
        debugPrint(response.body);
      }
    } catch (e) {
      debugPrint('❌ Error submitting product: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Guidelines for Posting Listings"),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Here are few points to check before posting your item",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF323537)),
            ),
            const SizedBox(height: 16),
            const BulletPoint(text: "All listings are subject to review"),
            const BulletPoint(text: "No Sale of Prohibited Items"),
            const BulletPoint(text: "No Offensive Content"),
            const BulletPoint(text: "Listings must not include hate speech, discriminatory language, or explicit content"),
            const BulletPoint(text: "All Images Must be Original"),
            const Spacer(),
            Row(
              children: [
                Checkbox(
                  value: isConfirmed,
                  onChanged: (val) => setState(() => isConfirmed = val ?? false),
                ),
                const Expanded(
                  child: Text("I have read and agree to the Ad Posting Terms & Conditions."),
                )
              ],
            ),
            AppButton(
              label: isSubmitting ? 'Submitting...' : 'Post Listing',
              onPressed: isConfirmed && !isSubmitting ? _submitListing : null,
              backgroundColor: const Color(0xFFFF6705),
              bottomSpacing: 24,
            )
          ],
        ),
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
