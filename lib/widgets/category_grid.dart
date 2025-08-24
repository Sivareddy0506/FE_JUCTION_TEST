import 'package:flutter/material.dart';
import './catergory_item.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  final List<Map<String, String>> categories = const [
    {'image': 'assets/CarBattery.png', 'label': 'Electronics'},
    {'image': 'assets/computers.png', 'label': 'Computers &\nNetworking'},
    {'image': 'assets/furniture.png', 'label': 'Furniture'},
    {'image': 'assets/books.png', 'label': 'Books'},
    // {'image': 'assets/clothing.png', 'label': 'Clothing'},
    // {'image': 'assets/toys.png', 'label': 'Toys'},
    // {'image': 'assets/kitchen.png', 'label': 'Kitchen'},
    // {'image': 'assets/sports.png', 'label': 'Sports'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, // Reduced from 100 to 120 to accommodate smaller icons
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12), // Reduced from 16 to 12
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryItem(
            imagePath: category['image']!,
            label: category['label']!,
          );
        },
      ),
    );
  }
}
