import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/search_bar_widget.dart';
import '../services/api_service.dart';
import './product_detail.dart';
import '../services/location_helper.dart';
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
  Map<String, String> _sellerNames = {}; // Cache for seller names
  Map<String, String> _locationCache = {}; //Cache for location (productId -> location string)


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
  void initState() {
    super.initState();
    fetchSectionProducts();
  }

  Future<void> fetchSectionProducts() async {
    List<Product> result = [];

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

    setState(() {
      products = result;
      isLoading = false;
    });
  }

  Future<void> _loadLocation(Product product) async {
  if (product.latitude != null &&
      product.longitude != null &&
      !_locationCache.containsKey(product.id)) {
    try {
      final location = await getAddressFromLatLng(
        product.latitude!,
        product.longitude!,
      );
      if (mounted) {
        setState(() {
          _locationCache[product.id] = location;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }
}

  Future<void> _handleProductClick(Product product) async {
    await ApiService.trackProductClick(product.id); // 🔥 track the click
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
      ),
    );
  }

  // Removed external seller fetch; rely on product.seller.fullName

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SearchBarWidget(),
            const SizedBox(height: 8),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                    itemBuilder: (context, index) {
  final product = products[index];

  final imageUrl = product.images.isNotEmpty
      ? product.images[0].fileUrl
      : product.imageUrl;

  final ageText = product.yearOfPurchase != null
      ? '${DateTime.now().year - product.yearOfPurchase!} Y'
      : 'N/A';
//Load location
_loadLocation(product);
final locationString = _locationCache[product.id] ?? product.location ?? 'Unknown';

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
                  backgroundImage: AssetImage('assets/avatarpng.png'),
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
                Text(locationString, style: const TextStyle(fontSize: 12)),
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
    );
  }
}
