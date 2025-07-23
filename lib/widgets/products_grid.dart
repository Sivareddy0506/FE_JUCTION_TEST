import 'package:flutter/material.dart';

class Product {
  final String imageUrl;
  final String title;
  final String price;
  final String location;

  Product({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.location,
  });
}

class ProductGridWidget extends StatelessWidget {
  final List<Product> products;

  const ProductGridWidget({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 16,
      children: products.map((product) {
        return Container(
          width: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.asset(
                  product.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.price,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6705),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/mappin.png',
                          height: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          product.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A8894),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}
