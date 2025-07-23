import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({Key? key, required String selectedCategory, required String title, required String price, required String description, required String productName, required String yearOfPurchase, required String brandName, required String usage, required String condition, required List<String> imageNames}) : super(key: key);

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  GoogleMapController? mapController;
  LatLng _currentLatLng = const LatLng(17.385044, 78.486671); // Default to Hyderabad
  String _address = 'Fetching address...';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _address = "${placemark.name}, ${placemark.locality}, ${placemark.postalCode}";
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Unable to fetch address';
      });
    }
  }

  void _onMapTap(LatLng position) {
    _updatePosition(position);
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
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _currentLatLng,
                zoom: 15,
              ),
              onTap: _onMapTap,
              markers: {
                Marker(
                  markerId: const MarkerId('selected-location'),
                  position: _currentLatLng,
                ),
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Selected Address:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_address),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onConfirm,
                    child: const Text("Confirm Location"),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
