import 'package:flutter/material.dart';
import './catergory_item.dart'; 

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        CategoryItem(imagePath: 'assets/CarBattery.png', label: 'Electronics'),
        CategoryItem(imagePath: 'assets/computers.png', label: 'Computers &\nNetworking'),
        CategoryItem(imagePath: 'assets/furniture.png', label: 'Furniture'),
        CategoryItem(imagePath: 'assets/books.png', label: 'Books'),
      ],
    );
  }
}
