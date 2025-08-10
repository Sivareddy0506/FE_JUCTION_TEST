import 'package:flutter/material.dart';
import '../../widgets/logo_icons_widget.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/category_grid.dart';
import '../../widgets/bottom_navbar.dart';
import '../../models/product.dart';
import './crew_crash_banner.dart';
import './horizontal_product_list.dart';
import './ad_banner_widget.dart';
import '../services/api_service.dart';
import './products_display.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String activeTab = 'home';

  List<Product> lastViewedProducts = [];
  List<Product> allProducts = [];
  List<Product> previousSearchProducts = [];
  List<Product> trendingProducts = [];
  String adUrl1 = '';
  String adUrl2 = '';
  bool isLoading = true;

  void handleTabChange(String selected) {
    setState(() {
      activeTab = selected;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    final lastViewed = await ApiService.fetchLastOpened();
    final latest = await ApiService.fetchAllProducts();
    final trending = await ApiService.fetchMostClicked();
    final searched = await ApiService.fetchLastSearched();
    final ads = await ApiService.fetchAdUrls();

    print("📦 lastViewedProducts: ${lastViewed.length}");
    print("📦 allProducts: ${latest.length}");
    print("📦 trendingProducts: ${trending.length}");
    print("📦 previousSearchProducts: ${searched.length}");
    print("📸 Ad URLs: $ads");

    setState(() {
      lastViewedProducts = lastViewed;
      allProducts = latest;
      trendingProducts = trending;
      previousSearchProducts = searched;
      if (ads.isNotEmpty) {
        adUrl1 = ads[0];
        adUrl2 = ads.length > 1 ? ads[1] : ads[0];
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              const SizedBox(
                height: 90,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [CategoryGrid()],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const CrewCrashBanner(),
              const SizedBox(height: 16),
              HorizontalProductList(
                title: 'Pick up where you left off',
                products: lastViewedProducts,
                source: 'lastViewed',
              ),
              if (adUrl1.isNotEmpty) ...[
                const SizedBox(height: 16),
                AdBannerWidget(mediaUrl: adUrl1),
              ],
              const SizedBox(height: 16),
              HorizontalProductList(
                title: 'Fresh Listings',
                products: allProducts,
                source: 'fresh',
              ),
              const SizedBox(height: 16),
              HorizontalProductList(
                title: 'Based on your Previous Search',
                products: previousSearchProducts,
                source: 'searched',
              ),
              if (adUrl2.isNotEmpty) ...[
                const SizedBox(height: 16),
                AdBannerWidget(mediaUrl: adUrl2),
              ],
              const SizedBox(height: 16),
              HorizontalProductList(
                title: 'Trending in your Locality',
                products: trendingProducts,
                source: 'trending',
              ),
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
