
// sold.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'empty_state.dart';
import '../../widgets/products_grid.dart';
import '../../../models/product.dart'; 

class SoldTab extends StatefulWidget {
  const SoldTab({super.key});

  @override
  State<SoldTab> createState() => _SoldTabState();
}

class _SoldTabState extends State<SoldTab> {
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
    final uri = Uri.parse('https://api.junctionverse.com/product/sold');

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['products'] ?? [];
      setState(() {
        products = items.map<Product>((item) => Product(
          imageUrl: (item['images'] != null && item['images'].isNotEmpty) ? item['images'][0] : 'assets/images/placeholder.png',
          title: item['title'] ?? 'No title',
          price: '₹${item['price'] ?? '0'}',
          location: item['location'] ?? 'Unknown',
        )).toList();
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
