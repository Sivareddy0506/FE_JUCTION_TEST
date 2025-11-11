import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/logo_icons_widget.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/category_grid.dart';
import '../../widgets/bottom_navbar.dart';
import '../../models/product.dart';
import './horizontal_product_list.dart';
import './ad_banner_widget.dart';
import '../services/api_service.dart';
import '../../services/favorites_service.dart';
import './products_display.dart';
import '../../app.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
  bool _isLoggedIn = false;
  
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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('HomePage: Starting parallel initialization');
    await Future.wait([
      _initializeFavorites(),
      _initializeProducts(),
    ]);
    debugPrint('HomePage: All data initialization completed');
  }

  Future<void> _initializeFavorites() async {
    debugPrint('HomePage: Initializing favorites service');
    try {
      await FavoritesService().initialize();
      setState(() {
        _favoritesReady = true;
      });
      debugPrint('HomePage: Favorites service initialized successfully');
    } catch (e) {
      debugPrint('HomePage: Error initializing favorites service - $e');
      setState(() {
        _favoritesReady = true; // Set to true even on error to prevent infinite loading
      });
    }
  }

  Future<void> _initializeProducts() async {
    debugPrint('HomePage: Initializing products data');
    try {
      await fetchHomeData();
      setState(() {
        _productsReady = true;
      });
      debugPrint('HomePage: Products data initialized successfully');
    } catch (e) {
      debugPrint('HomePage: Error initializing products data - $e');
      setState(() {
        _productsReady = true; // Set to true even on error to prevent infinite loading
      });
    }
  }

  Future<void> fetchHomeData() async {
    debugPrint('HomePage: fetchHomeData started');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final bool loggedIn = token != null && token.isNotEmpty;

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
        _isLoggedIn = loggedIn;
        lastViewedProducts = lastViewed;
        allProducts = latest;
        trendingProducts = trending;
        previousSearchProducts = searched;
        if (ads.isNotEmpty) {
          adUrl1 = ads[0];
          adUrl2 = ads.length > 1 ? ads[1] : ads[0];
        } else {
          adUrl1 = '';
          adUrl2 = '';
        }
      });
    } catch (e, stacktrace) {
      debugPrint('HomePage: Exception in fetchHomeData - $e');
      debugPrint(stacktrace.toString());
      rethrow; // Re-throw to be caught by _initializeProducts
    }
  }

  // Method to refresh favorites state across all product lists
  void _refreshFavorites() {
    debugPrint('HomePage: Refreshing favorites state');
    setState(() {
      // Triggers rebuild so ProductGridWidgets reload favourite state
    });
  }

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
              const SizedBox(height: 20),
              debugLogWidget('CategoryGrid'),
              const SizedBox(
                height: 130,
                child: CategoryGrid(),
              ),
              const SizedBox(height: 24),
              ..._buildProductSection(
                title: 'Last Viewed',
                products: lastViewedProducts,
                source: 'lastViewed',
                requireLogin: true,
                emptyMessage: 'You haven\'t viewed any products yet. Start exploring to see them here.',
              ),
              ..._buildProductSection(
                title: 'Fresh Listings',
                products: allProducts,
                source: 'fresh',
                emptyMessage: 'No fresh listings available right now. Check back soon!',
              ),
              if (adUrl1.isNotEmpty) ...[
                debugLogWidget('AdBannerWidget: adUrl1'),
                AdBannerWidget(mediaUrl: adUrl1),
                const SizedBox(height: 24),
              ],
              ..._buildProductSection(
                title: 'Trending in your location',
                products: trendingProducts,
                source: 'trending',
                emptyMessage: 'No trending items nearby yet. Be the first to list!',
              ),
              if (previousSearchProducts.isNotEmpty) ...[
                debugLogWidget('HorizontalProductList: Based on your Previous Search'),
                HorizontalProductList(
                  title: 'Based on your Previous Search',
                  products: previousSearchProducts,
                  source: 'searched',
                  onFavoriteChanged: _refreshFavorites,
                ),
              ],
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

  List<Widget> _buildProductSection({
    required String title,
    required List<Product> products,
    required String source,
    String? emptyMessage,
    bool requireLogin = false,
  }) {
    final bool shouldShow = !requireLogin || _isLoggedIn;
    if (!shouldShow) return [];

    final widgets = <Widget>[];

    if (products.isEmpty) {
      if (emptyMessage == null) return [];
      widgets
        ..add(debugLogWidget('Placeholder: $title'))
        ..add(_buildEmptySection(
          title: title,
          message: emptyMessage,
          source: source,
        ));
    } else {
      widgets
        ..add(debugLogWidget('HorizontalProductList: $title'))
        ..add(HorizontalProductList(
          title: title,
          products: products,
          source: source,
          onFavoriteChanged: _refreshFavorites,
        ));
    }

    if (widgets.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  Widget _buildEmptySection({
    required String title,
    required String message,
    required String source,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  SlidePageRoute(
                    page: ProductListingPage(
                      title: title,
                      source: source,
                    ),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E6E6)),
          ),
          child: Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF4F4F4F)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
