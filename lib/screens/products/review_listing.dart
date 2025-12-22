
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:junction/screens/products/submit_confirm.dart';
import 'package:junction/screens/products/location_selection_page.dart';

import '../../app_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/listing_progress_indicator.dart';
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
  final String selectedSubCategory;
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
    required this.selectedSubCategory,
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
  late String _currentTitle;
  late String _currentPrice;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPickupLocation = widget.pickupLocation;
    _currentLatLng = widget.latlng;
    _currentDescription = widget.description;
    _currentTitle = widget.title;
    _currentPrice = widget.price;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Place a Listing"),
        centerTitle: true,
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: const ListingProgressIndicator(currentStep: 5),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Review Listing", style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 16),

                  // Image Carousel
                  if (widget.imageUrls.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: PageView.builder(
                          itemCount: widget.imageUrls.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (_, pageIndex) {
                            final url = widget.imageUrls[pageIndex];
                            final isNetwork = url.startsWith('http');
                            final isAsset = url.startsWith('assets/');
                            if (isNetwork) {
                              return Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                              );
                            } else if (isAsset) {
                              return Image.asset(url, fit: BoxFit.cover);
                            } else {
                              return Image.file(File.fromUri(Uri.parse(url)), fit: BoxFit.cover);
                            }
                          },
                        ),
                      ),
                    ),
                    if (widget.imageUrls.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.imageUrls.length, (index) {
                            final isActive = index == _currentImageIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: isActive ? 18 : 6,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.black87 : const Color(0xFFD9D9D9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            );
                          }),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // Tags
                  Row(
                    children: [
                      _tag("Age: ${widget.age}"),
                      const SizedBox(width: 8),
                      _tag("Condition: ${widget.condition}"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title Field
                  _editableField(
                    context, 
                    "Title", 
                    _currentTitle,
                    onEdit: () => _editTitle(context),
                  ),
                  const SizedBox(height: 12),

                  // Price Field
                  _editableField(
                    context, 
                    "Price", 
                    _currentPrice,
                    onEdit: () => _editPrice(context),
                    showCurrency: true,
                  ),
                  const SizedBox(height: 12),

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
                              selectedSubCategory: widget.selectedSubCategory,
                              title: _currentTitle,
                              price: _currentPrice,
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
          ),
        ],
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

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter product description',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF262626),
                      borderColor: const Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Save',
                      onPressed: () {
                        if (descriptionController.text.trim().isNotEmpty) {
                          Navigator.pop(bottomSheetContext, descriptionController.text.trim());
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _currentDescription = result;
      });
    }
  }

  Future<void> _editTitle(BuildContext context) async {
    final TextEditingController titleController = 
        TextEditingController(text: _currentTitle);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Title',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter product title',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF262626),
                      borderColor: const Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Save',
                      onPressed: () {
                        if (titleController.text.trim().isNotEmpty) {
                          Navigator.pop(bottomSheetContext, titleController.text.trim());
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _currentTitle = result;
      });
    }
  }

  Future<void> _editPrice(BuildContext context) async {
    final TextEditingController priceController = 
        TextEditingController(text: _currentPrice);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Price',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                decoration: const InputDecoration(
                  hintText: 'Enter price',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF262626),
                      borderColor: const Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Save',
                      onPressed: () {
                        if (priceController.text.trim().isNotEmpty) {
                          Navigator.pop(bottomSheetContext, priceController.text.trim());
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _currentPrice = result;
      });
    }
  }

  Future<void> _editLocation(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      SlidePageRoute(
        page: const LocationSelectionPage(isForPostListing: true),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _currentPickupLocation = result["address"] ?? _currentPickupLocation;
        _currentLatLng = result["coordinates"] ?? _currentLatLng;
      });
    }
  }

  Widget _editableField(BuildContext context, String label, String value, {VoidCallback? onEdit, bool showCurrency = false}) {
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
                  Text(
                    showCurrency ? '₹ $value' : value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: showCurrency ? const Color(0xFFFF6705) : Colors.black,
                    ),
                  ),
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

}
