import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuctionService {
  static const String baseUrl = "https://api.junctionverse.com/user/auctions";

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  static Future<List<Product>> fetchUpcomingAuctions() async {
    final url = Uri.parse("$baseUrl/upcoming");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> data = json['data'] ?? [];
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load upcoming auctions");
    }
  }

  static Future<List<Product>> fetchMyCurrentAuctions() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Authentication required. Please log in again.");
    }
    
    final url = Uri.parse("$baseUrl/my-current");

    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> data = json['data'] ?? [];
      return data.map((e) => Product.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Authentication failed. Please log in again.");
    } else if (response.statusCode == 403) {
      throw Exception("Access denied. Please check your permissions.");
    } else {
      throw Exception("Failed to load my current auctions: ${response.statusCode}");
    }
  }

  static Future<List<Product>> fetchLiveTodayAuctions() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Authentication required. Please log in again.");
    }
    
    final url = Uri.parse("$baseUrl/live-today");

    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> data = json['data'] ?? [];
      return data.map((e) => Product.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Authentication failed. Please log in again.");
    } else if (response.statusCode == 403) {
      throw Exception("Access denied. Please check your permissions.");
    } else {
      throw Exception("Failed to load live today auctions: ${response.statusCode}");
    }
  }

  static Future<List<Product>> fetchTrendingAuctions() async {
    final url = Uri.parse("$baseUrl/trending");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> data = json['data'] ?? [];
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load trending auctions");
    }
  }

  static Future<List<Product>> fetchAuctionsByPreviousSearch() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Authentication required. Please log in again.");
    }
    
    final url = Uri.parse("$baseUrl/by-previous-search");

    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> data = json['data'] ?? [];
      return data.map((e) => Product.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Authentication failed. Please log in again.");
    } else if (response.statusCode == 403) {
      throw Exception("Access denied. Please check your permissions.");
    } else {
      throw Exception("Failed to load auctions by previous search: ${response.statusCode}");
    }
  }
}
