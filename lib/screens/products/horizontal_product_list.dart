import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/products_grid.dart';
import './products_display.dart';

class HorizontalProductList extends StatelessWidget {
  final String title;
  final List<Product> products;
  final String source; // used for navigating to View All screen with API source

  const HorizontalProductList({
    super.key,
    required this.title,
    required this.products,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final limitedProducts = products.take(2).toList(); // limit to 2

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductListingPage(
                      title: title,
                      source: source,
                    ),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ProductGridWidget(products: limitedProducts),
        const SizedBox(height: 16),
      ],
    );
  }
}
