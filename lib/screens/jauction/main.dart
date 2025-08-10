import 'package:flutter/material.dart';
import '../../widgets/logo_icons_widget.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/category_grid.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/products_grid.dart';
import '../../models/product.dart';

class JauctionHomePage extends StatefulWidget {
  const JauctionHomePage({Key? key}) : super(key: key);

  @override
  State<JauctionHomePage> createState() => _JauctionHomePageState();
}

class _JauctionHomePageState extends State<JauctionHomePage> {
  String activeTab = 'home';

  final List<Product> dummyProducts = [
   
  ];

  void handleTabChange(String selected) {
    setState(() {
      activeTab = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const LogoAndIconsWidget(),
              const SizedBox(height: 12),
              const SearchBarWidget(),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 16),
              const CategoryGrid(),
              const SizedBox(height: 24),
              ProductGridWidget(products: dummyProducts),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        activeItem: activeTab,
        onTap: handleTabChange,
      ),
    );
  }
}
