import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_manager.dart';

/// User Profile data model
class UserProfile {
  final String name;
  final String university;
  final String location;
  final String profileImage;

  UserProfile({
    required this.name,
    required this.university,
    required this.location,
    required this.profileImage,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String extractedLocation = '';

    // Parse the addressJson field
    if (json['addressJson'] != null && json['addressJson'] is List) {
      final addressList = json['addressJson'] as List;

      // Find the "Home" address, fallback to the first address if not found
      final homeAddress = addressList.firstWhere(
        (addr) => addr['label'] == 'Home',
        orElse: () => addressList.isNotEmpty ? addressList[0] : null,
      );

      if (homeAddress != null && homeAddress['address'] != null) {
        extractedLocation = homeAddress['address'];
      }
    }

    return UserProfile(
      name: json['fullName'] ?? 'User',
      university: json['university'] ?? 'University not set',
      location: extractedLocation.isNotEmpty ? extractedLocation : 'Location not set',
      profileImage: json['selfieUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'university': university,
      'location': location,
      'profileImage': profileImage,
    };
  }
}

/// Profile Service for handling profile data with caching
class ProfileService {
  static final CacheManager _cacheManager = CacheManager();
  static const String _baseUrl = 'https://api.junctionverse.com';

  /// Get user profile with caching
  static Future<UserProfile?> getUserProfileWithCache() async {
    // Check cache first
    final cachedProfile = await _cacheManager.getCachedData<UserProfile>(CacheConfig.profileKey);
    if (cachedProfile != null) {
      debugPrint('ProfileService: Returning cached profile data');
      return cachedProfile;
    }

    // Fetch from API if not cached
    final profile = await _fetchUserProfileFromAPI();
    if (profile != null) {
      // Cache the profile data
      await _cacheManager.setCachedData(
        CacheConfig.profileKey,
        profile,
        expiry: CacheConfig.profileExpiry,
      );
      debugPrint('ProfileService: Cached profile data');
    }

    return profile;
  }

  /// Fetch user profile from API
  static Future<UserProfile?> _fetchUserProfileFromAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        debugPrint('ProfileService: No auth token found');
        return null;
      }

      final uri = Uri.parse('$_baseUrl/user/profile');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        return UserProfile.fromJson(user);
      } else {
        debugPrint('ProfileService: API error - ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('ProfileService: Error fetching profile - $e');
      return null;
    }
  }

  /// Update profile cache
  static Future<void> updateProfileCache(UserProfile profile) async {
    await _cacheManager.setCachedData(
      CacheConfig.profileKey,
      profile,
      expiry: CacheConfig.profileExpiry,
    );
    debugPrint('ProfileService: Updated profile cache');
  }

  /// Clear profile cache
  static Future<void> clearProfileCache() async {
    await _cacheManager.invalidateCache(CacheConfig.profileKey);
    debugPrint('ProfileService: Cleared profile cache');
  }

  /// Force refresh profile data
  static Future<UserProfile?> refreshProfileData() async {
    // Clear cache and fetch fresh data
    await clearProfileCache();
    return await getUserProfileWithCache();
  }

  /// Check if profile is cached
  static Future<bool> isProfileCached() async {
    return await _cacheManager.hasCachedData(CacheConfig.profileKey);
  }
}


class ProductClickService {
  static final CacheManager _cacheManager = CacheManager();
  static const String _baseUrl = 'https://api.junctionverse.com';

  /// Fetch unique clicks for a product with caching
  static Future<int> getUniqueClicks(String productId) async {
    final cacheKey = 'uniqueClicks_$productId';

    // Check cache first
    final cachedCount = await _cacheManager.getCachedData<int>(cacheKey);
    if (cachedCount != null) {
      debugPrint('ProductClickService: Returning cached clicks for $productId');
      return cachedCount;
    }

    // Fetch from API if not cached
    final count = await _fetchUniqueClicksFromAPI(productId);
    if (count != null) {
      await _cacheManager.setCachedData(cacheKey, count, expiry: Duration(hours: 1));
      debugPrint('ProductClickService: Cached clicks for $productId -> $count');
      return count;
    }

    return 0;
  }

  /// Force refresh clicks for a product
  static Future<int> refreshUniqueClicks(String productId) async {
    await _cacheManager.invalidateCache('uniqueClicks_$productId');
    return await getUniqueClicks(productId);
  }

  /// Fetch clicks from API
  static Future<int?> _fetchUniqueClicksFromAPI(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      if (token.isEmpty) return 0;

      final uri = Uri.parse('$_baseUrl/history/unique-clicks');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'productId': productId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else {
        debugPrint('ProductClickService: API error ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      debugPrint('ProductClickService: Error fetching clicks -> $e');
      return 0;
    }
  }
}
