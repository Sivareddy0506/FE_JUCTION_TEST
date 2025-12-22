import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for Google Places Autocomplete API
class PlacesAutocompleteService {
  static const MethodChannel _channel = MethodChannel('com.junction.config');
  static String? _cachedApiKey;

  /// Gets the Google Maps API key from native configuration
  /// Uses platform channel to read from AndroidManifest.xml (Android) or Info.plist (iOS)
  static Future<String?> _getApiKey() async {
    if (_cachedApiKey != null) {
      return _cachedApiKey;
    }

    try {
      final String? apiKey = await _channel.invokeMethod<String>('getGoogleMapsApiKey');
      _cachedApiKey = apiKey;
      return apiKey;
    } catch (e) {
      debugPrint('PlacesAutocompleteService: Failed to get API key: $e');
      return null;
    }
  }
  
  /// Fetches autocomplete predictions for a given input
  /// Returns a list of place predictions with description and place_id
  static Future<List<PlacePrediction>> getPredictions(String input) async {
    if (input.isEmpty) {
      return [];
    }

    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('PlacesAutocompleteService: API key not available');
      return [];
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=$apiKey'
        '&components=country:in' // Restrict to India (optional, remove if you want global results)
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          return (data['predictions'] as List)
              .map((prediction) => PlacePrediction.fromJson(prediction))
              .toList();
        } else if (data['status'] == 'REQUEST_DENIED') {
          debugPrint('PlacesAutocompleteService: API request denied - check API key and Places API enablement');
        }
      }
    } catch (e) {
      debugPrint('PlacesAutocompleteService error: $e');
    }
    
    return [];
  }

  /// Gets place details including coordinates from a place_id
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) {
      return null;
    }

    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('PlacesAutocompleteService: API key not available');
      return null;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$apiKey'
        '&fields=geometry,formatted_address,name'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          return PlaceDetails.fromJson(data['result']);
        } else if (data['status'] == 'REQUEST_DENIED') {
          debugPrint('PlacesAutocompleteService: API request denied - check API key and Places API enablement');
        }
      }
    } catch (e) {
      debugPrint('PlacesAutocompleteService getPlaceDetails error: $e');
    }
    
    return null;
  }
}

class PlacePrediction {
  final String description;
  final String placeId;

  PlacePrediction({
    required this.description,
    required this.placeId,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
    );
  }
}

class PlaceDetails {
  final String formattedAddress;
  final String name;
  final LatLng location;

  PlaceDetails({
    required this.formattedAddress,
    required this.name,
    required this.location,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    
    return PlaceDetails(
      formattedAddress: json['formatted_address'] ?? '',
      name: json['name'] ?? '',
      location: LatLng(
        (location?['lat'] as num?)?.toDouble() ?? 0.0,
        (location?['lng'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }
}
