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
          padding: const EdgeInsets.all(8), // Increased from 6 to 8
          decoration: BoxDecoration(
            //shape: BoxShape.circle,
            //color: Colors.grey[200],
          ),
          child: Image.asset(
            imagePath,
            height: (MediaQuery.of(context).size.width * 0.18).clamp(48.0, 96.0),
            width: (MediaQuery.of(context).size.width * 0.18).clamp(48.0, 96.0),
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12), // Increased from 11 to 12
        ),
      ],
    );
  }
}
