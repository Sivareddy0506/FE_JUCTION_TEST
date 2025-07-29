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
        final auctions = data['auctions'] ?? [];
        final products = data['products'] ?? [];

        List<Product> allFetchedItems = [];

        // Convert auctions
        allFetchedItems.addAll(
          auctions.map<Product>((item) {
            final image = (item['images'] != null && item['images'].isNotEmpty)
                ? item['images'][0]
                : 'assets/images/placeholder.png';

            return Product(
              imageUrl: image,
              title: item['title'] ?? 'No title',
              price: item['starting_price'] != null
                  ? 'Starting: ₹${item['starting_price']}'
                  : null,
              location: item['location'] ?? 'Unknown',
              isAuction: true,
              bidStartDate: item['bid_start_date'] != null
                  ? DateTime.tryParse(item['bid_start_date'])
                  : null,
              duration: item['duration'],
            );
          }).toList(),
        );

        // Convert regular products
        allFetchedItems.addAll(
          products.map<Product>((item) {
            final image = (item['images'] != null && item['images'].isNotEmpty)
                ? item['images'][0]
                : 'assets/images/placeholder.png';

            return Product(
              imageUrl: image,
              title: item['title'] ?? 'No title',
              price: item['price'] != null ? '₹${item['price']}' : null,
              location: item['location'] ?? 'Unknown',
              isAuction: false,
            );
          }).toList(),
        );

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
