import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductGridWidget extends StatelessWidget {
  final List<Product> products;

  const ProductGridWidget({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final product = products[index];

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/placeholder.png'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (product.isAuction && product.bidStartDate != null && product.duration != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.price ?? '',
                            style: const TextStyle(color: Colors.deepOrange),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bidding: ${product.bidStartDate!.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Duration: ${product.duration} days',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      )
                    else if (!product.isAuction)
                      Text(
                        product.price ?? '',
                        style: const TextStyle(color: Colors.green),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      product.location,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
