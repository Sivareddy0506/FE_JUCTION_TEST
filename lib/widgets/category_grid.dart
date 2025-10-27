import 'package:flutter/material.dart';
import '../screens/search/search_results_page.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  final List<Map<String, String>> categories = const [
    {'image': 'assets/CarBattery.png', 'label': 'Electronics'},
    {'image': 'assets/computers.png', 'label': 'Computers &\nNetworking'},
    {'image': 'assets/furniture.png', 'label': 'Furniture'},
    {'image': 'assets/books.png', 'label': 'Books'},
    {'image': 'assets/sports.png', 'label': 'Sports Equipment'},
    {'image': 'assets/clothes.png', 'label': 'Clothes &\nAccessories'},
    {'image': 'assets/gaming.png', 'label': 'Gaming'},
    {'image': 'assets/hobbies.png', 'label': 'Hobbies &\nActivities'},
    {'image': 'assets/tickets.png', 'label': 'Tickets &\nVouchers'},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemSize = (screenWidth * 0.18).clamp(48.0, 96.0);

    return SizedBox(
      height: itemSize + 40, // image + label + padding
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              final raw = category['label'] ?? '';
              final query = raw
                  .replaceAll('\n', ' ')
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchResultsPage(searchQuery: query),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔥 High-quality responsive image
                Image.asset(
                  category['image']!,
                  width: itemSize,
                  height: itemSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 6),
                // 🔠 Responsive label
                Text(
                  category['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (screenWidth * 0.035).clamp(12.0, 16.0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
