import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'empty_state.dart';
import '../../widgets/products_grid.dart';
import '../../../models/product.dart';

class PurchasedTab extends StatefulWidget {
  const PurchasedTab({super.key});

  @override
  State<PurchasedTab> createState() => _PurchasedTabState();
}

class _PurchasedTabState extends State<PurchasedTab> {
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final uri = Uri.parse('https://api.junctionverse.com/product/purchased');

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['products'] ?? [];

      final fetchedProducts = items.map<Product>((item) {
        final imageUrl = (item['images'] != null && item['images'].isNotEmpty)
            ? item['images'][0]['fileUrl']
            : 'assets/images/placeholder.png';

        final location = item['location'];
        final latitude = location != null ? location['lat']?.toDouble() : null;
        final longitude = location != null ? location['lng']?.toDouble() : null;


        return Product(
          id: item['_id'] ?? item['id'] ?? '',
          imageUrl: imageUrl,
          title: item['title'] ?? 'No title',
          price: item['price'] != null ? '₹${item['price']}' : null,
          isAuction: item['isAuction'] ?? false,
          bidStartDate: item['bidStartDate'] != null
              ? DateTime.tryParse(item['bidStartDate'])
              : null,
          duration: item['duration'],
          latitude: latitude,
          longitude: longitude,
        );
      }).toList();

      setState(() {
        products = fetchedProducts;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (products.isEmpty) return const EmptyState(text: 'Oops, no listings so far');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ProductGridWidget(products: products),
    );
  }
}
