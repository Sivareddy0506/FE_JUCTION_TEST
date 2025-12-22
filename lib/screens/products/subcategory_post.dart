import 'package:flutter/material.dart';
import 'package:junction/app_state.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/listing_progress_indicator.dart';
import '../../constants/category_subcategories.dart';
import './describe_product.dart';
import '../../app.dart'; // For SlidePageRoute

class SubcategoryPostPage extends StatefulWidget {
  final String selectedCategory;

  const SubcategoryPostPage({super.key, required this.selectedCategory});

  @override
  State<SubcategoryPostPage> createState() => _SubcategoryPostPageState();
}

class _SubcategoryPostPageState extends State<SubcategoryPostPage> {
  List<String> get subcategories => CategorySubcategories.getSubcategories(widget.selectedCategory);

  void _onSubcategorySelected(String subcategory) {
    Navigator.push(
      context,
      SlidePageRoute(
        page: DescribeProductPage(
          selectedCategory: widget.selectedCategory,
          selectedSubCategory: subcategory,
        ),
      ),
    );
  }


  Widget _buildSubcategoryItem(String title) {
    return GestureDetector(
      onTap: () => _onSubcategorySelected(title),
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
              "Select Product Subcategory",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4, // 28px
                color: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Category: ${widget.selectedCategory}",
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF323537),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: subcategories.isEmpty
                  ? const Center(
                      child: Text(
                        'No subcategories available for this category',
                        style: TextStyle(color: Color(0xFF323537)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: subcategories.length,
                      itemBuilder: (_, index) => _buildSubcategoryItem(subcategories[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

