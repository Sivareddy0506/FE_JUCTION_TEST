import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../../widgets/app_button.dart';
import '../../widgets/products_grid.dart';
import '../profile/empty_state.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  List<Product> relatedProducts = [];
  bool isLoadingRelated = true;

  @override
  void initState() {
    super.initState();
    _fetchRelatedProducts();
    _loadSellerName();
  }

  Future<void> _fetchRelatedProducts() async {
    setState(() => isLoadingRelated = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      debugPrint('ProductDetailPage: no auth token found.');
      setState(() => isLoadingRelated = false);
      return;
    }

    final uri = Uri.parse(
        'https://api.junctionverse.com/product/related/${widget.product.id}');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) {
        debugPrint(
            'ProductDetailPage: related API Error ${response.statusCode}');
        setState(() => isLoadingRelated = false);
        return;
      }

      final dynamic decoded = jsonDecode(response.body);

      final List<dynamic> data = () {
        if (decoded == null) return <dynamic>[];
        if (decoded is List) return decoded;
        if (decoded is Map<String, dynamic>) {
          if (decoded['products'] is List) return decoded['products'];
          if (decoded['data'] is List) return decoded['data'];
          if (decoded['items'] is List) return decoded['items'];
          final found = decoded.values.firstWhere(
            (v) => v is List,
            orElse: () => <dynamic>[],
          );
          return found is List ? found : <dynamic>[];
        }
        return <dynamic>[];
      }();

      final List<Product> fetched = data.map<Product>((item) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);

        final List<ProductImage> imageList = (map['images'] as List?)
                ?.map((imgRaw) {
                  final Map<String, dynamic> img =
                      Map<String, dynamic>.from(imgRaw);
                  return ProductImage(
                    fileUrl: img['fileUrl']?.toString() ??
                        'assets/images/placeholder.png',
                    fileType: img['fileType']?.toString(),
                    filename: img['filename']?.toString(),
                  );
                })
                .toList() ??
            [];

        final String imageUrl = imageList.isNotEmpty
            ? imageList.first.fileUrl
            : (map['imageUrl']?.toString() ??
                'assets/images/placeholder.png');

        final Seller? seller = (map['seller'] is Map<String, dynamic>)
            ? Seller.fromJson(Map<String, dynamic>.from(map['seller']))
            : null;

        return Product(
  id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
  images: imageList,
  imageUrl: imageUrl,
  title: map['title']?.toString() ??
      map['name']?.toString() ??
      'No title',
  price: map['price'] != null ? '₹${map['price']}' : null,
  description: map['description']?.toString(),
  location: map['pickupLocation']?.toString() ??
      map['locationName']?.toString(),
  seller: seller,
  isAuction: map['isAuction'] == true, // ✅ required param fix
);
      }).toList();

      setState(() {
        relatedProducts = fetched;
        isLoadingRelated = false;
      });
    } catch (e, st) {
      debugPrint(
          'ProductDetailPage: exception while fetching related: $e\n$st');
      setState(() => isLoadingRelated = false);
    }
  }

 @override
Widget build(BuildContext context) {
  final product = widget.product;

  return Scaffold(
    appBar: AppBar(title: Text(product.title)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Seller info block (no border, no extra spacing)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.transparent,
          child: Row(
            children: [
              Image.asset(
                'assets/avatarpng.png',
                width: 12,
                height: 12,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 8),
                             Text(
                 _sellerName ?? 
                 (product.seller?.fullName?.startsWith('Seller ') == true ? 
                  'Loading seller...' : 
                  product.seller?.fullName ?? 'Unknown Seller'),
                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
               ),
              const Spacer(),
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Combined block: Images + badges + category + title/price + views/location
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product images
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PageView(
                  children: product.images.isNotEmpty
                      ? product.images
                          .map((img) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  img.fileUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/placeholder.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ))
                          .toList()
                      : [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/placeholder.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        ],
                ),
              ),

              const SizedBox(height: 12),

              // Badges block (condition, usage, age)
              Wrap(
                spacing: 12,
                children: [
                  if (product.yearOfPurchase != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE3E3E3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Age: > ${DateTime.now().year - product.yearOfPurchase!}Y',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  if (product.usage != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE3E3E3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Usage: ${product.usage}',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  if (product.condition != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE3E3E3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Condition: ${product.condition}',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                ],
              ),

              if (product.category != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                   // color: Colors.white,
                   // borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.category!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF505050),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Title and Price block
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                 // color: Colors.white,
                  //borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF262626),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.price ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6705),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Views and location block
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                 // color: Colors.white,
                 // borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/Eye.png',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Viewed by ${product.views} others',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      product.location ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Favourite and Share buttons combined in one section with bg color #f9f9f9
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Favourite'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Combined Description and Pickup Location block with bg #f9f9f9
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                product.description ?? 'No description provided',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pickup Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                product.location ?? '',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Related products and chat button remain unchanged...
        const SizedBox(height: 16),

        const Text('Related Products',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (isLoadingRelated)
          const Center(child: CircularProgressIndicator())
        else if (relatedProducts.isEmpty)
          const EmptyState(text: 'No related products found.')
        else
          ProductGridWidget(products: relatedProducts),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.chat),
          label: const Text('Chat'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    ),
  );
}

String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minute(s) ago';
    return 'Just now';
  }
}
