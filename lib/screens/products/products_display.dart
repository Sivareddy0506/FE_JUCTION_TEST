import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/search_bar_widget.dart';
import '../services/api_service.dart';
import './product_detail.dart';
import '../services/location_helper.dart';
import '../../services/profile_service.dart';
import '../../../widgets/custom_appbar.dart';
import '../../widgets/bottom_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../profile/user_profile.dart';
import '../profile/others_profile.dart';
import '../../app.dart'; // For SlidePageRoute

class ProductListingPage extends StatefulWidget {
  final String title;
  final String source; // "fresh", "trending", "lastViewed", "searched"

  const ProductListingPage({
    super.key,
    required this.title,
    required this.source,
  });

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  List<Product> products = [];
  bool isLoading = true;

  // Caches
  final Map<String, String> _sellerNames = {};
  final Map<String, String> _locationCache = {};
  Map<String, int> _uniqueClicks = {};

  @override
  void initState() {
    super.initState();
    fetchSectionProducts();
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

  Future<void> fetchSectionProducts() async {
    List<Product> result = [];

    try {
      switch (widget.source) {
        case 'fresh':
          result = await ApiService.fetchAllProducts();
          break;
        case 'trending':
          result = await ApiService.fetchMostClicked();
          break;
        case 'lastViewed':
          result = await ApiService.fetchLastOpened();
          break;
        case 'searched':
          result = await ApiService.fetchLastSearched();
          break;
        default:
          result = [];
      }

      // Store products first (needed for prefetch)
      products = result;

      // Prefetch all data BEFORE rendering
      await Future.wait([
        _fetchAllClicks(),
        _prefetchAllLocations(),
      ]);

      if (mounted) {
        setState(() {
          isLoading = false; // Only now allow rendering
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAllClicks() async {
    final Map<String, int> clicksMap = {};
    final List<String> productIds = products.map((p) => p.id).toList();
    final results = await ProductClickService.getUniqueClicksFor(productIds);
    clicksMap.addAll(results);

    setState(() {
      _uniqueClicks = clicksMap;
    });
  }

  Future<void> _prefetchAllLocations() async {
    final futures = <Future>[];

    for (final product in products) {
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

  Future<void> _handleProductClick(Product product, int index) async {
    await ApiService.trackProductClick(product.id); // track click
    Navigator.push(
      context,
      SlidePageRoute(
        page: ProductDetailPage(
          product: product,
          products: products, // Pass in product list
          initialIndex: index, // Pass in list index
          initialUniqueClicks: _uniqueClicks,
          initialLocations: _locationCache,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold
    (
      appBar: CustomAppBar(title: widget.title),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SearchBarWidget(),
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    // Location is already prefetched
                    final locationString = _locationCache[product.id] ??
                        product.location ??
                        'Unknown';

                    // Seller name caching
                    final sellerId = product.seller?.id ?? '';
                    final cachedName = _sellerNames[sellerId];
                    final displayName =
                        cachedName ?? product.seller?.fullName ?? 'Seller';

                    final imageUrl = product.images.isNotEmpty
                        ? product.images[0].fileUrl
                        : product.imageUrl;

                    return GestureDetector(
                      onTap: () => _handleProductClick(product, index),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seller & timestamp row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                             child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    // 👤 Seller section (left-aligned)
    GestureDetector(
      onTap: () => _openSellerProfile(sellerId),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 6,
            backgroundImage: AssetImage('assets/avatarpng.png'),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),

    // ⏰ Time section (right-aligned)
    Row(
      children: [
        Image.asset(
          'assets/ClockCountdown.png',
          width: 14,
          height: 14,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          product.createdAt != null ? _timeAgo(product.createdAt!) : '',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    ),
  ],
),

                            ),

                            // Product image
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
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

                            // Badges: Age, Usage, Condition
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Wrap(
                                spacing: 12,
                                children: [
                                  if (product.yearOfPurchase != null)
                                    _buildBadge(
                                        'Age: > ${DateTime.now().year - product.yearOfPurchase!}Y'),
                                  if (product.usage != null)
                                    _buildBadge('Usage: ${product.usage}'),
                                  if (product.condition != null)
                                    _buildBadge(
                                        'Condition: ${product.condition}'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Category, Title, Price
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.category ?? '',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.title,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.displayPrice,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: const Color(0xFFFF6705),

                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Views & Location
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Image.asset('assets/Eye.png', width: 16, height: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                      'Viewed by ${_uniqueClicks[product.id] ?? 0} others',
                                      style:
                                          const TextStyle(fontSize: 12)),
                                  const Spacer(),
                                  Image.asset('assets/MapPin.png', width: 16, height: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(locationString,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
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
        ),
      ),
      bottomNavigationBar: BottomNavBar(activeItem: 'home', onTap: (_) {}),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE3E3E3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: Colors.black87)),
    );
  }
}
