import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Cache for storing geocoded locations to minimize API calls
class LocationCache {
  static final Map<String, String> _cache = {};
  static const Duration _cacheExpiry = Duration(hours: 24);
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Get cached location if available and not expired
  static String? get(double lat, double lng) {
    final key = _generateKey(lat, lng);
    final timestamp = _cacheTimestamps[key];
    
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < _cacheExpiry) {
      return _cache[key];
    }
    
    // Remove expired cache entry
    if (timestamp != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    return null;
  }
  
  /// Store location in cache
  static void set(double lat, double lng, String location) {
    final key = _generateKey(lat, lng);
    _cache[key] = location;
    _cacheTimestamps[key] = DateTime.now();
  }
  
  /// Generate cache key from coordinates (rounded to 4 decimal places)
  static String _generateKey(double lat, double lng) {
    return '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
  }
  
  /// Clear all cached locations
  static void clear() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
  
  /// Get cache statistics (useful for debugging)
  static Map<String, dynamic> getStats() {
    return {
      'totalEntries': _cache.length,
      'cacheSize': _cache.length,
    };
  }
}

/// Reverse geocode coordinates to location name using Nominatim (OpenStreetMap)
/// Returns format: "Neighborhood, City" or "City, State" depending on availability
Future<String> getAddressFromLatLng(double lat, double lng) async {
  // Check cache first
  final cached = LocationCache.get(lat, lng);
  if (cached != null) {
    debugPrint('Location cache hit for ($lat, $lng): $cached');
    return cached;
  }
  
  try {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?'
      'format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'
    );
    
    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'FlutterApp/1.0', // Required by Nominatim policy
        'Accept-Language': 'en', // Get results in English
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Geocoding request timed out');
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Check if we got valid data
      if (data['error'] != null) {
        debugPrint('Nominatim error: ${data['error']}');
        return 'Location unavailable';
      }
      
      final address = data['address'];
      if (address == null) {
        return 'Location unavailable';
      }
      
      // Extract neighborhood/sublocality, city, and state
      final neighborhood = address['neighbourhood'] ?? 
                          address['suburb'] ?? 
                          address['residential'] ??
                          address['quarter'] ?? '';
      
      final city = address['city'] ?? 
                   address['town'] ?? 
                   address['village'] ?? 
                   address['municipality'] ?? '';
      
      final state = address['state'] ?? 
                    address['province'] ?? 
                    address['region'] ?? '';
      
      String result;
      
      // Priority 1: Neighborhood + City (e.g., "Indira Nagar, Bengaluru")
      if (neighborhood.isNotEmpty && city.isNotEmpty) {
        result = '$neighborhood, $city';
      }
      // Priority 2: City + State (e.g., "Bengaluru, Karnataka")
      else if (city.isNotEmpty && state.isNotEmpty) {
        result = '$city, $state';
      }
      // Priority 3: Just City
      else if (city.isNotEmpty) {
        result = city;
      }
      // Priority 4: Just State
      else if (state.isNotEmpty) {
        result = state;
      }
      // Fallback: Country
      else {
        result = address['country'] ?? 'Location unavailable';
      }
      
      // Cache the successful result
      if (result != 'Location unavailable') {
        LocationCache.set(lat, lng, result);
        debugPrint('Location cached for ($lat, $lng): $result');
      }
      
      return result;
      
    } else if (response.statusCode == 429) {
      // Rate limit exceeded
      debugPrint('Nominatim rate limit exceeded');
      return 'Location unavailable';
    } else {
      debugPrint('Nominatim returned status: ${response.statusCode}');
      return 'Location unavailable';
    }
    
  } catch (e) {
    debugPrint('Error reverse geocoding ($lat, $lng): $e');
    return 'Location unavailable';
  }
}

/// Batch geocode multiple coordinates (with rate limiting to respect Nominatim policy)
/// Nominatim allows 1 request per second for free usage
Future<Map<String, String>> batchGeocodeLocations(
  List<Map<String, double>> coordinates,
) async {
  final results = <String, String>{};
  
  for (var i = 0; i < coordinates.length; i++) {
    final coord = coordinates[i];
    final lat = coord['lat']!;
    final lng = coord['lng']!;
    final key = '${lat}_$lng';
    
    results[key] = await getAddressFromLatLng(lat, lng);
    
    // Rate limiting: wait 1 second between requests (Nominatim policy)
    if (i < coordinates.length - 1) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }
  
  return results;
}