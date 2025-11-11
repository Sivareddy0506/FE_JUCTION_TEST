import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/app_button.dart';

class ListingGuidelinesPage extends StatefulWidget {
  final Map<String, dynamic> listingData;

  const ListingGuidelinesPage({super.key, required this.listingData});

  @override
  State<ListingGuidelinesPage> createState() => _ListingGuidelinesPageState();
}

class _ListingGuidelinesPageState extends State<ListingGuidelinesPage> {
  bool agreed = false;
  bool isSubmitting = false;

  Future<void> _submitListing() async {
    setState(() => isSubmitting = true);

    final uri = Uri.parse("https://api.junctionverse.com/product/products");
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer YOUR_TOKEN_HERE';

    final data = widget.listingData;

    request.fields['name'] = data['productName'];
    request.fields['title'] = data['title'];
    request.fields['description'] = data['description'];
    request.fields['category'] = data['selectedCategory'];
    request.fields['condition'] = data['condition'];
    request.fields['brand'] = data['brandName'];
    request.fields['yearOfPurchase'] = data['yearOfPurchase'];
    request.fields['usage'] = data['usage'];
    request.fields['price'] = data['price'];
    request.fields['isAuction'] = 'false';
    request.fields['location'] = jsonEncode(data['location']);
    request.fields['notes'] = data['notes'] ?? '';

    for (String path in data['imagePaths']) {
      request.files.add(await http.MultipartFile.fromPath('images', path));
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        Navigator.pushNamed(context, '/listingSuccess');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Place a Listing"),
        centerTitle: true,
        leading: const BackButton(),
        actions: const [Icon(Icons.close)],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Guidelines for Posting Listings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Here are few points to check before posting your item",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text("• All listings are subject to review"),
            const Text("• No Sale of Prohibited Items"),
            const Text("• No Offensive Content"),
            const Text("• Listings must not include hate speech, discriminatory language, or explicit content"),
            const Text("• All Images Must be Original"),
            const Spacer(),
            Row(
              children: [
                Checkbox(
                  value: agreed,
                  onChanged: (value) => setState(() => agreed = value ?? false),
                ),
                const Expanded(
                  child: Text("I have read and agree to the Ad Posting Terms & Conditions."),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppButton(
              label: isSubmitting ? 'Submitting...' : 'Done',
              onPressed: agreed && !isSubmitting ? _submitListing : null,
              backgroundColor: agreed ? Colors.black : Colors.grey,
              textColor: Colors.white,
              customChild: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : null,
            )
          ],
        ),
      ),
    );
  }
}
