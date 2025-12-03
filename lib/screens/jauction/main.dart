import 'package:flutter/material.dart';
import '../../widgets/logo_icons_widget.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/jauction_coming_soon_widget.dart';
// TODO: Uncomment when restoring auction functionality
// import '../../widgets/category_grid.dart';
// import '../../models/product.dart';
// import '../products/horizontal_product_list.dart';
// import '../products/ad_banner_widget.dart';
// import '../services/auction_service.dart';



class JauctionHomePage extends StatefulWidget {
  final String adUrl1;
  final String adUrl2;

  const JauctionHomePage({
    super.key,
    this.adUrl1 = '',
    this.adUrl2 = '',
  });

  @override
  State<JauctionHomePage> createState() => _JauctionHomePageState();
}

class _JauctionHomePageState extends State<JauctionHomePage> {
  String activeTab = 'jauction';

  // TODO: Uncomment when restoring auction functionality
  // List<Product> upcomingAuctions = [];
  // List<Product> myCurrentAuctions = [];
  // List<Product> liveTodayAuctions = [];
  // List<Product> previousSearchAuctions = [];
  // List<Product> trendingAuctions = [];
  // bool isLoading = true;

  void handleTabChange(String selected) {
    debugPrint('JauctionHomePage: handleTabChange called with "$selected"');
    setState(() {
      activeTab = selected;
    });
  }

  // TODO: Uncomment when restoring auction functionality
  // @override
  // void initState() {
  //   super.initState();
  //   debugPrint('JauctionHomePage: initState called');
  //   _fetchAllSections();
  // }

  // TODO: Uncomment when restoring auction functionality
  // Future<void> _fetchAllSections() async {
  //   try {
  //     debugPrint('JauctionHomePage: Fetching auctions...');
  //     final upcoming = await AuctionService.fetchUpcomingAuctions();
  //     final current = await AuctionService.fetchMyCurrentAuctions();
  //     final today = await AuctionService.fetchLiveTodayAuctions();
  //     final previous = await AuctionService.fetchAuctionsByPreviousSearch();
  //     final trending = await AuctionService.fetchTrendingAuctions();

  //     setState(() {
  //       upcomingAuctions = upcoming;
  //       myCurrentAuctions = current;
  //       liveTodayAuctions = today;
  //       previousSearchAuctions = previous;
  //       trendingAuctions = trending;
  //       isLoading = false;
  //     });

  //     debugPrint("✅ Auctions fetched successfully");
  //   } catch (e, stacktrace) {
  //     debugPrint('❌ Error loading auction data: $e');
  //     debugPrint(stacktrace.toString());
  //     setState(() => isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    debugPrint('JauctionHomePage: build called');

  // TODO: Uncomment when restoring auction functionality
  // Widget content;
  // 
  // if (isLoading) {
  //   content = const Center(child: CircularProgressIndicator());
  // } else {
  //   content = SafeArea(
  //     minimum: const EdgeInsets.only(top: 24), // extra push-down (same as home page)
  //     child: SingleChildScrollView(
  //       padding: const EdgeInsets.symmetric(horizontal: 16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           debugLogWidget('LogoAndIconsWidget'),
  //           const LogoAndIconsWidget(),
  //           const SizedBox(height: 16),
    //           debugLogWidget('SearchBarWidget'),
    //           const SearchBarWidget(),
    //           const SizedBox(height: 16),
    //           const SizedBox(height: 130, child: CategoryGrid()), // Category grid height finalised at 130px
    //           const SizedBox(height: 8),

    //           if (upcomingAuctions.isNotEmpty) ...[
    //             HorizontalProductList(
    //               title: 'Upcoming Auctions',
    //               products: upcomingAuctions,
    //               source: 'upcoming',
    //             ),
    //             const SizedBox(height: 16),
    //           ],

    //           if (widget.adUrl1.isNotEmpty) ...[
    //             AdBannerWidget(mediaUrl: widget.adUrl1),
    //             const SizedBox(height: 16),
    //           ],

    //           if (myCurrentAuctions.isNotEmpty) ...[
    //             HorizontalProductList(
    //               title: 'My Current Auctions',
    //               products: myCurrentAuctions,
    //               source: 'current',
    //             ),
    //             const SizedBox(height: 16),
    //           ],

    //           if (liveTodayAuctions.isNotEmpty) ...[
    //             HorizontalProductList(
    //               title: 'Today\'s Auctions',
    //               products: liveTodayAuctions,
    //               source: 'today',
    //             ),
    //             const SizedBox(height: 16),
    //           ],

    //           if (widget.adUrl2.isNotEmpty) ...[
    //             AdBannerWidget(mediaUrl: widget.adUrl2),
    //             const SizedBox(height: 16),
    //           ],

    //           if (previousSearchAuctions.isNotEmpty) ...[
    //             HorizontalProductList(
    //               title: 'Based on Previous Search',
    //               products: previousSearchAuctions,
    //               source: 'previous',
    //             ),
    //             const SizedBox(height: 16),
    //           ],

    //           if (trendingAuctions.isNotEmpty) ...[
    //             HorizontalProductList(
    //               title: 'Trending Auctions',
    //               products: trendingAuctions,
    //               source: 'trending',
    //             ),
    //             const SizedBox(height: 16),
    //           ],

    //           const SizedBox(height: 30),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    // Current implementation - Coming Soon screen
    Widget content = SafeArea(
      minimum: const EdgeInsets.only(top: 24), // extra push-down (same as home page)
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const LogoAndIconsWidget(),
          ),
          const SizedBox(height: 16),
          // TODO: Uncomment when restoring auction functionality
          // const SearchBarWidget(),
          // const SizedBox(height: 16),
          const Expanded(
            child: JauctionComingSoonWidget(),
          ),
        ],
      ),
    );

    return BottomNavWrapper(
      activeItem: activeTab,
      onTap: handleTabChange,
      child: content,
    );
  }

  // TODO: Uncomment when restoring auction functionality
  // Widget debugLogWidget(String widgetName) {
  //   debugPrint('Rendering widget: $widgetName');
  //   return const SizedBox.shrink();
  // }
}
