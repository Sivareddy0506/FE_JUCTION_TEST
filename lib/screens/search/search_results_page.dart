import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/search_bar_widget.dart';
import '../../services/search_service.dart';
import '../../services/filter_state_service.dart';
import '../services/api_service.dart';
import '../products/product_detail.dart';
import '../../services/profile_service.dart'; 

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  final Map<String, dynamic>? appliedFilters;
  final String? sortBy;

  const SearchResultsPage({
    super.key,
    required this.searchQuery,
    this.appliedFilters,
    this.sortBy,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<Product> searchResults = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  Map<String, String> _sellerNames = {}; // Seller names cache
  Map<String, int> _uniqueClicks = {};   // Product clicks cache

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
      // Perform search
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

      // Save search history
      if (widget.searchQuery.isNotEmpty) {
        await ApiService.saveSearchHistory(widget.searchQuery);
      }

      setState(() {
        searchResults = searchResult.products;
        isLoading = false;
      });

      // Prefetch product clicks
      await _fetchAllClicks();
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
    // await Future.wait(searchResults.map((product) async {
    //   final count = await ProductClickService.getUniqueClicks(product.id);
    //   clicksMap[product.id] = count;
    // }));

    setState(() {
      _uniqueClicks = clicksMap;
    });
  }

  void _handleProductClick(Product product) async {
    await ApiService.trackProductClick(product.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          if (hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _performSearch,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SearchBarWidget(
              initialQuery: widget.searchQuery,
              onSearch: (query) {
                if (query != widget.searchQuery) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchResultsPage(searchQuery: query),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
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
            ElevatedButton(onPressed: _performSearch, child: const Text('Try Again')),
          ],
        ),
      );
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/nodata.png', width: 200),
            const SizedBox(height: 16),
            const Text('Oops, no listings so far', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
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

              return GestureDetector(
                onTap: () => _handleProductClick(product),
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
                            const CircleAvatar(radius: 6, backgroundImage: AssetImage('assets/avatarpng.png')),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                product.seller?.fullName ?? 'Seller Name',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Views & location
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.remove_red_eye, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Viewed by ${_uniqueClicks[product.id] ?? 0} others',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Spacer(),
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(product.location ?? 'Unknown', style: const TextStyle(fontSize: 12)),
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
