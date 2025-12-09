
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:junction/screens/products/submit_confirm.dart';
import 'package:junction/screens/products/select_location.dart';

import '../../app_state.dart';
import '../../widgets/app_button.dart';
import '../../app.dart'; // For SlidePageRoute

class ReviewListingPage extends StatefulWidget {
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
  State<ReviewListingPage> createState() => _ReviewListingPageState();
}

class _ReviewListingPageState extends State<ReviewListingPage> {
  late String _currentPickupLocation;
  late LatLng _currentLatLng;
  late String _currentDescription;

  @override
  void initState() {
    super.initState();
    _currentPickupLocation = widget.pickupLocation;
    _currentLatLng = widget.latlng;
    _currentDescription = widget.description;
  }


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
                _tag("Age: ${widget.age}"),
                const SizedBox(width: 8),
                _tag("Usage: ${widget.usage}"),
                const SizedBox(width: 8),
                _tag("Condition: ${widget.condition}"),
              ],
            ),
            const SizedBox(height: 16),

            // Title and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Text(
                  widget.price,
                  style: const TextStyle(fontSize: 16, color: Color(0xFFFF6705),
 fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description Field
            _editableField(
              context, 
              "Description", 
              _currentDescription,
              onEdit: () => _editDescription(context),
            ),
            const SizedBox(height: 12),

            // Pickup Location Field
            _editableField(
              context, 
              "Pickup Location", 
              _currentPickupLocation,
              onEdit: () => _editLocation(context),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppButton(
                bottomSpacing: 20,
                label: 'Review Guidelines',
                backgroundColor: const Color(0xFF262626),
                onPressed: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: PostGuidelinesPage(
                        selectedCategory: widget.selectedCategory,
                        title: widget.title,
                        price: widget.price,
                        description: _currentDescription,
                        productName: widget.productName,
                        yearOfPurchase: widget.yearOfPurchase,
                        brand: widget.brandName,
                        usage: widget.usage,
                        condition: widget.condition,
                        images: widget.imageUrls,
                        location: _currentPickupLocation,
                        latlng: _currentLatLng,
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

  Future<void> _editDescription(BuildContext context) async {
    final TextEditingController descriptionController = 
        TextEditingController(text: _currentDescription);

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Description'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter product description',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: AppButton(
                  label: 'Save',
                  onPressed: () {
                    if (descriptionController.text.trim().isNotEmpty) {
                      Navigator.of(context).pop(descriptionController.text.trim());
                    }
                  },
                  backgroundColor: const Color(0xFFFF6705),
                  textColor: Colors.white,
                ),
              ),
            ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _currentDescription = result;
      });
    }
  }

  Future<void> _editLocation(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      SlidePageRoute(
        page: SelectLocationPage(
          selectedCategory: widget.selectedCategory,
          title: widget.title,
          price: widget.price,
          description: _currentDescription,
          productName: widget.productName,
          yearOfPurchase: widget.yearOfPurchase,
          brandName: widget.brandName,
          usage: widget.usage,
          condition: widget.condition,
          imageNames: widget.imageUrls,
          isEditing: true, // Mark as editing mode
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _currentPickupLocation = result["address"] ?? _currentPickupLocation;
        _currentLatLng = result["coordinates"] ?? _currentLatLng;
      });
    }
  }

  Widget _editableField(BuildContext context, String label, String value, {VoidCallback? onEdit}) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
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
            Icon(
              Icons.edit, 
              size: 18, 
              color: onEdit != null ? Colors.blue : Colors.grey,
            ),
          ],
        ),
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
