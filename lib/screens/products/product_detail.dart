import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:junction/screens/Chat/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../../widgets/app_button.dart';
import '../../widgets/products_grid.dart';
import '../profile/empty_state.dart';
import '../../services/favorites_service.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final VoidCallback? onFavoriteChanged; // Add callback for favorite changes

  const ProductDetailPage({
    super.key, 
    required this.product,
    this.onFavoriteChanged,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}


Future<void> _shareProduct(BuildContext context, Product product) async {
  try {
    String text = '''
${product.title}
${product.price ?? ''}

${product.description ?? ''}

Location: ${product.location ?? 'N/A'}

Check this out on JunctionVerse!
https://junctionverse.com/product/${product.id}
''';

    if (product.imageUrl.isNotEmpty) {
      final response = await http.get(Uri.parse(product.imageUrl));
      final bytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/product_${product.id}.jpg');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
      );
    } else {
      await Share.share(text);
    }
  } catch (e) {
    debugPrint('❌ Error sharing product: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to share product')),
    );
  }
}


class _ProductDetailPageState extends State<ProductDetailPage> {
  List<Product> relatedProducts = [];
  bool isLoadingRelated = true;
  final ChatService _chatService = ChatService();
  late FavoritesService _favoritesService;
  String? _sellerName;

  @override
  void initState() {
    super.initState();
    _favoritesService = FavoritesService();
    // Defer listener registration to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _favoritesService.addListener(_onFavoritesChanged);
    });
    _fetchRelatedProducts();
    _loadSellerName();
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    setState(() {
      // Trigger rebuild when favorites change
    });
  }

  Future<void> _loadSellerName() async {
    debugPrint('🔍 Starting seller name fetch for product: ${widget.product.id}');
    debugPrint('🔍 Current seller: ${widget.product.seller?.toString()}');
    
    if (widget.product.seller != null) {
      final currentName = widget.product.seller!.fullName;
      debugPrint('🔍 Current seller name: "$currentName"');
      
      // Check if name is just an ID (multiple patterns)
      final isIdPattern = currentName.startsWith('Seller ') && 
                         (currentName.contains('...') || currentName.length > 20);
      
      if (isIdPattern || currentName.isEmpty || currentName == 'Unknown Seller') {
        debugPrint('🔍 Detected ID pattern, fetching actual seller name...');
        await _fetchActualSellerName();
      } else {
        debugPrint('🔍 Using existing seller name: $currentName');
        _sellerName = currentName;
      }
    } else {
      debugPrint('🔍 No seller information available');
    }
  }

  Future<void> _fetchActualSellerName() async {
    try {
      final sellerId = widget.product.seller!.id;
      debugPrint('🔍 Fetching seller details for ID: $sellerId');
      
      final sellerDetails = await ApiService.fetchSellerDetails(sellerId);
      
      if (sellerDetails != null && mounted) {
        final actualName = sellerDetails['fullName'] ?? 
                          sellerDetails['name'] ?? 
                          sellerDetails['firstName'] ?? 
                          sellerDetails['displayName'] ??
                          'Unknown Seller';
        
        debugPrint('🔍 Fetched seller name: $actualName');
        
        setState(() {
          _sellerName = actualName;
        });
      } else {
        debugPrint('❌ No seller details returned from API');
      }
    } catch (e) {
      debugPrint('❌ Error fetching seller details: $e');
      // Set fallback name
      if (mounted) {
        setState(() {
          _sellerName = 'Seller ${widget.product.seller!.id.substring(0, 8)}...';
        });
      }
    }
  }


  Future<void> _toggleFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add favorites')),
      );
      return;
    }

    try {
      if (_favoritesService.isFavorited(productId)) {
        // Remove from favorites using the global service
        final success = await _favoritesService.removeFromFavorites(productId);
        if (success) {
          widget.onFavoriteChanged?.call(); // Notify parent of change
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove from favorites')),
          );
        }
      } else {
        // Add to favorites using the global service
        final success = await _favoritesService.addToFavorites(productId);
        if (success) {
          widget.onFavoriteChanged?.call(); // Notify parent of change
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add to favorites')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
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

  void startChat(BuildContext context) async {
    try {
      String sellerId = widget.product.seller?.id ?? '';
      String buyerId = _chatService.currentUserId;
      String productId = widget.product.id;
      String chatId = '${productId}_${sellerId}_$buyerId';
      final prefs = await SharedPreferences.getInstance();
      String buyerName = prefs.getString('fullName') ?? 'You';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      bool exists = await _chatService.chatExists(chatId);
      
      if (!exists) {
        await _chatService.createChat(
          productId: productId,
          sellerId: sellerId,
          buyerId: buyerId,
          sellerName: widget.product.seller?.fullName ?? 'Seller',
          buyerName: buyerName,
          productTitle: widget.product.title,
          productImage: widget.product.imageUrl,
          productPrice: widget.product.price?.toString() ?? '0',
        );
      }

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(chatId: chatId),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                   onPressed: _favoritesService.isLoading ? null : () => _toggleFavorite(product.id),
                   icon: _favoritesService.isLoading
                       ? const SizedBox(
                           width: 20,
                           height: 20,
                           child: CircularProgressIndicator(
                             strokeWidth: 2,
                             valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                           ),
                         )
                       : Icon(
                           _favoritesService.isFavorited(product.id) ? Icons.favorite : Icons.favorite_border,
                           color: _favoritesService.isFavorited(product.id) ? Colors.deepOrange : null,
                         ),
                   label: _favoritesService.isLoading
                       ? const Text('Loading...')
                       : Text(_favoritesService.isFavorited(product.id) ? 'Favourited' : 'Favourite'),
                 ),
               ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _shareProduct(context, product),
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
          onPressed: () {
            startChat(context);
          },
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