import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';

class ApiService {
  // Get auth token from local storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// Helper: filter out auction products
  static List<Product> _filterNonAuction(List<Product> products) {
    return products.where((p) => p.isAuction != true).toList();
  }

  /// Fetch last opened products
  static Future<List<Product>> fetchLastOpened() async {
    final token = await _getToken();
    final uri = Uri.parse('https://api.junctionverse.com/api/history/last-opened');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    print('🔍 fetchLastOpened: ${res.statusCode}');
    print('🧾 Response: ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is List) {
        return _filterNonAuction(data.map((e) => Product.fromJson(e)).toList());
      }
    }
    return [];
  }

  /// Fetch most clicked products
  static Future<List<Product>> fetchMostClicked() async {
    final uri = Uri.parse('https://api.junctionverse.com/api/history/most-clicked');
    final res = await http.get(uri);

    print('🔍 fetchMostClicked: ${res.statusCode}');
    print('🧾 Response: ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is List) {
        return _filterNonAuction(data.map((e) => Product.fromJson(e)).toList());
      }
    }
    return [];
  }

  /// Fetch all public products
  static Future<List<Product>> fetchAllProducts() async {
    final token = await _getToken();
    final uri = Uri.parse('https://api.junctionverse.com/product/products/public');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    print('🔍 fetchAllProducts: ${res.statusCode}');
    print('🧾 Response: ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      List<Product> products = [];
      if (data is Map && data['products'] is List) {
        products = (data['products'] as List).map((e) => Product.fromJson(e)).toList();
      } else if (data is List) {
        products = data.map((e) => Product.fromJson(e)).toList();
      }
      return _filterNonAuction(products);
    }
    return [];
  }

  /// Track product click
  static Future<void> trackProductClick(String productId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('https://api.junctionverse.com/api/history/track-click');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'productId': productId}),
      );

      print('📌 Track Click Status: ${res.statusCode}');
      print('📦 Track Click Response: ${res.body}');
    } catch (e) {
      print('❌ Track Click Error: $e');
    }
  }

  /// Fetch based on user search history
  static Future<List<Product>> fetchLastSearched() async {
    final token = await _getToken();
    final uri = Uri.parse('https://api.junctionverse.com/api/history/last-searched');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    print('🔍 fetchLastSearched: ${res.statusCode}');
    print('🧾 Response: ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is List) {
        return _filterNonAuction(data.map((e) => Product.fromJson(e)).toList());
      }
    }
    return [];
  }

  static Future<List<String>> fetchAdUrls() async {
    final token = await _getToken();
    final uri = Uri.parse('https://api.junctionverse.com/api/ad/allids');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    print('🔍 fetchAdUrls: ${res.statusCode}');
    print('🧾 Response: ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is List) {
        final urls = data
            .map<String>((e) => e['mediaUrl'] ?? '')
            .where((url) => url.isNotEmpty && url.startsWith('http'))
            .toList();

        print("✅ Filtered Ad URLs: $urls");
        return urls;
      }
    }
    return [];
  }
}
