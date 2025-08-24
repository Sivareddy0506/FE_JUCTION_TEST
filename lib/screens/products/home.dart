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
  
  // Separate flags for different data sources
  bool _favoritesReady = false;
  bool _productsReady = false;
  
  // Computed getter to check if all data is ready
  bool get _allDataReady => _favoritesReady && _productsReady;

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
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    debugPrint('HomePage: fetchHomeData started');
    try {
      final lastViewed = await ApiService.fetchLastOpenedWithCache();
      final latest = await ApiService.fetchAllProductsWithCache();
      final trending = await ApiService.fetchMostClickedWithCache();
      final searched = await ApiService.fetchLastSearchedWithCache();
      final ads = await ApiService.fetchAdUrlsWithCache();

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
      });
    } catch (e, stacktrace) {
      debugPrint('HomePage: Exception in fetchHomeData - $e');
      debugPrint(stacktrace.toString());
      // Don't set isLoading to false here, let _initializeProducts handle it
      rethrow; // Re-throw to be caught by _initializeProducts
    }
  }
@override
Widget build(BuildContext context) {
  debugPrint('HomePage: build called. isLoading=$isLoading');

  @override
  Widget build(BuildContext context) {
    debugPrint('HomePage: build called. _allDataReady=$_allDataReady, _favoritesReady=$_favoritesReady, _productsReady=$_productsReady');

    Widget content;
    
    if (!_allDataReady) {
      debugPrint('HomePage: showing loading indicator - waiting for data to be ready');
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      content = SafeArea(
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
              height: 150,
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
              ),

              const SizedBox(height: 8),

            if (allProducts.isNotEmpty) ...[
              debugLogWidget('HorizontalProductList: Fresh Listings'),
              HorizontalProductList(
                title: 'Fresh Listings',
                products: allProducts,
                source: 'fresh',
              ),
              const SizedBox(height: 16),
            ],

            if (previousSearchProducts.isNotEmpty) ...[
              debugLogWidget('HorizontalProductList: Based on your Previous Search'),
              HorizontalProductList(
                title: 'Based on your Previous Search',
                products: previousSearchProducts,
                source: 'searched',
              ),
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

            if (trendingProducts.isNotEmpty) ...[
              debugLogWidget('HorizontalProductList: Trending in your Locality'),
              HorizontalProductList(
                title: 'Trending in your Locality',
                products: trendingProducts,
                source: 'trending',
              ),
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
      );
    }

    return BottomNavWrapper(
      activeItem: activeTab,
      onTap: handleTabChange,
      child: content,
    );
  }

  // Helper method to print logs on widget rendering
  Widget debugLogWidget(String widgetName) {
    debugPrint('Rendering widget: $widgetName');
    return const SizedBox.shrink();
  }
}
