import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AboutSummary {
  final double avgRating;
  final int productsSoldCount;
  final List<Map<String, dynamic>> reviews;
  final Map<String, dynamic>? user;

  AboutSummary({
    required this.avgRating,
    required this.productsSoldCount,
    required this.reviews,
    this.user,
  });
}

class AboutRepository {
  static Future<AboutSummary> fetchAboutData({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final fallbackUserId = prefs.getString('userId');

    final targetUserId = userId ?? fallbackUserId;
    if (targetUserId == null || targetUserId.isEmpty) {
      throw Exception('No userId available for fetching about data');
    }

    final bool isOtherUser = userId != null && userId != fallbackUserId;
    final uri = isOtherUser
        ? Uri.parse('https://api.junctionverse.com/ratings/others/$targetUserId')
        : Uri.parse('https://api.junctionverse.com/ratings/$targetUserId');

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch about data (status ${response.statusCode})');
    }

    final dynamic decoded = json.decode(response.body);
    final Map<String, dynamic> data =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'raw': decoded};

    Map<String, dynamic>? user;
    if (data['user'] is Map<String, dynamic>) {
      user = Map<String, dynamic>.from(data['user'] as Map<String, dynamic>);
    }

    return AboutSummary(
      avgRating: _parseDouble(data['avgRating'] ?? data['averageRating'] ?? data['average']),
      productsSoldCount:
          _parseInt(data['productsSoldCount'] ?? data['productsSold'] ?? data['soldCount']),
      reviews: _normalizeReviews(data['ratings'] ?? data['reviews']),
      user: user,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static List<Map<String, dynamic>> _normalizeReviews(dynamic raw) {
    if (raw is List) {
      return raw.map<Map<String, dynamic>>((item) {
        if (item is Map<String, dynamic>) {
          final normalized = Map<String, dynamic>.from(item);
          if (!normalized.containsKey('comments') && normalized['comment'] != null) {
            normalized['comments'] = normalized['comment'];
          }
          return normalized;
        }
        return {'comments': item.toString(), 'ratedBy': {}};
      }).toList();
    }
    return <Map<String, dynamic>>[];
  }
}
