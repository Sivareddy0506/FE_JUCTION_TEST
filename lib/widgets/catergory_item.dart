import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final String imagePath;
  final String label;

  const CategoryItem({super.key, required this.imagePath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6), // Reduced from 8 to 6
          decoration: BoxDecoration(
            //shape: BoxShape.circle,
            //color: Colors.grey[200],
          ),
          child: Image.asset(
            imagePath,
            height: 60, // Reduced from 80 to 60
            width: 60,  // Reduced from 80 to 60
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11), // Reduced from 12 to 11
        ),
      ],
    );
  }
}
