import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/app_button.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Row(
            children: [
              CircleAvatar(),
              SizedBox(width: 8),
              Text('Advika Sethi'),
              Spacer(),
              Text('1 hour ago'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: PageView(
              children: [
                Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Image.asset('assets/images/placeholder.png'),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Chip(label: Text('Age: > 2Y')),
              SizedBox(width: 8),
              Chip(label: Text('Usage: Regular')),
              SizedBox(width: 8),
              Chip(label: Text('Condition: Good')),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Electronics', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(product.title, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(product.price ?? '', style: const TextStyle(color: Colors.orange, fontSize: 18)),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.remove_red_eye, size: 16),
              SizedBox(width: 4),
              Text('Viewed by 23 others'),
              Spacer(),
              Icon(Icons.location_on, size: 16),
              SizedBox(width: 4),
              Text('Kalyani Nagar'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border),
                label: const Text('Favourite'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(product.description ?? 'Good condition, box included'),
          const SizedBox(height: 8),
          const Text('Pickup Location', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(product.location ?? 'Behind Cafeteria 1, Symbiosis'),
          const SizedBox(height: 16),
          const Text('Related Products', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.network(
                        'https://via.placeholder.com/150x150?text=Related+$index',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Plywood Table for sale - Urgent'),
                    const Text('₹950.00', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat),
            label: const Text('Chat'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          )
        ],
      ),
    );
  }
}
