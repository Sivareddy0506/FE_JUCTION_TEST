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
      debugPrint('PlacesAutocompleteService: Using cached API key (length: ${_cachedApiKey!.length})');
      return _cachedApiKey;
    }

    try {
      final String? apiKey = await _channel.invokeMethod<String>('getGoogleMapsApiKey');
      if (apiKey != null && apiKey.isNotEmpty) {
        _cachedApiKey = apiKey;
        debugPrint('PlacesAutocompleteService: ✅ API key retrieved successfully (length: ${apiKey.length}, prefix: ${apiKey.substring(0, apiKey.length > 10 ? 10 : apiKey.length)}...)');
        return apiKey;
      } else {
        debugPrint('PlacesAutocompleteService: ❌ API key is null or empty');
        return null;
      }
    } catch (e) {
      debugPrint('PlacesAutocompleteService: ❌ Failed to get API key: $e');
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

      debugPrint('PlacesAutocompleteService: Making request to: ${url.toString().replaceAll(apiKey, '***HIDDEN***')}');
      final response = await http.get(url);
      
      debugPrint('PlacesAutocompleteService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('PlacesAutocompleteService: API response status: ${data['status']}');
        
        if (data['status'] == 'OK' && data['predictions'] != null) {
          return (data['predictions'] as List)
              .map((prediction) => PlacePrediction.fromJson(prediction))
              .toList();
        } else if (data['status'] == 'REQUEST_DENIED') {
          final errorMessage = data['error_message'] ?? 'No error message provided';
          debugPrint('PlacesAutocompleteService: ❌ API request denied');
          debugPrint('PlacesAutocompleteService: Error message: $errorMessage');
          debugPrint('PlacesAutocompleteService: Full response: ${response.body}');
        } else {
          debugPrint('PlacesAutocompleteService: Unexpected status: ${data['status']}');
          debugPrint('PlacesAutocompleteService: Full response: ${response.body}');
        }
      } else {
        debugPrint('PlacesAutocompleteService: ❌ HTTP error: ${response.statusCode}');
        debugPrint('PlacesAutocompleteService: Response body: ${response.body}');
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

      debugPrint('PlacesAutocompleteService: Making place details request to: ${url.toString().replaceAll(apiKey, '***HIDDEN***')}');
      final response = await http.get(url);
      
      debugPrint('PlacesAutocompleteService: Place details response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('PlacesAutocompleteService: Place details API response status: ${data['status']}');
        
        if (data['status'] == 'OK' && data['result'] != null) {
          return PlaceDetails.fromJson(data['result']);
        } else if (data['status'] == 'REQUEST_DENIED') {
          final errorMessage = data['error_message'] ?? 'No error message provided';
          debugPrint('PlacesAutocompleteService: ❌ Place details API request denied');
          debugPrint('PlacesAutocompleteService: Error message: $errorMessage');
          debugPrint('PlacesAutocompleteService: Full response: ${response.body}');
        } else {
          debugPrint('PlacesAutocompleteService: Unexpected status: ${data['status']}');
          debugPrint('PlacesAutocompleteService: Full response: ${response.body}');
        }
      } else {
        debugPrint('PlacesAutocompleteService: ❌ HTTP error: ${response.statusCode}');
        debugPrint('PlacesAutocompleteService: Response body: ${response.body}');
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
