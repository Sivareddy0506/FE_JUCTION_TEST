import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'empty_state.dart';
import '../../../models/product.dart';
import 'package:intl/intl.dart';
import '/screens/products/product_detail.dart';
import '../../app.dart'; // For SlidePageRoute

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final currentUserId = prefs.getString('userId'); // <-- get it here
      if (token == null || token.isEmpty) {
        setState(() => isLoading = false);
        return;
      }
      final uri = Uri.parse('https://api.junctionverse.com/product/sold');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });
      debugPrint("Sold API Response:  ${response.body}");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> items = decoded is List ? decoded : [];
        final fetchedProducts = items.map<Product>((item) {
          final imagesList = (item['images'] as List?)
                  ?.map((img) => ProductImage.fromJson(Map<String, dynamic>.from(img)))
                  .toList() ??
              [];

          Seller? seller;
          if (item['seller'] is Map<String, dynamic>) {
            seller = Seller.fromJson(Map<String, dynamic>.from(item['seller']));
          } else if (item['sellerId'] != null) {
            seller = Seller(
              id: item['sellerId'] ?? '',
              fullName: item['sellerName'] ?? 'Unknown Seller',
              email: item['sellerEmail'] ?? '',
            );
          }

          final status = item['status'] ?? 'Sold';

          return Product(
            id: item['id'] ?? item['_id'] ?? '',
            images: imagesList,
            imageUrl: imagesList.isNotEmpty ? imagesList.first.fileUrl ?? '' : '',
            title: item['title'] ?? item['name'] ?? 'No Title',
            price: item['price'] != null ? '₹${item['price']}' : '',
            seller: seller,
            status: status,
            orderId: item['orderId'] ?? '',
            isAuction: item['isAuction'] ?? false,
            createdAt: item['createdAt'] != null ? DateTime.tryParse(item['createdAt']) : null,
            category: item['category'] ?? '',
            condition: item['condition'] ?? '',
            usage: item['usage'] ?? '',
            brand: item['brand'] ?? '',
            yearOfPurchase: item['yearOfPurchase'] ?? 0,
          );
        }).toList();
        final filteredProducts = fetchedProducts.where((p) => p.seller != null && p.seller!.id == currentUserId).toList();
        if (!mounted) return;
        setState(() {
          products = filteredProducts;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Sold Exception: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (products.isEmpty) return const EmptyState(text: 'No sold products found');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        final dateStr = product.createdAt != null
            ? DateFormat('dd MMM yyyy').format(product.createdAt!)
            : '';

       return GestureDetector(
        onTap: () {
          // TODO: navigate to product details page
          Navigator.push(
            context,
            SlidePageRoute(
              page: ProductDetailPage(product: product),
            ),
          );
        },
         child: Container(
           margin: const EdgeInsets.only(bottom: 16),
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(16),
             boxShadow: [
               BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
               ),
             ],
           ),
           child: Row(
             crossAxisAlignment: CrossAxisAlignment.center,
             children: [
               // Product image
               ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: product.imageUrl.isNotEmpty
              ? Image.network(
                  product.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/placeholder.png',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
               ),
               const SizedBox(width: 12),
         
               // Middle section
               Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title ?? 'No Title',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Order ID / ${product.orderId ?? ''}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.status ?? 'Deal Locked',
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
               ),
         
               // Right side: Date + Arrow
               Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              dateStr,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
               ),
             ],
           ),
         ),
       );

      },
    );
  }
}