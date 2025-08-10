import 'package:flutter/material.dart';
import '../../../models/product.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: Center(
        child: Text(
          product.isAuction ? "Auction Detail" : "Product Detail",
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
