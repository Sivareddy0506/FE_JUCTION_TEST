import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/logo_icons_widget.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/category_grid.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/location_display_widget.dart';
import '../../models/product.dart';
import './horizontal_product_list.dart';
import './ad_banner_widget.dart';
import '../services/api_service.dart';
import '../../services/favorites_service.dart';
import './products_display.dart';
import '../../app.dart';
import '../../app_state.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
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

  // Pull-to-refresh: clear caches and fetch fresh data
  Future<void> _handleForceRefresh() async {
    try {
      // Optional: clear any cached home data before refetching. Implementations vary.
      // await AppCacheService.clearHomeFeed();

      setState(() => _productsReady = false);
      await fetchHomeData();
    } finally {
      if (mounted) setState(() => _productsReady = true);
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('HomePage: initState called');
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    // Check user status on init
    _checkUserStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check user status when app resumes from background
    if (state == AppLifecycleState.resumed) {
      debugPrint('HomePage: App resumed, checking user status');
      _checkUserStatus();
    }
  }

  /// Check and update user status from backend
  Future<void> _checkUserStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLogin') ?? false;
      
      if (!isLoggedIn) {
        return;
      }

      final result = await AuthHealthService.refreshAuthToken();
      
      if (result['status'] == 'refreshed') {
        final isVerified = result['isVerified'] as bool? ?? false;
        final isOnboarded = result['isOnboarded'] as bool? ?? false;
        final wasOnboarded = AppState.instance.isOnboarded;
        
        // Persist to SharedPreferences for cold start restoration
        await prefs.setBool('isVerified', isVerified);
        await prefs.setBool('isOnboarded', isOnboarded);
        
        // Update AppState with latest status
        AppState.instance.setUserStatus(
          isVerified: isVerified,
          isOnboarded: isOnboarded,
        );
        
        // Update token if provided
        if (result['token'] != null) {
          await prefs.setString('authToken', result['token'] as String);
        }
        
        // If user just became onboarded, setup Firebase and show success message
        if (!wasOnboarded && isOnboarded && mounted) {
          debugPrint('HomePage: User just became onboarded! Setting up Firebase...');
          await _setupFirebaseForNewlyOnboardedUser();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Your account has been approved! Full access enabled.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('HomePage: Error checking user status: $e');
    }
  }

  /// Setup Firebase for a user who just became onboarded
  Future<void> _setupFirebaseForNewlyOnboardedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId == null || userId.isEmpty) {
        debugPrint('HomePage: No userId found, skipping Firebase setup');
        return;
      }

      // Create Firebase custom token
      final customTokenResponse = await http.post(
        Uri.parse('https://api.junctionverse.com/user/firebase/createcustomtoken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      ).timeout(const Duration(seconds: 30));

      if (customTokenResponse.statusCode == 200) {
        final customToken = jsonDecode(customTokenResponse.body)['token'];
        
        // Setup Firebase Auth
        try {
          await FirebaseAuth.instance.signInWithCustomToken(customToken);
          await prefs.setString('firebaseUserId', FirebaseAuth.instance.currentUser?.uid ?? '');
          await prefs.setString('firebaseToken', customToken);
          
          // Initialize ChatService
          await ChatService.initializeUserId();
          
          debugPrint('HomePage: Firebase setup completed for newly onboarded user');
        } catch (e) {
          debugPrint('HomePage: Error setting up Firebase: $e');
        }
      }
    } catch (e) {
      debugPrint('HomePage: Error in Firebase setup: $e');
    }
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
      if (mounted) {
        setState(() {
          _favoritesReady = true;
        });
      }
      debugPrint('HomePage: Favorites service initialized successfully');
    } catch (e) {
      debugPrint('HomePage: Error initializing favorites service - $e');
      if (mounted) {
        setState(() {
          _favoritesReady = true; // Set to true even on error to prevent infinite loading
        });
      }
    }
  }

  Future<void> _initializeProducts() async {
    debugPrint('HomePage: Initializing products data');
    try {
      await fetchHomeData();
      if (mounted) {
        setState(() {
          _productsReady = true;
        });
      }
      debugPrint('HomePage: Products data initialized successfully');
    } catch (e) {
      debugPrint('HomePage: Error initializing products data - $e');
      if (mounted) {
        setState(() {
          _productsReady = true; // Set to true even on error to prevent infinite loading
        });
      }
    }
  }

  Future<void> fetchHomeData() async {
    debugPrint('HomePage: fetchHomeData started');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final bool loggedIn = token != null && token.isNotEmpty;

      // Run all API calls in parallel with individual timeouts and error handling
      final results = await Future.wait([
        // Each call has its own timeout and returns empty list on error
        ApiService.fetchLastOpenedWithCache()
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                debugPrint('HomePage: fetchLastOpenedWithCache timed out');
                return <Product>[];
              },
            )
            .catchError((e) {
              debugPrint('HomePage: Error fetching lastViewed: $e');
              return <Product>[];
            }),
        
        ApiService.fetchAllProductsWithCache()
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                debugPrint('HomePage: fetchAllProductsWithCache timed out');
                return <Product>[];
              },
            )
            .catchError((e) {
              debugPrint('HomePage: Error fetching allProducts: $e');
              return <Product>[];
            }),
        
        ApiService.fetchMostClickedWithCache()
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                debugPrint('HomePage: fetchMostClickedWithCache timed out');
                return <Product>[];
              },
            )
            .catchError((e) {
              debugPrint('HomePage: Error fetching trending: $e');
              return <Product>[];
            }),
        
        ApiService.fetchLastSearchedWithCache()
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                debugPrint('HomePage: fetchLastSearchedWithCache timed out');
                return <Product>[];
              },
            )
            .catchError((e) {
              debugPrint('HomePage: Error fetching searched: $e');
              return <Product>[];
            }),
        
        ApiService.fetchAdUrlsWithCache()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('HomePage: fetchAdUrlsWithCache timed out');
                return <String>[];
              },
            )
            .catchError((e) {
              debugPrint('HomePage: Error fetching ads: $e');
              return <String>[];
            }),
      ], eagerError: false); // Don't fail all if one fails

      // Extract results
      final lastViewed = results[0] as List<Product>;
      final latest = results[1] as List<Product>;
      final trending = results[2] as List<Product>;
      final searched = results[3] as List<Product>;
      final ads = results[4] as List<String>;

      debugPrint("HomePage: API data fetched successfully");
      debugPrint("📦 lastViewedProducts: ${lastViewed.length}");
      debugPrint("📦 allProducts: ${latest.length}");
      debugPrint("📦 trendingProducts: ${trending.length}");
      debugPrint("📦 previousSearchProducts: ${searched.length}");
      debugPrint("📸 Ad URLs: $ads");

      if (mounted) {
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
      }
    } catch (e, stacktrace) {
      debugPrint('HomePage: Exception in fetchHomeData - $e');
      debugPrint(stacktrace.toString());
      // Don't rethrow - set empty data instead to prevent infinite loading
      if (mounted) {
        setState(() {
          lastViewedProducts = [];
          allProducts = [];
          trendingProducts = [];
          previousSearchProducts = [];
          adUrl1 = '';
          adUrl2 = '';
        });
      }
    }
  }

  // Method to refresh favorites state across all product lists
  void _refreshFavorites() {
    debugPrint('HomePage: Refreshing favorites state');
    if (mounted) {
      setState(() {
        // Triggers rebuild so ProductGridWidgets reload favourite state
      });
    }
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
        minimum: const EdgeInsets.only(top: 24), // extra push-down
        child: Column(
          children: [
            // Static header section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  debugLogWidget('LogoAndIconsWidget'),
                  const LogoAndIconsWidget(),
                  const SizedBox(height: 8),
                  debugLogWidget('LocationDisplayWidget'),
                  const LocationDisplayWidget(),
                  const SizedBox(height: 8),
                  debugLogWidget('SearchBarWidget'),
                  const SearchBarWidget(),
                  const SizedBox(height: 10),
                  // Separator line below search bar
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color(0xFFEAEAEA),
                  ),
                ],
              ),
            ),
            // Scrollable content section
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleForceRefresh,
                edgeOffset: 0,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      debugLogWidget('CategoryGrid'),
                      const SizedBox(
                        height: 130,
                        child: CategoryGrid(),
                      ),
                      const SizedBox(height: 10), // Reduced from 16 to 10
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
              ),
            ),
          ],
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
