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
<<<<<<< Updated upstream
      height: 100, // Adjust height as needed
=======
      height: 130, // Increased from 120 to 130 to accommodate larger icons
>>>>>>> Stashed changes
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
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
