import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../screens/products/product_detail.dart'; // Adjust the import path
import '../../app.dart'; // For SlidePageRoute

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    required this.product,
    this.onTap,
    super.key,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sold':
        return Colors.green;
      case 'Deal Locked':
        return const Color(0xFFFF6705);
      case 'For Sale':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              SlidePageRoute(
                page: ProductDetailPage(product: product),
              ),
            );
          },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: 8,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9F9),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(12),
            top: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Card(
          color: Colors.transparent, // ✅ Transparent to show background
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl,
                    width: screenWidth * 0.15,
                    height: screenWidth * 0.15,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/placeholder.png',
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        product.title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Product Description
                      if (product.description != null)
                        Text(
                          product.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[700],
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Row: Status + Date
                      Row(
                        children: [
                          if (product.currentOrder != null ||
                              product.status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                    product.currentOrder?.status ??
                                        product.status ??
                                        'Deal Locked'),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.currentOrder?.status ??
                                    product.status ??
                                    'Deal Locked',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),

                          // Created Date
                          if (product.createdAt != null)
                            Text(
                              DateFormat('MMM d, yyyy')
                                  .format(product.createdAt!),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: screenWidth * 0.032,
                              ),
                            ),
                        ],
                      ),

                      // Order ID
                      if (product.orderId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Order ID: ${product.orderId}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: screenWidth * 0.032,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: screenWidth * 0.04,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
