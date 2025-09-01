import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/search_bar_widget.dart';
import '../../services/search_service.dart';
import '../../services/filter_state_service.dart';
import '../services/api_service.dart';
import '../products/product_detail.dart';

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
  Map<String, String> _sellerNames = {}; // Cache for seller names

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    // Clear filter state when user exits search results page
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
      // Always use enhanced search service with location-based filtering
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
      
      // Save search history if query was provided
      if (widget.searchQuery.isNotEmpty) {
        await ApiService.saveSearchHistory(widget.searchQuery);
      }
      
      setState(() {
        searchResults = searchResult.products;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Removed external seller fetch; rely on product.seller.fullName

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
                // Handle new search if needed
                if (query != widget.searchQuery) {
                  // Navigate to new search results
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
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
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
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Try Again'),
            ),
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
            const Text(
              'Oops, no listings so far',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
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

              final imageUrl = product.images.isNotEmpty
                  ? product.images[0].fileUrl
                  : product.imageUrl;

              final ageText = product.yearOfPurchase != null
                  ? '${DateTime.now().year - product.yearOfPurchase!} Y'
                  : 'N/A';

              return GestureDetector(
                onTap: () => _handleProductClick(product),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seller info row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: const AssetImage('assets/avatarpng.png'),
                            ),
                            const SizedBox(width: 8),
                                                         Expanded(
                               child: Builder(
                                 builder: (context) {
                                   final sellerId = product.seller?.id;
                                   final cachedName = _sellerNames[sellerId];
                                   final originalName = product.seller?.fullName;
                                   final displayName = cachedName ?? originalName ?? 'Seller Name';
                                   
                                   debugPrint('🔍 Displaying seller name for product ${product.id}: cached="$cachedName", original="$originalName", final="$displayName"');
                                   
                                   return Text(
                                     displayName,
                                     style: const TextStyle(fontWeight: FontWeight.w500),
                                   );
                                 },
                               ),
                             ),
                            Text(
                              _timeAgo(product.createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
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

                      // Chips: Age, Usage, Condition
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            Chip(label: Text('Age: > $ageText')),
                            Chip(label: Text('Usage: ${product.usage ?? 'N/A'}')),
                            Chip(label: Text('Condition: ${product.condition ?? 'N/A'}')),
                          ],
                        ),
                      ),

                      // Category, Title & price
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.category ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.displayPrice,
                              style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                                             // Views & location row
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         child: Row(
                           children: [
                             const Icon(Icons.remove_red_eye, size: 16, color: Colors.grey),
                             const SizedBox(width: 4),
                             Text('Viewed by ${product.views ?? 0} others', style: const TextStyle(fontSize: 12)),
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
}
