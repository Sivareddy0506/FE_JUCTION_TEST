import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:junction/app_state.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import '../profile/user_profile.dart';

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
  final List<String> images; // image files
  final LatLng latlng;

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
    required this.latlng
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final uri = Uri.parse("https://api.junctionverse.com/product/products");
    final request = http.MultipartRequest("POST", uri)
      ..headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = widget.productName;
    request.fields['title'] = widget.title;
    request.fields['description'] = widget.description;
    request.fields['category'] = widget.selectedCategory;
    request.fields['condition'] = widget.condition;
    request.fields['brand'] = widget.brand;
    request.fields['yearOfPurchase'] = widget.yearOfPurchase;
    request.fields['usage'] = widget.usage;
    request.fields['price'] = widget.price;
    request.fields['initialBid'] = widget.price;
    request.fields['startingPrice'] = widget.price;
    request.fields['isAuction'] = AppState.instance.isJuction.toString();
    if(AppState.instance.isJuction == true){
      request.fields['duration'] = AppState.instance.listingDuration;
      request.fields['bidStartDate'] = AppState.instance.auctionDate;
    }

    request.fields['location'] =jsonEncode({"lat":widget.latlng.latitude,
      "lng":widget.latlng.longitude});
    request.fields['notes'] = 'Charger included';

    for (String image in widget.images) {
      debugPrint('❌ Submission test: test $image');

      final mimeType = lookupMimeType(image) ?? 'image/jpeg';
      final mimeSplit = mimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        image,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ));
    }
    debugPrint('❌ Submission test: test');

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserProfilePage()),
              (Route<dynamic> route) => false, // ⬅️ removes all previous routes
        );
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
