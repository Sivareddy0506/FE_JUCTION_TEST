import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../app.dart';
import 'package:junction/screens/products/review_listing.dart';
import '../../widgets/app_button.dart';

class SelectLocationPage extends StatefulWidget {
  final String selectedCategory;
  final String title;
  final String price;
  final String description;
  final String productName;
  final String yearOfPurchase;
  final String brandName;
  final String usage;
  final String condition;
  final List<String> imageNames;
  final bool isEditing; // Whether this is called for editing location

  const SelectLocationPage({
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
    required this.imageNames,
    this.isEditing = false, // Default to false for normal flow
  });

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  GoogleMapController? mapController;
  LatLng _currentLatLng = const LatLng(17.385044, 78.486671); // Default to Hyderabad
  String _address = 'Fetching address...';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _userSearched = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.requestPermission();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _updatePosition(LatLng(position.latitude, position.longitude));
    }
  }

  void _updatePosition(LatLng position) {
    setState(() {
      _currentLatLng = position;
    });
    _fetchAddress(position);
    mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  Future<void> _fetchAddress(LatLng position) async {
    if (_userSearched) return; // Don't overwrite if user searched
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _address = "${placemark.name}, ${placemark.locality}, ${placemark.postalCode}";
        });
      }
    } catch (e) {
      if (!_userSearched) {
        setState(() {
          _address = 'Unable to fetch address';
        });
      }
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _userSearched = false;
      _searchController.clear(); // Clear search text when tapping map
    });
    _updatePosition(position);
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (value.isNotEmpty) {
        _moveMapToAddress(value);
      }
    });

    setState(() {
      _address = value;
      _userSearched = true;
    });
  }

  Future<void> _moveMapToAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final latLng = LatLng(locations[0].latitude, locations[0].longitude);
        setState(() {
          _currentLatLng = latLng;
          _userSearched = true;
          // Update address with the search query if geocoding succeeds
          _address = address;
        });
        mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
        // Optionally fetch more detailed address from coordinates
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
          if (placemarks.isNotEmpty) {
            final place = placemarks[0];
            setState(() {
              // Use more detailed address if available
              _address = "${place.name}, ${place.street}, ${place.locality}, ${place.postalCode}";
            });
          }
        } catch (e) {
          // Keep the search address if reverse geocoding fails
        }
      }
    } catch (e) {
      debugPrint("Address not found: $e");
      // Keep the search text even if geocoding fails
    }
  }

  void _onConfirm() {
    Navigator.pop(context, {
      "coordinates": _currentLatLng,
      "address": _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentLatLng,
              zoom: 15,
            ),
            onTap: _onMapTap,
            myLocationEnabled: true,
            markers: {
              Marker(
                markerId: const MarkerId('selected-location'),
                position: _currentLatLng,
              ),
            },
          ),
          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search for building, street name",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onChanged: _onSearchChanged,
                      onSubmitted: _moveMapToAddress,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom sheet with address and button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selected Address:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _address,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: widget.isEditing ? "Confirm" : "Next",
                    onPressed: widget.isEditing ? _onConfirm : _onNext,
                    backgroundColor: const Color(0xFFFF6705),
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    if (widget.isEditing) {
      _onConfirm();
      return;
    }
    Navigator.push(
      context,
      SlidePageRoute(
        page: ReviewListingPage(
          imageUrls: widget.imageNames,
          title: widget.title,
          price: widget.price,
          age: widget.yearOfPurchase,
          usage: widget.usage,
          condition: widget.condition,
          description: widget.description,
          pickupLocation: _address,
          brandName: widget.brandName,
          productName: widget.productName,
          selectedCategory: widget.selectedCategory,
          yearOfPurchase: widget.yearOfPurchase,
          latlng: _currentLatLng,
        ),
      ),
    );
  }
}
