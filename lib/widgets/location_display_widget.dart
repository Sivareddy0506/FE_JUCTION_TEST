import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../screens/products/location_selection_page.dart';
import '../app.dart'; // For SlidePageRoute

/// Widget to display user's current location on home page
/// Shows address with tag if matched to saved address, or human-readable address
class LocationDisplayWidget extends StatefulWidget {
  const LocationDisplayWidget({super.key});

  @override
  State<LocationDisplayWidget> createState() => _LocationDisplayWidgetState();
}

class _LocationDisplayWidgetState extends State<LocationDisplayWidget> {
  LocationData? _currentLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() => _isLoading = true);
    try {
      final location = await LocationService.getPreferredLocation();
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('LocationDisplayWidget: Error loading location: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onLocationTap() async {
    // Navigate to location selection page
    final result = await Navigator.push(
      context,
      SlidePageRoute(
        page: const LocationSelectionPage(),
      ),
    );

    // Reload location if user made a selection
    if (result == true) {
      _loadLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Loading location...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_currentLocation == null) {
      return InkWell(
        onTap: _onLocationTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Tap to set location',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    // Format display text
    String displayText;
    if (_currentLocation!.addressLabel != null) {
      // Show "TAG - Address" format for saved addresses
      displayText = "${_currentLocation!.addressLabel!.toUpperCase()} - ${_currentLocation!.address}";
    } else {
      // Show just address for current location or other location
      displayText = _currentLocation!.address;
    }

    return InkWell(
      onTap: _onLocationTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: Color(0xFFFF6705)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
