import 'package:flutter/material.dart';
import 'package:junction/app_state.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/listing_progress_indicator.dart';
import './subcategory_post.dart';
import '../../app.dart'; // For SlidePageRoute

class CategoryPostPage extends StatefulWidget {
  const CategoryPostPage({super.key});

  @override
  State<CategoryPostPage> createState() => _CategoryPostPageState();
}

class _CategoryPostPageState extends State<CategoryPostPage> {
  final List<String> categories = [
    "Electronics",
    "Furniture",
    "Books",
    "Sports",
    "Fashion",
    "Hobbies",
    "Vehicles",
    "Other",
  ];

 void _onCategorySelected(String category) {
  Navigator.push(
    context,
    SlidePageRoute(
      page: SubcategoryPostPage(selectedCategory: category),
    ),
  );
}



  Widget _buildCategoryItem(String title) {
    return GestureDetector(
      onTap: () => _onCategorySelected(title),
      child: Container(
        height: 56,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFC9C8D3), width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                height: 1.14, // ~16px
                fontWeight: FontWeight.w400,
                color: Color(0xFF262626),
              ),
            ),
            Image.asset('assets/CaretRight.png', width: 20, height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Place a Listing"),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListingProgressIndicator(currentStep: 1),
            const SizedBox(height: 32),
            const Text(
              "Select Product Category",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4, // 28px
                color: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (_, index) => _buildCategoryItem(categories[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
