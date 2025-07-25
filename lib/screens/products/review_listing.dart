
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:junction/screens/products/submit_confirm.dart';

import '../../app_state.dart';
import '../../widgets/app_button.dart';

class ReviewListingPage extends StatelessWidget {
  final List<String> imageUrls; // From add_product_images.dart
  final String title;
  final String price;
  final String age;
  final String usage;
  final String condition;
  final String description;
  final String pickupLocation;
  final String selectedCategory;
  final String productName;
  final String yearOfPurchase;
  final String brandName;
  final LatLng latlng;

  const ReviewListingPage({
    super.key,
    required this.imageUrls,
    required this.title,
    required this.price,
    required this.age,
    required this.usage,
    required this.condition,
    required this.description,
    required this.pickupLocation,
    required this.selectedCategory,
    required this.yearOfPurchase,
    required this.brandName,
    required this.productName,
    required this.latlng
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Place a Listing"),
        centerTitle: true,
        leading: const BackButton(),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.close))],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _progressIndicator(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Review Listing", style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 16),

            // Image Carousel
           /* CarouselSlider(
              options: CarouselOptions(height: 200.0, viewportFraction: 1.0),
              items: imageUrls.map((img) {
                return Builder(
                  builder: (BuildContext context) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(img, fit: BoxFit.cover, width: double.infinity),
                    );
                  },
                );
              }).toList(),
            ),*/
            const SizedBox(height: 16),

            // Tags
            Row(
              children: [
                _tag("Age: $age"),
                const SizedBox(width: 8),
                _tag("Usage: $usage"),
                const SizedBox(width: 8),
                _tag("Condition: $condition"),
              ],
            ),
            const SizedBox(height: 16),

            // Title and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Text(
                  price,
                  style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description Field
            _editableField(context, "Description", description),
            const SizedBox(height: 12),

            // Pickup Location Field
            _editableField(context, "Pickup Location", pickupLocation),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppButton(
                bottomSpacing: 20,
                label: 'Add New Address',
                backgroundColor: const Color(0xFF262626),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostGuidelinesPage(
                        selectedCategory: selectedCategory,
                        title: title,
                        price: price,
                        description: description,
                        productName: productName,
                        yearOfPurchase: yearOfPurchase,
                        brand: brandName,
                        usage: usage,
                        condition: condition,
                        images: imageUrls,
                        location: pickupLocation,
                        latlng: latlng,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _editableField(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.edit, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _progressIndicator() {
    return Row(
      children: List.generate(
        5,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            decoration: BoxDecoration(
              color: index < 4  ? AppState.instance.isJuction?
              const Color(0xFFC105FF):
              const Color(0xFFFF6705): const Color(0xFFE9E9E9),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
