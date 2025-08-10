import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'empty_state.dart';
import '../../widgets/products_grid.dart';
import '../../../models/product.dart';

class ActiveAuctionsTab extends StatefulWidget {
  const ActiveAuctionsTab({super.key});

  @override
  State<ActiveAuctionsTab> createState() => _ActiveAuctionsTabState();
}

class _ActiveAuctionsTabState extends State<ActiveAuctionsTab> {
  List<Product> allItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      debugPrint("Error: No auth token found.");
      setState(() => isLoading = false);
      return;
    }

    final uri = Uri.parse('https://api.junctionverse.com/product/active');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

       List<Product> allFetchedItems = data.map<Product>((item) {
  final imageUrl = (item['images'] != null && item['images'].isNotEmpty)
      ? item['images'][0]['fileUrl']
      : 'assets/images/placeholder.png';

  final isAuction = item['isAuction'] ?? false;
  final location = item['location'];
  final double? latitude = location != null ? location['lat']?.toDouble() : null;
  final double? longitude = location != null ? location['lng']?.toDouble() : null;

  return Product(
    id: item['_id'] ?? item['id'] ?? '', // ✅ add this line
    imageUrl: imageUrl,
    title: item['title'] ?? 'No title',
    price: isAuction
        ? (item['price'] != null ? 'Starting: ₹${item['price']}' : null)
        : (item['price'] != null ? '₹${item['price']}' : null),
    isAuction: isAuction,
    bidStartDate: item['bidStartDate'] != null
        ? DateTime.tryParse(item['bidStartDate'])
        : null,
    duration: item['duration'],
    latitude: latitude,
    longitude: longitude,
    description: item['description'],
    location: item['pickupLocation'] ?? item['locationName'],
    seller: item['seller'] != null
        ? Seller.fromJson(item['seller'])
        : null,
  );
}).toList();


        setState(() {
          allItems = allFetchedItems;
          isLoading = false;
        });
      } else {
        debugPrint("API Error: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Exception while fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (allItems.isEmpty) {
      return const EmptyState(text: 'No products or auctions available.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ProductGridWidget(products: allItems),
    );
  }
}
