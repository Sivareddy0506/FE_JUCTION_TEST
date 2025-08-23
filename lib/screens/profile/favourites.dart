import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../../widgets/products_grid.dart';
import './empty_state.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  bool isLoading = true;
  List<Product> favouriteProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchFavourites();
  }

  Future<void> _fetchFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      debugPrint("No auth token found.");
      setState(() => isLoading = false);
      return;
    }

    try {
      final uri = Uri.parse("https://api.junctionverse.com/user/my-favourites");
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        final List<dynamic> favouritesList = decoded['favourites'] ?? [];

        final products = favouritesList.map<Product>((item) {
          // Use the proper Product.fromJson method to handle all type conversions
          return Product.fromJson(Map<String, dynamic>.from(item));
        }).toList();

        setState(() {
          favouriteProducts = products;
          isLoading = false;
        });
      } else {
        debugPrint("Error fetching favourites: ${res.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Exception while fetching favourites: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favouriteProducts.isEmpty) {
      return const EmptyState(text: 'No favorites yet.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ProductGridWidget(products: favouriteProducts),
    );
  }
}
