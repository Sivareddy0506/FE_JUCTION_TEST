import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/search_bar_widget.dart';
import '../services/api_service.dart';
import '../products/product_detail.dart';

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;

  const SearchResultsPage({
    super.key,
    required this.searchQuery,
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

  Future<void> _performSearch() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      // Save search history first
      await ApiService.saveSearchHistory(widget.searchQuery);
      
      // Then perform the search
      final results = await ApiService.searchProducts(widget.searchQuery);
      setState(() {
        searchResults = results;
        isLoading = false;
      });
      
      // Fetch seller names for products that need them
      _fetchSellerNames();
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSellerNames() async {
    debugPrint('🔍 Starting to fetch seller names for ${searchResults.length} products');
    
    for (final product in searchResults) {
      if (product.seller != null) {
        final currentName = product.seller!.fullName;
        debugPrint('🔍 Product ${product.id}: Current seller name = "$currentName"');
        
        // Check if name is just an ID (multiple patterns)
        final isIdPattern = currentName.startsWith('Seller ') && 
                           (currentName.contains('...') || currentName.length > 20);
        
        debugPrint('🔍 Product ${product.id}: Is ID pattern = $isIdPattern');
        
        if (isIdPattern || currentName.isEmpty || currentName == 'Unknown Seller') {
          debugPrint('🔍 Fetching actual seller name for product ${product.id}, seller ID: ${product.seller!.id}');
          await _fetchActualSellerName(product.seller!.id);
        } else {
          debugPrint('🔍 Using existing seller name for product ${product.id}: $currentName');
        }
      } else {
        debugPrint('🔍 Product ${product.id}: No seller information');
      }
    }
  }

  Future<void> _fetchActualSellerName(String sellerId) async {
    try {
      debugPrint('🔍 Fetching seller details for ID: $sellerId');
      final sellerDetails = await ApiService.fetchSellerDetails(sellerId);
      
      if (sellerDetails != null && mounted) {
        final actualName = sellerDetails['fullName'] ?? 
                          sellerDetails['name'] ?? 
                          sellerDetails['firstName'] ?? 
                          sellerDetails['displayName'] ??
                          'Unknown Seller';
        
        debugPrint('🔍 Fetched seller name for $sellerId: $actualName');
        
        setState(() {
          _sellerNames[sellerId] = actualName;
        });
      } else {
        debugPrint('❌ No seller details returned for $sellerId');
      }
    } catch (e) {
      debugPrint('❌ Error fetching seller details for $sellerId: $e');
    }
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Searching for "${widget.searchQuery}"...'),
          ],
        ),
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
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "${widget.searchQuery}"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try different keywords or browse categories',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
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
                            'assets/images/placeholder.png',
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
