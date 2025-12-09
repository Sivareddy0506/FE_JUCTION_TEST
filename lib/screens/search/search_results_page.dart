import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/search_bar_widget.dart';
import '../../services/search_service.dart';
import '../../services/filter_state_service.dart';
import '../services/api_service.dart';
import '../services/location_helper.dart';
import '../products/product_detail.dart';
import '../../services/profile_service.dart'; 
import '../../../widgets/custom_appbar.dart';
import '../../widgets/bottom_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../profile/user_profile.dart';
import '../profile/others_profile.dart';
import '../profile/empty_state.dart';
import '../../app.dart'; // For SlidePageRoute
import '../../widgets/app_button.dart';

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  final Map<String, dynamic>? appliedFilters;
  final String? sortBy;
  final String? title;

  const SearchResultsPage({
    super.key,
    required this.searchQuery,
    this.appliedFilters,
    this.sortBy,
    this.title,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<Product> searchResults = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  final Map<String, String> _sellerNames = {}; // Seller names cache
  Map<String, int> _uniqueClicks = {};   // Product clicks cache
  final Map<String, String> _locationCache = {}; // Location cache

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    FilterStateService.forceClearFilterState();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      final searchResult = await SearchService.searchProducts(
        query: widget.searchQuery.isNotEmpty ? widget.searchQuery : null,
        listingType: widget.appliedFilters?['listingType'],
        category: widget.appliedFilters?['category'],
        condition: widget.appliedFilters?['condition'],
        pickupMethod: widget.appliedFilters?['pickupMethod'],
        minPrice: widget.appliedFilters?['minPrice']?.toDouble(),
        maxPrice: widget.appliedFilters?['maxPrice']?.toDouble(),
        sortBy: widget.sortBy ?? 'Distance',
      );

      if (widget.searchQuery.isNotEmpty) {
        await ApiService.saveSearchHistory(widget.searchQuery);
      }

      // Store results first (needed for prefetch)
      searchResults = searchResult.products;

      // Prefetch all data BEFORE rendering
      await Future.wait([
        _fetchAllClicks(),
        _prefetchAllLocations(),
      ]);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAllClicks() async {
    final Map<String, int> clicksMap = {};
    final List<String> productIds = searchResults.map((p) => p.id).toList();
    final results = await ProductClickService.getUniqueClicksFor(productIds);
    clicksMap.addAll(results);
    _uniqueClicks = clicksMap;
  }

  Future<void> _prefetchAllLocations() async {
    final futures = <Future>[];

    for (final product in searchResults) {
      if (product.latitude != null &&
          product.longitude != null &&
          !_locationCache.containsKey(product.id)) {
        futures.add(_loadLocationForProduct(product));
      }
    }

    // Wait for all locations to be fetched
    await Future.wait(futures);
  }

  Future<void> _loadLocationForProduct(Product product) async {
    try {
      final location = await getAddressFromLatLng(
        product.latitude!,
        product.longitude!,
      );
      _locationCache[product.id] = location;
    } catch (e) {
      _locationCache[product.id] = 'Location unavailable';
    }
  }

  Future<void> _openSellerProfile(String sellerId) async {
    if (sellerId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    if (!mounted) return;
    if (sellerId == currentUserId) {
      Navigator.push(context, SlidePageRoute(page: const UserProfilePage()));
    } else {
      Navigator.push(context, SlidePageRoute(page: OthersProfilePage(userId: sellerId)));
    }
  }

  void _handleProductClick(Product product, int index) async {
    await ApiService.trackProductClick(product.id);
    Navigator.push(
      context,
      SlidePageRoute(
        page: ProductDetailPage(
          product: product,
          products: searchResults,
          initialIndex: index,
          initialUniqueClicks: _uniqueClicks,
          initialLocations: _locationCache,
        ),
      ),
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.title ?? 'Search Results'),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchBarWidget(
                initialQuery: widget.searchQuery,
                onSearch: (query) {
                  if (query != widget.searchQuery) {
                    Navigator.pushReplacement(
                      context,
                      SlidePageRoute(
                        page: SearchResultsPage(searchQuery: query, title: widget.title ?? 'Search Results'),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(activeItem: 'home', onTap: (_) {}),
    );
  }

  Widget _buildContent() {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Error searching for "${widget.searchQuery}"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Try Again',
              onPressed: _performSearch,
              backgroundColor: const Color(0xFFFF6705),
              textColor: Colors.white,
            ),
          ],
        ),
      );
    }

    if (searchResults.isEmpty) {
      return const EmptyState(text: 'Oops, no listings so far');
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${searchResults.length} result${searchResults.length == 1 ? '' : 's'} found',
                style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final product = searchResults[index];
              final imageUrl = product.images.isNotEmpty ? product.images[0].fileUrl : product.imageUrl;
              final sellerId = product.seller?.id ?? '';

              return GestureDetector(
                onTap: () => _handleProductClick(product, index),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seller row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _openSellerProfile(sellerId),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircleAvatar(radius: 6, backgroundImage: AssetImage('assets/avatarpng.png')),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      product.seller?.fullName ?? 'Seller',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Image.asset('assets/ClockCountdown.png', width: 14, height: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(product.createdAt != null ? _timeAgo(product.createdAt!) : '',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Product image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/placeholder.png',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Badges block
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (product.yearOfPurchase != null)
                              _badge('Age: > ${DateTime.now().year - product.yearOfPurchase!}Y'),
                            if (product.usage != null) _badge('Usage: ${product.usage}'),
                            if (product.condition != null) _badge('Condition: ${product.condition}'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Category, title, price
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.category ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(product.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(product.displayPrice,
                                style: const TextStyle(fontSize: 16, color: Color(0xFFFF6705), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Views & location
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Image.asset('assets/Eye.png', width: 16, height: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Viewed by ${_uniqueClicks[product.id] ?? 0} others',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Spacer(),
                            Image.asset('assets/MapPin.png', width: 16, height: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _locationCache[product.id] ?? product.location ?? 'Unknown',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE3E3E3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
    );
  }
}
