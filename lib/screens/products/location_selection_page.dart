import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/custom_appbar.dart';
import '../../app.dart'; // For SlidePageRoute
import '../profile/address/address_response.dart';
import '../../services/location_service.dart';

/// Page for selecting location from saved addresses or "Other" option
class LocationSelectionPage extends StatefulWidget {
  const LocationSelectionPage({super.key});

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  List<Address> _savedAddresses = [];
  String? _defaultAddressId;
  String? _selectedAddressId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedAddresses();
  }

  Future<void> _fetchSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/user/get-address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addressResponse = AddressResponse.fromJson(data);
        
        setState(() {
          _savedAddresses = addressResponse.addresses;
          _defaultAddressId = addressResponse.defaultAddressId;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('LocationSelectionPage: Error fetching addresses: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSavedAddressSelected(Address address) async {
    // If address has coordinates, use them directly
    if (address.lat != null && address.lng != null) {
      // Reverse geocode to get human-readable address (in case address text is outdated)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          address.lat!,
          address.lng!,
        );
        String humanReadableAddress = address.address; // Default to stored address
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          if (place.street != null && place.street!.isNotEmpty) {
            humanReadableAddress = "${place.name}, ${place.street}, ${place.locality}, ${place.postalCode}";
          } else {
            humanReadableAddress = "${place.name}, ${place.locality}, ${place.postalCode}";
          }
        }
        
        // Save to LocationService as "other" type (temporary location)
        await LocationService.saveOtherLocation(
          lat: address.lat!,
          lng: address.lng!,
          address: humanReadableAddress,
        );
      } catch (e) {
        debugPrint('LocationSelectionPage: Error reverse geocoding: $e');
        // Use stored address if reverse geocoding fails
        await LocationService.saveOtherLocation(
          lat: address.lat!,
          lng: address.lng!,
          address: address.address,
        );
      }
    } else {
      // Address doesn't have coordinates - geocode the address string
      try {
        List<Location> locations = await locationFromAddress(address.address);
        if (locations.isNotEmpty) {
          final lat = locations[0].latitude;
          final lng = locations[0].longitude;
          
          // Reverse geocode to get formatted address
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
          String humanReadableAddress = address.address;
          if (placemarks.isNotEmpty) {
            final place = placemarks[0];
            if (place.street != null && place.street!.isNotEmpty) {
              humanReadableAddress = "${place.name}, ${place.street}, ${place.locality}, ${place.postalCode}";
            } else {
              humanReadableAddress = "${place.name}, ${place.locality}, ${place.postalCode}";
            }
          }
          
          await LocationService.saveOtherLocation(
            lat: lat,
            lng: lng,
            address: humanReadableAddress,
          );
        } else {
          // Geocoding failed - show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to find location for this address'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('LocationSelectionPage: Error geocoding address: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error processing address'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate location was selected
    }
  }

  Future<void> _onOtherSelected() async {
    // Open map (reuse SelectLocationPage but without product listing context)
    // We'll create a simplified version or reuse the existing one
    final result = await Navigator.push(
      context,
      SlidePageRoute(
        page: SelectLocationPageForLocationSelection(),
      ),
    );

    if (result != null && result is Map) {
      final coordinates = result['coordinates'] as LatLng;
      final address = result['address'] as String;

      // Save to LocationService
      await LocationService.saveOtherLocation(
        lat: coordinates.latitude,
        lng: coordinates.longitude,
        address: address,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate location was selected
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Select Location"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Saved addresses list
                if (_savedAddresses.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Saved Addresses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _savedAddresses.length + 1, // +1 for "Other" option
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        // Show "Other" option at the end
                        if (index == _savedAddresses.length) {
                          return RadioListTile<String>(
                            value: 'other',
                            groupValue: _selectedAddressId,
                            onChanged: (value) {
                              setState(() => _selectedAddressId = value);
                              _onOtherSelected();
                            },
                            title: const Text(
                              'Other',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Search and select a location on map',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          );
                        }
                        
                        // Show saved address
                        final address = _savedAddresses[index];
                        final isDefault = address.id == _defaultAddressId;

                        return RadioListTile<String>(
                          value: address.id,
                          groupValue: _selectedAddressId,
                          onChanged: (value) {
                            setState(() => _selectedAddressId = value);
                            _onSavedAddressSelected(address);
                          },
                          title: Text(
                            address.label[0].toUpperCase() + address.label.substring(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            address.address,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          secondary: isDefault
                              ? const Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFF6705),
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // No saved addresses - show "Other" option only
                  Expanded(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Saved Addresses',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No saved addresses found.\nAdd addresses from Settings.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: RadioListTile<String>(
                            value: 'other',
                            groupValue: _selectedAddressId,
                            onChanged: (value) {
                              setState(() => _selectedAddressId = value);
                              _onOtherSelected();
                            },
                            title: const Text(
                              'Other',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Search and select a location on map',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Simplified SelectLocationPage for location selection (without product listing context)
class SelectLocationPageForLocationSelection extends StatefulWidget {
  const SelectLocationPageForLocationSelection({super.key});

  @override
  State<SelectLocationPageForLocationSelection> createState() =>
      _SelectLocationPageForLocationSelectionState();
}

class _SelectLocationPageForLocationSelectionState
    extends State<SelectLocationPageForLocationSelection> {
  GoogleMapController? mapController;
  LatLng? _currentLatLng;
  String _address = 'Fetching address...';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _userSearched = false;
  bool _isLoading = true;

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

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _updatePosition(LatLng(position.latitude, position.longitude));
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _updatePosition(LatLng position) {
    setState(() {
      _currentLatLng = position;
      _isLoading = false;
    });
    _fetchAddress(position);
    if (mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  Future<void> _fetchAddress(LatLng position) async {
    if (_userSearched) return;

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
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
      _searchController.clear();
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
          _address = address;
        });
        mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
        try {
          List<Placemark> placemarks =
              await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
          if (placemarks.isNotEmpty) {
            final place = placemarks[0];
            setState(() {
              _address =
                  "${place.name}, ${place.street}, ${place.locality}, ${place.postalCode}";
            });
          }
        } catch (e) {
          // Keep the search address if reverse geocoding fails
        }
      }
    } catch (e) {
      debugPrint("Address not found: $e");
    }
  }

  void _onConfirm() {
    if (_currentLatLng == null) return;
    Navigator.pop(context, {
      "coordinates": _currentLatLng!,
      "address": _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentLatLng == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                          'Unable to fetch your location. Please enable location services and try again.'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _getCurrentLocation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) {
                        mapController = controller;
                        if (_currentLatLng != null) {
                          controller.animateCamera(
                              CameraUpdate.newLatLng(_currentLatLng!));
                        }
                      },
                      initialCameraPosition: CameraPosition(
                        target: _currentLatLng!,
                        zoom: 15,
                      ),
                      onTap: _onMapTap,
                      myLocationEnabled: true,
                      markers: {
                        Marker(
                          markerId: const MarkerId('selected-location'),
                          position: _currentLatLng!,
                        ),
                      },
                    ),
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
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Selected Address:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
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
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _onConfirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6705),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Use this location'),
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
}
