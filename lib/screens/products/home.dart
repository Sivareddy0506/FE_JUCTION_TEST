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
import '../../services/favorites_service.dart';
//import './products_display.dart';

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
    debugPrint('HomePage: handleTabChange called with "$selected"');
    setState(() {
      activeTab = selected;
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint('HomePage: initState called');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize favorites service first
    await FavoritesService().initialize();
    // Then fetch home data
    await fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    debugPrint('HomePage: fetchHomeData started');
    try {
      final lastViewed = await ApiService.fetchLastOpened();
      final latest = await ApiService.fetchAllProducts();
      final trending = await ApiService.fetchMostClicked();
      final searched = await ApiService.fetchLastSearched();
      final ads = await ApiService.fetchAdUrls();

      debugPrint("HomePage: API data fetched successfully");
      debugPrint("📦 lastViewedProducts: ${lastViewed.length}");
      debugPrint("📦 allProducts: ${latest.length}");
      debugPrint("📦 trendingProducts: ${trending.length}");
      debugPrint("📦 previousSearchProducts: ${searched.length}");
      debugPrint("📸 Ad URLs: $ads");

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
    } catch (e, stacktrace) {
      debugPrint('HomePage: Exception in fetchHomeData - $e');
      debugPrint(stacktrace.toString());
      setState(() {
        isLoading = false;
      });
    }
  }

  // Method to refresh favorites state across all product lists
  void _refreshFavorites() {
    debugPrint('HomePage: Refreshing favorites state');
    setState(() {
      // This will trigger a rebuild of all ProductGridWidget instances
      // which will reload their favorite states from the API
    });
  }
@override
Widget build(BuildContext context) {
  debugPrint('HomePage: build called. isLoading=$isLoading');

  if (isLoading) {
    debugPrint('HomePage: showing loading indicator');
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
            debugLogWidget('LogoAndIconsWidget'),
            const LogoAndIconsWidget(),
            const SizedBox(height: 16),
            debugLogWidget('SearchBarWidget'),
            const SearchBarWidget(),

            const SizedBox(height: 16),
            const SizedBox(height: 16),
            
            // Correct usage: CategoryGrid wrapped in SizedBox with fixed height
            const SizedBox(
              height: 120, // Reduced from 150 to 120 to match CategoryGrid height
              child: CategoryGrid(),
            ),

            const SizedBox(height: 8),

            debugLogWidget('CrewCrashBanner'),
            const CrewCrashBanner(),

            const SizedBox(height: 16),

            if (lastViewedProducts.isNotEmpty) ...[
              debugLogWidget('HorizontalProductList: Pick up where you left off'),
              HorizontalProductList(
                title: 'Pick up where you left off',
                products: lastViewedProducts,
                source: 'lastViewed',
                onFavoriteChanged: _refreshFavorites,
              ),
              const SizedBox(height: 16),
            ],

            if (adUrl1.isNotEmpty) ...[
              debugLogWidget('AdBannerWidget: adUrl1'),
              AdBannerWidget(mediaUrl: adUrl1),
              const SizedBox(height: 16),
            ],

            if (allProducts.isNotEmpty) ...[
              debugLogWidget('HorizontalProductList: Fresh Listings'),
              HorizontalProductList(
                title: 'Fresh Listings',
                products: allProducts,
                source: 'fresh',
                onFavoriteChanged: _refreshFavorites,
              ),
              const SizedBox(height: 16),
            ],

            if (previousSearchProducts.isNotEmpty) ...[
              debugLogWidget('HorizontalProductList: Based on your Previous Search'),
              HorizontalProductList(
                title: 'Based on your Previous Search',
                products: previousSearchProducts,
                source: 'searched',
                onFavoriteChanged: _refreshFavorites,
              ),
              const SizedBox(height: 16),
            ],

            if (adUrl2.isNotEmpty) ...[
              debugLogWidget('AdBannerWidget: adUrl2'),
              AdBannerWidget(mediaUrl: adUrl2),
              const SizedBox(height: 16),
            ],

            if (trendingProducts.isNotEmpty) ...[
              debugLogWidget('HorizontalProductList: Trending in your Locality'),
              HorizontalProductList(
                title: 'Trending in your Locality',
                products: trendingProducts,
                source: 'trending',
                onFavoriteChanged: _refreshFavorites,
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 30),
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

  // Helper method to print logs on widget rendering
  Widget debugLogWidget(String widgetName) {
    debugPrint('Rendering widget: $widgetName');
    return const SizedBox.shrink();
  }
}
