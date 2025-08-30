import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Filter state service that manages filter preferences in local storage
/// with automatic 5-minute expiration
class FilterStateService {
  static const String _filterStateKey = 'filter_state';
  static const String _filterStateTimestampKey = 'filter_state_timestamp';
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Save filter state to local storage with timestamp
  static Future<void> saveFilterState(Map<String, dynamic> filterState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString(_filterStateKey, jsonEncode(filterState));
      await prefs.setInt(_filterStateTimestampKey, timestamp);
      
      print('FilterStateService: Filter state saved successfully');
    } catch (e) {
      print('FilterStateService: Error saving filter state: $e');
    }
  }

  /// Get filter state from local storage if not expired
  static Future<Map<String, dynamic>?> getFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if filter state exists
      final filterStateJson = prefs.getString(_filterStateKey);
      final timestamp = prefs.getInt(_filterStateTimestampKey);
      
      if (filterStateJson == null || timestamp == null) {
        print('FilterStateService: No filter state found');
        return null;
      }

      // Check if cache has expired
      final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final timeDifference = now.difference(savedTime);

      if (timeDifference > _cacheExpiry) {
        print('FilterStateService: Filter state expired, clearing cache');
        await clearFilterState();
        return null;
      }

      // Parse and return filter state
      final filterState = jsonDecode(filterStateJson) as Map<String, dynamic>;
      print('FilterStateService: Filter state retrieved successfully');
      return filterState;
    } catch (e) {
      print('FilterStateService: Error retrieving filter state: $e');
      return null;
    }
  }

  /// Clear filter state from local storage
  static Future<void> clearFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_filterStateKey);
      await prefs.remove(_filterStateTimestampKey);
      print('FilterStateService: Filter state cleared successfully');
    } catch (e) {
      print('FilterStateService: Error clearing filter state: $e');
    }
  }

  /// Check if filter state exists and is not expired
  static Future<bool> hasValidFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final filterStateJson = prefs.getString(_filterStateKey);
      final timestamp = prefs.getInt(_filterStateTimestampKey);
      
      if (filterStateJson == null || timestamp == null) {
        return false;
      }

      // Check if cache has expired
      final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final timeDifference = now.difference(savedTime);

      return timeDifference <= _cacheExpiry;
    } catch (e) {
      print('FilterStateService: Error checking filter state validity: $e');
      return false;
    }
  }

  /// Get remaining time until filter state expires
  static Future<Duration?> getRemainingTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_filterStateTimestampKey);
      
      if (timestamp == null) {
        return null;
      }

      final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final timeDifference = now.difference(savedTime);

      if (timeDifference > _cacheExpiry) {
        return Duration.zero;
      }

      return _cacheExpiry - timeDifference;
    } catch (e) {
      print('FilterStateService: Error getting remaining time: $e');
      return null;
    }
  }

  /// Force clear filter state (useful when user exits search page)
  static Future<void> forceClearFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_filterStateKey);
      await prefs.remove(_filterStateTimestampKey);
      print('FilterStateService: Filter state force cleared');
    } catch (e) {
      print('FilterStateService: Error force clearing filter state: $e');
    }
  }

  /// Update specific filter values while preserving others
  static Future<void> updateFilterState(Map<String, dynamic> newFilters) async {
    try {
      final currentState = await getFilterState() ?? {};
      currentState.addAll(newFilters);
      await saveFilterState(currentState);
      print('FilterStateService: Filter state updated successfully');
    } catch (e) {
      print('FilterStateService: Error updating filter state: $e');
    }
  }
}

/// Filter state model for type safety
class FilterState {
  final String? listingType;
  final List<String>? categories;
  final List<String>? conditions;
  final String? pickupMethod;
  final double? minPrice;
  final double? maxPrice;
  final String? sortBy;

  FilterState({
    this.listingType,
    this.categories,
    this.conditions,
    this.pickupMethod,
    this.minPrice,
    this.maxPrice,
    this.sortBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'listingType': listingType,
      'categories': categories,
      'conditions': conditions,
      'pickupMethod': pickupMethod,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'sortBy': sortBy,
    };
  }

  factory FilterState.fromJson(Map<String, dynamic> json) {
    return FilterState(
      listingType: json['listingType'],
      categories: json['categories'] != null 
          ? List<String>.from(json['categories'])
          : null,
      conditions: json['conditions'] != null 
          ? List<String>.from(json['conditions'])
          : null,
      pickupMethod: json['pickupMethod'],
      minPrice: json['minPrice']?.toDouble(),
      maxPrice: json['maxPrice']?.toDouble(),
      sortBy: json['sortBy'],
    );
  }

  /// Convert to the format expected by the filter widget
  Map<String, dynamic> toFilterWidgetFormat() {
    return {
      'listingType': listingType ?? 'All',
      'categories': categories ?? [],
      'conditions': conditions ?? [],
      'pickupMethod': pickupMethod ?? 'All',
      'minPrice': minPrice ?? 0.0,
      'maxPrice': maxPrice ?? 100000.0,
      'sortBy': sortBy ?? 'Distance',
    };
  }
}
