import 'package:flutter/material.dart';
import '../../widgets/logo_icons_widget.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/category_grid.dart';
import '../../widgets/bottom_navbar.dart';
import '../../models/product.dart';
import '../products/horizontal_product_list.dart';
import '../products/ad_banner_widget.dart';
import '../services/auction_service.dart';

class JauctionHomePage extends StatefulWidget {
  final String adUrl1;
  final String adUrl2;

  const JauctionHomePage({
    Key? key,
    this.adUrl1 = '',
    this.adUrl2 = '',
  }) : super(key: key);

  @override
  State<JauctionHomePage> createState() => _JauctionHomePageState();
}

class _JauctionHomePageState extends State<JauctionHomePage> {
  String activeTab = 'home';

  List<Product> upcomingAuctions = [];
  List<Product> myCurrentAuctions = [];
  List<Product> liveTodayAuctions = [];
  List<Product> previousSearchAuctions = [];
  List<Product> trendingAuctions = [];

  bool isLoading = true;

  void handleTabChange(String selected) {
    debugPrint('JauctionHomePage: handleTabChange called with "$selected"');
    setState(() {
      activeTab = selected;
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint('JauctionHomePage: initState called');
    _fetchAllSections();
  }

  Future<void> _fetchAllSections() async {
    try {
      debugPrint('JauctionHomePage: Fetching auctions...');
      final upcoming = await AuctionService.fetchUpcomingAuctions();
      final current = await AuctionService.fetchMyCurrentAuctions();
      final today = await AuctionService.fetchLiveTodayAuctions();
      final previous = await AuctionService.fetchAuctionsByPreviousSearch();
      final trending = await AuctionService.fetchTrendingAuctions();

      setState(() {
        upcomingAuctions = upcoming;
        myCurrentAuctions = current;
        liveTodayAuctions = today;
        previousSearchAuctions = previous;
        trendingAuctions = trending;
        isLoading = false;
      });

      debugPrint("✅ Auctions fetched successfully");
    } catch (e, stacktrace) {
      debugPrint('❌ Error loading auction data: $e');
      debugPrint(stacktrace.toString());
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('JauctionHomePage: build called. isLoading=$isLoading');

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
              debugLogWidget('LogoAndIconsWidget'),
              const LogoAndIconsWidget(),
              const SizedBox(height: 16),
              debugLogWidget('SearchBarWidget'),
              const SearchBarWidget(),
              const SizedBox(height: 16),
              const SizedBox(height: 120, child: CategoryGrid()), // Reduced from 150 to 120
              const SizedBox(height: 8),

              if (upcomingAuctions.isNotEmpty) ...[
                HorizontalProductList(
                  title: 'Upcoming Auctions',
                  products: upcomingAuctions,
                  source: 'upcoming',
                ),
                const SizedBox(height: 16),
              ],

              if (widget.adUrl1.isNotEmpty) ...[
                AdBannerWidget(mediaUrl: widget.adUrl1),
                const SizedBox(height: 16),
              ],

              if (myCurrentAuctions.isNotEmpty) ...[
                HorizontalProductList(
                  title: 'My Current Auctions',
                  products: myCurrentAuctions,
                  source: 'current',
                ),
                const SizedBox(height: 16),
              ],

              if (liveTodayAuctions.isNotEmpty) ...[
                HorizontalProductList(
                  title: 'Today’s Auctions',
                  products: liveTodayAuctions,
                  source: 'today',
                ),
                const SizedBox(height: 16),
              ],

              if (widget.adUrl2.isNotEmpty) ...[
                AdBannerWidget(mediaUrl: widget.adUrl2),
                const SizedBox(height: 16),
              ],

              if (previousSearchAuctions.isNotEmpty) ...[
                HorizontalProductList(
                  title: 'Based on Previous Search',
                  products: previousSearchAuctions,
                  source: 'previous',
                ),
                const SizedBox(height: 16),
              ],

              if (trendingAuctions.isNotEmpty) ...[
                HorizontalProductList(
                  title: 'Trending Auctions',
                  products: trendingAuctions,
                  source: 'trending',
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

  Widget debugLogWidget(String widgetName) {
    debugPrint('Rendering widget: $widgetName');
    return const SizedBox.shrink();
  }
}
