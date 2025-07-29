import 'package:flutter/material.dart';
import '../../widgets/logo_icons_widget.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/category_grid.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/products_grid.dart';
import '../../models/product.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String activeTab = 'home';

  final List<Product> dummyProducts = [
    Product(
      imageUrl: 'assets/images/product1.png',
      title: 'Product 1',
      price: '₹199',
      location: 'Koregaon Park',
    ),
    Product(
      imageUrl: 'assets/images/product2.png',
      title: 'Product 2',
      price: '₹299',
      location: 'Viman Nagar',
    ),
    Product(
      imageUrl: 'assets/images/product3.png',
      title: 'Product 3',
      price: '₹399',
      location: 'Baner',
    ),
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
