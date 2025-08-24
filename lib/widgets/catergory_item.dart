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
<<<<<<< Updated upstream
          padding: const EdgeInsets.all(8),
=======
          padding: const EdgeInsets.all(8), // Increased from 6 to 8
>>>>>>> Stashed changes
          decoration: BoxDecoration(
            //shape: BoxShape.circle,
            //color: Colors.grey[200],
          ),
          child: Image.asset(
            imagePath,
<<<<<<< Updated upstream
            height: 80,
            width: 80,
=======
            height: 70, // Increased from 60 to 70
            width: 70,  // Increased from 60 to 70
>>>>>>> Stashed changes
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
<<<<<<< Updated upstream
          style: const TextStyle(fontSize: 12),
=======
          style: const TextStyle(fontSize: 12), // Increased from 11 to 12
>>>>>>> Stashed changes
        ),
      ],
    );
  }
}
