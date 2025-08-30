import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class SearchService {
  static const String baseUrl = 'https://api.junctionverse.com/user';
  
  // Cache for user location to avoid repeated requests
  static Position? _cachedLocation;
  static DateTime? _lastLocationFetch;
  static const Duration _locationCacheDuration = Duration(minutes: 5);

  /// Get user's current location with fallback to saved location
  static Future<Map<String, double>?> getUserLocation() async {
    try {
      // Check if we have a recent cached location
      if (_cachedLocation != null && _lastLocationFetch != null) {
        final timeSinceLastFetch = DateTime.now().difference(_lastLocationFetch!);
        if (timeSinceLastFetch < _locationCacheDuration) {
          return {
            'lat': _cachedLocation!.latitude,
            'lng': _cachedLocation!.longitude,
          };
        }
      }

      // Try to get current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Cache the location
      _cachedLocation = position;
      _lastLocationFetch = DateTime.now();

      return {
        'lat': position.latitude,
        'lng': position.longitude,
      };
    } catch (e) {
      print('Error getting current location: $e');
      
      // Fallback to saved location from user profile
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedLat = prefs.getDouble('user_lat');
        final savedLng = prefs.getDouble('user_lng');
        
        if (savedLat != null && savedLng != null) {
          print('Using saved location: $savedLat, $savedLng');
          return {
            'lat': savedLat,
            'lng': savedLng,
          };
        }
      } catch (fallbackError) {
        print('Error getting saved location: $fallbackError');
      }
      
      return null;
    }
  }

  /// Save user location for future use
  static Future<void> saveUserLocation(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('user_lat', lat);
      await prefs.setDouble('user_lng', lng);
      
      // Update cache
      _cachedLocation = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      _lastLocationFetch = DateTime.now();
    } catch (e) {
      print('Error saving user location: $e');
    }
  }

  /// Enhanced search with filters and location
  static Future<SearchResult> searchProducts({
    String? query,
    String? listingType,
    dynamic category, // Can be String or List<String>
    dynamic condition, // Can be String or List<String>
    String? pickupMethod,
    double? minPrice,
    double? maxPrice,
    String? sortBy = 'Distance',
    int? limit = 50,
    double? radius = 50,
  }) async {
    try {
      // Get user location (required for search)
      final location = await getUserLocation();
      if (location == null) {
        throw Exception('Unable to get user location. Please enable location services.');
      }

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null || token.isEmpty) {
        print('SearchService: No auth token found');
        throw Exception('Authentication required. Please log in again.');
      }
      
      print('SearchService: Token found, length: ${token.length}');

      // Build query parameters
      final queryParams = <String, String>{
        'userLat': location['lat'].toString(),
        'userLng': location['lng'].toString(),
        'radius': radius.toString(),
        'sortBy': sortBy ?? 'Distance',
        'limit': limit.toString(),
      };

      // Add optional parameters
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      if (listingType != null && listingType != 'All') {
        queryParams['listingType'] = listingType;
      }
      if (category != null && category != 'All') {
        // Handle both string and list formats
        if (category is List<String>) {
          queryParams['category'] = category.join(',');
        } else if (category is String) {
          queryParams['category'] = category;
        }
      }
      if (condition != null && condition != 'All') {
        // Handle both string and list formats
        if (condition is List<String>) {
          queryParams['condition'] = condition.join(',');
        } else if (condition is String) {
          queryParams['condition'] = condition;
        }
      }
      if (pickupMethod != null && pickupMethod != 'All') {
        queryParams['pickupMethod'] = pickupMethod;
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toString();
      }

      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl/search/current').replace(queryParameters: queryParams);

      print('Search API URL: $uri');

      // Make API call
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('SearchService: API Response Status: ${response.statusCode}');
      print('SearchService: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
         final data = json.decode(response.body);
         
         // Parse products (without distance fields)
         final List<Product> products = (data['products'] as List)
             .map((productData) => Product.fromJson(productData))
             .toList();

         // Extract distances separately from the API response
         Map<String, double>? productDistances;
         if (data['products'] is List) {
           productDistances = {};
           for (int i = 0; i < data['products'].length; i++) {
             final productData = data['products'][i];
             final productId = productData['id'] ?? productData['_id'];
             final distance = productData['distance']?.toDouble();
             if (productId != null && distance != null) {
               productDistances[productId] = distance;
             }
           }
         }

         return SearchResult(
           products: products,
           totalResults: data['totalResults'] ?? products.length,
           userLocation: location,
           searchRadius: radius,
           appliedFilters: data['appliedFilters'] ?? {},
           productDistances: productDistances,
         );
      } else if (response.statusCode == 401) {
        print('SearchService: Authentication failed - 401 Unauthorized');
        throw Exception('Authentication failed. Please log in again.');
      } else if (response.statusCode == 403) {
        print('SearchService: Access forbidden - 403 Forbidden');
        throw Exception('Access denied. Please check your permissions.');
      } else {
        final errorData = json.decode(response.body);
        print('SearchService: API Error ${response.statusCode}: ${response.body}');
        throw Exception(errorData['error'] ?? 'Search failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('SearchService: Error during search: $e');
      if (e.toString().contains('Authentication')) {
        rethrow; // Re-throw authentication errors as-is
      } else {
        throw Exception('Search failed: $e');
      }
    }
  }

  /// Search with only filters (no query)
  static Future<SearchResult> searchWithFilters({
    required Map<String, dynamic> filters,
    String? sortBy = 'Distance',
    int? limit = 50,
    double? radius = 50,
  }) async {
    return searchProducts(
      listingType: filters['listingType'],
      category: filters['category'],
      condition: filters['condition'],
      pickupMethod: filters['pickupMethod'],
      minPrice: filters['minPrice']?.toDouble(),
      maxPrice: filters['maxPrice']?.toDouble(),
      sortBy: sortBy,
      limit: limit,
      radius: radius,
    );
  }

  /// Search with query and filters
  static Future<SearchResult> searchWithQueryAndFilters({
    required String query,
    required Map<String, dynamic> filters,
    String? sortBy = 'Distance',
    int? limit = 50,
    double? radius = 50,
  }) async {
    return searchProducts(
      query: query,
      listingType: filters['listingType'],
      category: filters['category'],
      condition: filters['condition'],
      pickupMethod: filters['pickupMethod'],
      minPrice: filters['minPrice'],
      maxPrice: filters['maxPrice'],
      sortBy: sortBy,
      limit: limit,
      radius: radius,
    );
  }

  /// Clear location cache (useful for testing or when location changes)
  static void clearLocationCache() {
    _cachedLocation = null;
    _lastLocationFetch = null;
  }
}

/// Search result model
class SearchResult {
  final List<Product> products;
  final int totalResults;
  final Map<String, double>? userLocation;
  final double? searchRadius;
  final Map<String, dynamic> appliedFilters;
  final Map<String, double>? productDistances; // Store distances separately

  SearchResult({
    required this.products,
    required this.totalResults,
    this.userLocation,
    this.searchRadius,
    required this.appliedFilters,
    this.productDistances,
  });

  bool get hasResults => products.isNotEmpty;
  bool get hasLocation => userLocation != null;
  
  /// Get distance for a specific product
  double? getDistanceForProduct(String productId) {
    return productDistances?[productId];
  }
  
  /// Get formatted distance text for a product
  String? getDistanceTextForProduct(String productId) {
    final distance = getDistanceForProduct(productId);
    if (distance == null) return null;
    
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    } else if (distance < 10) {
      return '${distance.toStringAsFixed(1)}km';
    } else {
      return '${distance.round()}km';
    }
  }
}
