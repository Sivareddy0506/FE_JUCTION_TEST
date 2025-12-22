import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:junction/screens/products/location_selection_page.dart';
import '../../models/product.dart';
import '../../widgets/app_button.dart';
import '../../app.dart'; // For SlidePageRoute

class EditListingPage extends StatefulWidget {
  final Product product;

  const EditListingPage({
    super.key,
    required this.product,
  });

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  late String _currentTitle;
  late String _currentPrice;
  late String _currentDescription;
  late String _currentPickupLocation;
  late LatLng _currentLatLng;
  int _currentImageIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.product.title;
    _currentPrice = widget.product.price?.replaceAll('₹', '').trim() ?? '';
    _currentDescription = widget.product.description ?? '';
    _currentPickupLocation = widget.product.readableLocation ?? widget.product.location ?? 'Location not set';
    _currentLatLng = LatLng(
      widget.product.latitude ?? 0.0,
      widget.product.longitude ?? 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Listing"),
        centerTitle: true,
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Edit Listing", style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 16),

                  // Image Carousel (read-only)
                  if (widget.product.images.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: PageView.builder(
                          itemCount: widget.product.images.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (_, pageIndex) {
                            final image = widget.product.images[pageIndex];
                            return Image.network(
                              image.fileUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                            );
                          },
                        ),
                      ),
                    ),
                    if (widget.product.images.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.product.images.length, (index) {
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

                  // Tags (read-only)
                  Row(
                    children: [
                      if (widget.product.yearOfPurchase != null)
                        _tag("Age: ${widget.product.yearOfPurchase}"),
                      if (widget.product.yearOfPurchase != null && widget.product.condition != null)
                        const SizedBox(width: 8),
                      if (widget.product.condition != null)
                        _tag("Condition: ${widget.product.condition}"),
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
                      label: _isSubmitting ? 'Submitting...' : 'Save Changes',
                      backgroundColor: const Color(0xFF262626),
                      onPressed: _isSubmitting ? null : _saveChanges,
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

  Future<void> _editTitle(BuildContext context) async {
    final TextEditingController titleController = TextEditingController(text: _currentTitle);

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
    final TextEditingController priceController = TextEditingController(text: _currentPrice);

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

  Future<void> _editDescription(BuildContext context) async {
    final TextEditingController descriptionController = TextEditingController(text: _currentDescription);

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

  Future<void> _editLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      SlidePageRoute(
        page: SelectLocationPageForLocationSelection(),
      ),
    );

    if (result != null && result is Map) {
      final coordinates = result['coordinates'] as LatLng?;
      final address = result['address'] as String?;

      if (coordinates != null && address != null && mounted) {
        setState(() {
          _currentLatLng = coordinates;
          _currentPickupLocation = address;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    // Show confirmation dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resubmit for Review'),
        content: const Text(
          'Your listing will be resubmitted for review and will not be live until updates are approved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Prepare image objects from existing product images
      final imageObjects = widget.product.images.map((img) => {
        'fileUrl': img.fileUrl,
        'fileType': img.fileType ?? 'image/jpeg',
        'filename': img.filename ?? img.fileUrl.split('/').last,
      }).toList();

      final uri = Uri.parse('https://api.junctionverse.com/product/products/${widget.product.id}');
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': widget.product.title, // Using title as name
          'title': _currentTitle,
          'description': _currentDescription,
          'category': widget.product.category ?? '',
          'subCategory': null, // Not editable
          'condition': widget.product.condition ?? '',
          'brand': widget.product.brand ?? '',
          'yearOfPurchase': widget.product.yearOfPurchase?.toString() ?? '',
          'usage': '', // Not editable in this flow
          'price': _currentPrice,
          'isAuction': widget.product.isAuction ?? false,
          'location': {
            'lat': _currentLatLng.latitude,
            'lng': _currentLatLng.longitude,
          },
          'images': imageObjects,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing updated successfully. It will be reviewed before going live.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate successful update
        } else {
          final errorBody = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update listing: ${errorBody['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating listing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while updating the listing.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
