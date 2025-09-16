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

    if (token == null || token.isEmpty) {
      debugPrint("Error: No auth token found.");
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    final uri = Uri.parse('https://api.junctionverse.com/product/purchased');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // ✅ Handle both list and map responses
        final List<dynamic> items =
            decoded is List ? decoded : (decoded['products'] ?? []);

        final fetchedProducts = items.map<Product>((item) {
          final List<ProductImage> imageList =
              (item['images'] != null && item['images'] is List)
                  ? (item['images'] as List)
                      .map((img) => ProductImage(
                            fileUrl: img['fileUrl'] ??
                                'assets/images/placeholder.png',
                          ))
                      .toList()
                  : [];

          final imageUrl = imageList.isNotEmpty
              ? imageList.first.fileUrl
              : 'assets/images/placeholder.png';

          final location = item['location'];
          final double? latitude =
              location != null ? location['lat']?.toDouble() : null;
          final double? longitude =
              location != null ? location['lng']?.toDouble() : null;

          return Product(
            id: item['id'] ?? item['_id'] ?? '',
            images: imageList,
            imageUrl: imageUrl,
            title: item['title'] ?? item['name'] ?? 'No title',
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

        if (!mounted) return;
        setState(() {
          products = fetchedProducts;
          isLoading = false;
        });
      } else {
        debugPrint("API Error: ${response.statusCode}");
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Exception while fetching purchased products: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (products.isEmpty) {
      return const EmptyState(text: 'Oops, no listings so far');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ProductGridWidget(products: products),
    );
  }
}
