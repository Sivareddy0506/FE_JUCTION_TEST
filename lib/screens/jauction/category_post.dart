import 'package:flutter/material.dart';
import '../../../widgets/custom_appbar.dart';

class JauctionCategoryPostPage extends StatefulWidget {
  const JauctionCategoryPostPage({super.key});

  @override
  State<JauctionCategoryPostPage> createState() => _CategoryPostPageState();
}

class _CategoryPostPageState extends State<JauctionCategoryPostPage> {
  final List<String> categories = [
    "Electronics",
    "Furniture",
    "Books",
    "Sports",
    "Fashion",
    "Gaming",
    "Hobbies",
    "Tickets",
    "Vehicles",
    "Miscellaneous",
  ];

  void _onCategorySelected(String category) {
    // Save selected category and navigate to next step
    // You can use Navigator.push to go to next page
    print("Selected category: $category");

    // Example:
    // Navigator.push(context, SlidePageRoute(page: NextPage(category: category)));
  }

  Widget _buildProgressChips(int currentStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final isActive = index <= currentStep;
        return Container(
          width: 59,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive ? const Color(0xFFFF6705) : const Color(0xFFE9E9E9),
          ),
        );
      }),
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
            _buildProgressChips(0),
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
