import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../screens/profile/address/address_response.dart';

/// Service to manage user's location preference
/// Handles: Current GPS location, saved addresses, and "Other" location
class LocationService {
  static const String _selectedLocationLatKey = 'selected_location_lat';
  static const String _selectedLocationLngKey = 'selected_location_lng';
  static const String _selectedLocationAddressKey = 'selected_location_address';
  static const String _selectedLocationTypeKey = 'selected_location_type'; // 'other', 'saved', 'current'
  static const String _selectedLocationAddressIdKey = 'selected_location_address_id';
  static const String _selectedLocationAddressLabelKey = 'selected_location_address_label';

  /// Distance threshold for matching current location with saved addresses (in meters)
  static const double _matchThresholdMeters = 100.0;

  /// Get user's preferred location for product fetching/search
  /// Priority: 1. Selected "Other" location, 2. Current GPS, 3. Matched saved address, 4. Default saved address
  static Future<LocationData?> getPreferredLocation() async {
    // 1. Check for selected "Other" location (highest priority)
    final otherLocation = await _getOtherLocation();
    if (otherLocation != null) {
      return otherLocation;
    }

    // 2. Try to get current GPS location
    Position? currentPosition;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || 
            permission == LocationPermission.always) {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
        }
      }
    } catch (e) {
      debugPrint('LocationService: Error getting current location: $e');
    }

    // 3. If we have current location, check if it matches a saved address
    if (currentPosition != null) {
      final matchedAddress = await _matchCurrentLocationWithSavedAddress(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      
      if (matchedAddress != null) {
        // Return matched saved address
        // Use matched address coordinates if available, otherwise use current position
        final lat = matchedAddress.lat ?? currentPosition.latitude;
        final lng = matchedAddress.lng ?? currentPosition.longitude;
        
        return LocationData(
          lat: lat,
          lng: lng,
          address: matchedAddress.address,
          addressLabel: matchedAddress.label,
          addressId: matchedAddress.id,
          type: LocationType.savedAddress,
        );
      }

      // 4. Current location doesn't match saved address - use current location
      final humanReadableAddress = await _reverseGeocode(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      
      return LocationData(
        lat: currentPosition.latitude,
        lng: currentPosition.longitude,
        address: humanReadableAddress,
        type: LocationType.currentLocation,
      );
    }

    // 5. No GPS permission - fallback to default saved address
    final defaultAddress = await _getDefaultSavedAddress();
    if (defaultAddress != null) {
      // If address has coordinates, use them; otherwise geocode the address string
      if (defaultAddress.lat != null && defaultAddress.lng != null) {
        return LocationData(
          lat: defaultAddress.lat!,
          lng: defaultAddress.lng!,
          address: defaultAddress.address,
          addressLabel: defaultAddress.label,
          addressId: defaultAddress.id,
          type: LocationType.savedAddress,
        );
      } else {
        // Address doesn't have coordinates - geocode it
        try {
          List<Location> locations = await locationFromAddress(defaultAddress.address);
          if (locations.isNotEmpty) {
            final lat = locations[0].latitude;
            final lng = locations[0].longitude;
            final humanReadableAddress = await _reverseGeocode(lat, lng);
            
            return LocationData(
              lat: lat,
              lng: lng,
              address: humanReadableAddress,
              addressLabel: defaultAddress.label,
              addressId: defaultAddress.id,
              type: LocationType.savedAddress,
            );
          }
        } catch (e) {
          debugPrint('LocationService: Error geocoding default address: $e');
        }
      }
    }

    return null;
  }

  /// Save "Other" location (temporary, not saved to backend)
  static Future<void> saveOtherLocation({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_selectedLocationLatKey, lat);
      await prefs.setDouble(_selectedLocationLngKey, lng);
      await prefs.setString(_selectedLocationAddressKey, address);
      await prefs.setString(_selectedLocationTypeKey, 'other');
      debugPrint('LocationService: Saved other location: $address');
    } catch (e) {
      debugPrint('LocationService: Error saving other location: $e');
    }
  }

  /// Clear "Other" location (revert to normal flow)
  static Future<void> clearOtherLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedLocationLatKey);
      await prefs.remove(_selectedLocationLngKey);
      await prefs.remove(_selectedLocationAddressKey);
      await prefs.remove(_selectedLocationTypeKey);
      await prefs.remove(_selectedLocationAddressIdKey);
      await prefs.remove(_selectedLocationAddressLabelKey);
      debugPrint('LocationService: Cleared other location');
    } catch (e) {
      debugPrint('LocationService: Error clearing other location: $e');
    }
  }

  /// Get "Other" location from SharedPreferences
  static Future<LocationData?> _getOtherLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_selectedLocationLatKey);
      final lng = prefs.getDouble(_selectedLocationLngKey);
      final address = prefs.getString(_selectedLocationAddressKey);
      final type = prefs.getString(_selectedLocationTypeKey);

      if (lat != null && lng != null && address != null && type == 'other') {
        return LocationData(
          lat: lat,
          lng: lng,
          address: address,
          type: LocationType.other,
        );
      }
    } catch (e) {
      debugPrint('LocationService: Error getting other location: $e');
    }
    return null;
  }

  /// Match current GPS location with saved addresses
  static Future<Address?> _matchCurrentLocationWithSavedAddress(
    double currentLat,
    double currentLng,
  ) async {
    try {
      final savedAddresses = await _fetchSavedAddresses();
      
      for (final address in savedAddresses) {
        if (address.lat != null && address.lng != null) {
          final distance = Geolocator.distanceBetween(
            currentLat,
            currentLng,
            address.lat!,
            address.lng!,
          );
          
          if (distance <= _matchThresholdMeters) {
            debugPrint('LocationService: Matched current location with saved address: ${address.label}');
            return address;
          }
        }
      }
    } catch (e) {
      debugPrint('LocationService: Error matching location: $e');
    }
    return null;
  }

  /// Get default saved address (home address)
  static Future<Address?> _getDefaultSavedAddress() async {
    try {
      final savedAddresses = await _fetchSavedAddresses();
      if (savedAddresses.isEmpty) return null;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return savedAddresses.first;

      // Try to get default address ID from API
      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/user/get-address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final defaultAddressId = data['defaultAddressId'] as String?;
        
        if (defaultAddressId != null && defaultAddressId.isNotEmpty) {
          final defaultAddress = savedAddresses.firstWhere(
            (addr) => addr.id == defaultAddressId,
            orElse: () => savedAddresses.first,
          );
          return defaultAddress;
        }
      }

      // Fallback to first address
      return savedAddresses.first;
    } catch (e) {
      debugPrint('LocationService: Error getting default address: $e');
      return null;
    }
  }

  /// Fetch all saved addresses from API
  static Future<List<Address>> _fetchSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

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
        return addressResponse.addresses;
      }
    } catch (e) {
      debugPrint('LocationService: Error fetching saved addresses: $e');
    }
    return [];
  }

  /// Reverse geocode coordinates to human-readable address
  static Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        // Format similar to SelectLocationPage
        if (place.street != null && place.street!.isNotEmpty) {
          return "${place.name}, ${place.street}, ${place.locality}, ${place.postalCode}";
        } else {
          return "${place.name}, ${place.locality}, ${place.postalCode}";
        }
      }
    } catch (e) {
      debugPrint('LocationService: Error reverse geocoding: $e');
    }
    return 'Location unavailable';
  }
}

/// Location data model
class LocationData {
  final double lat;
  final double lng;
  final String address;
  final LocationType type;
  final String? addressLabel; // For saved addresses (e.g., "HOME")
  final String? addressId; // For saved addresses

  LocationData({
    required this.lat,
    required this.lng,
    required this.address,
    required this.type,
    this.addressLabel,
    this.addressId,
  });
}

/// Location type enum
enum LocationType {
  other, // User selected "Other" location
  currentLocation, // Current GPS location
  savedAddress, // Matched or default saved address
}
