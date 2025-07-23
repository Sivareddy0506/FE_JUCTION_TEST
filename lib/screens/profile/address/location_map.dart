import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/custom_appbar.dart';
import 'add_more_details.dart'; // import the new page

class LocationMapPage extends StatefulWidget {
  final String? initialAddress;

  const LocationMapPage({super.key, this.initialAddress});

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  String _selectedAddress = 'Fetching address...';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _userSearched = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _selectedAddress = widget.initialAddress!;
      _searchController.text = widget.initialAddress!;
      _userSearched = true;
      _getCurrentLocation();
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      if (!_userSearched) {
        _getAddressFromLatLng(_currentLatLng!);
      }
    } catch (e) {
      print("Location error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty && !_userSearched) {
        final place = placemarks[0];
        final address =
            "${place.name}, ${place.street}, ${place.locality}, ${place.postalCode}";
        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      print("Reverse geocoding failed: $e");
    }
  }

  void _onMapMoved(CameraPosition position) {
    _currentLatLng = position.target;
  }

  void _onMapIdle() {
    if (!_userSearched && _currentLatLng != null) {
      _getAddressFromLatLng(_currentLatLng!);
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (value.isNotEmpty) {
        _moveMapToAddress(value);
      }
    });

    setState(() {
      _selectedAddress = value;
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
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      }
    } catch (e) {
      print("Address not found: $e");
    }
  }

  void _confirmLocation() {
    if (_currentLatLng == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMoreDetailsPage(
          address: _selectedAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Select Location"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLatLng!,
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  onMapCreated: (controller) => _mapController = controller,
                  onCameraMove: _onMapMoved,
                  onCameraIdle: _onMapIdle,
                  onTap: (_) {
                    if (!_userSearched) {
                      _getAddressFromLatLng(_currentLatLng!);
                    }
                  },
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 32),
                    child: Image(
                      image: AssetImage('assets/locpincolor.png'),
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Image(
                          image: AssetImage('assets/MagnifyingGlass.png'),
                          width: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Search for building, street name",
                            ),
                            onChanged: _onSearchChanged,
                            onSubmitted: _moveMapToAddress,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selected Area",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAddress,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: "Confirm Location",
                          onPressed: _confirmLocation,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
