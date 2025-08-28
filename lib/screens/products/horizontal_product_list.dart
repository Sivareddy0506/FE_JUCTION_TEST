import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/products_grid.dart';
import './products_display.dart';

class HorizontalProductList extends StatelessWidget {
  final String title;
  final List<Product> products;
  final String source; // used for navigating to View All screen with API source
  final VoidCallback? onFavoriteChanged; // Add callback for favorite changes

  const HorizontalProductList({
    super.key,
    required this.title,
    required this.products,
    required this.source,
    this.onFavoriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('HorizontalProductList: build called for "$title" with ${products.length} products');

    if (products.isEmpty) {
      debugPrint('HorizontalProductList: No products for "$title", returning empty widget');
      return const SizedBox.shrink();
    }

    final limitedProducts = products.length > 2 ? products.take(2).toList() : products;

    debugPrint('HorizontalProductList: Showing ${limitedProducts.length} products for "$title"');

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
                debugPrint('HorizontalProductList: "View All" pressed for "$title"');
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
        ProductGridWidget(
          products: limitedProducts,
          onFavoriteChanged: onFavoriteChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
