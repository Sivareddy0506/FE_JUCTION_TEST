import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:junction/screens/profile/address/address_response.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/custom_appbar.dart';
import 'add_more_details.dart'; // import the new page
import '../../../app.dart'; // For SlidePageRoute
import '../../../services/places_autocomplete_service.dart';

class LocationMapPage extends StatefulWidget {
  final Address? initialAddress;
  final bool isItFromEdit;

  const LocationMapPage({super.key, this.initialAddress, required this.isItFromEdit});

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  String _selectedAddress = 'Fetching address...';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  Timer? _autocompleteDebounce;
  bool _userSearched = false;
  bool _isLoading = true;
  List<PlacePrediction> _autocompletePredictions = [];
  bool _showAutocompleteDropdown = false;
  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _getCurrentLocation();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 3), () {
          _moveMapToAddress(widget.initialAddress!.address);
          setState(() {
            _selectedAddress = widget.initialAddress!.address;
            _searchController.text = widget.initialAddress!.address;
          });
        });
      });
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _autocompleteDebounce?.cancel();
    _searchFocusNode.dispose();
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
    // Cancel previous debounce timers
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (_autocompleteDebounce?.isActive ?? false) _autocompleteDebounce!.cancel();

    setState(() {
      _selectedAddress = value;
      _userSearched = true;
      if (value.isEmpty) {
        _autocompletePredictions = [];
        _showAutocompleteDropdown = false;
      }
    });

    // Fetch autocomplete predictions as user types
    if (value.isNotEmpty) {
      _autocompleteDebounce = Timer(const Duration(milliseconds: 300), () {
        _fetchAutocompletePredictions(value);
      });
    }

    // Fallback to geocoding if user submits or after delay (for backward compatibility)
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      if (value.isNotEmpty && _autocompletePredictions.isEmpty) {
        _moveMapToAddress(value);
      }
    });
  }

  Future<void> _fetchAutocompletePredictions(String input) async {
    final predictions = await PlacesAutocompleteService.getPredictions(input);
    if (mounted) {
      setState(() {
        _autocompletePredictions = predictions;
        _showAutocompleteDropdown = predictions.isNotEmpty && input.isNotEmpty;
      });
    }
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    setState(() {
      _searchController.text = prediction.description;
      _showAutocompleteDropdown = false;
      _autocompletePredictions = [];
    });
    _searchFocusNode.unfocus();

    // Get place details including coordinates
    final placeDetails = await PlacesAutocompleteService.getPlaceDetails(prediction.placeId);
    if (placeDetails != null && mounted) {
      setState(() {
        _currentLatLng = placeDetails.location;
        _selectedAddress = placeDetails.formattedAddress.isNotEmpty
            ? placeDetails.formattedAddress
            : prediction.description;
        _userSearched = true;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(placeDetails.location));
    } else {
      // Fallback to geocoding if Places API fails
      _moveMapToAddress(prediction.description);
    }
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
      SlidePageRoute(
        page: AddMoreDetailsPage(
          id: widget.isItFromEdit? widget.initialAddress!.id :"",
          address: _selectedAddress,
          isEditable: widget.isItFromEdit,
          latitude: _currentLatLng!.latitude,
          longitude: _currentLatLng!.longitude,
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
          : _currentLatLng == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to fetch your location. Please enable location services and try again.'),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Retry',
                        onPressed: _getCurrentLocation,
                      ),
                    ],
                  ),
                )
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
                    setState(() {
                      _showAutocompleteDropdown = false;
                    });
                    _searchFocusNode.unfocus();
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
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
                                focusNode: _searchFocusNode,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Search for building, street name",
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                                onChanged: _onSearchChanged,
                                onSubmitted: (value) {
                                  if (_autocompletePredictions.isNotEmpty) {
                                    _onPredictionSelected(_autocompletePredictions.first);
                                  } else {
                                    _moveMapToAddress(value);
                                  }
                                },
                                onTap: () {
                                  if (_autocompletePredictions.isNotEmpty) {
                                    setState(() {
                                      _showAutocompleteDropdown = true;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Autocomplete dropdown
                      if (_showAutocompleteDropdown && _autocompletePredictions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _autocompletePredictions.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final prediction = _autocompletePredictions[index];
                              return InkWell(
                                onTap: () => _onPredictionSelected(prediction),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          prediction.description,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
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
