import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:junction/screens/Chat/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../../widgets/products_grid.dart';
import '../profile/empty_state.dart';
import '../../services/favorites_service.dart';
import '../services/chat_service.dart';
import '../../services/view_tracker.dart';
import '../services/location_helper.dart';
import '../../services/profile_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final VoidCallback? onFavoriteChanged;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.onFavoriteChanged,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  List<Product> relatedProducts = [];
  bool isLoadingRelated = true;
  final ChatService _chatService = ChatService();
  late FavoritesService _favoritesService;
  String? _sellerName;
  int _displayViews = 0;
  bool _registeredView = false;
  String? _cachedLocation;
  bool _isLoadingLocation = false;
  int _viewCount = 0;

  @override
  void initState() {
    super.initState();
    _favoritesService = FavoritesService();
    _displayViews = widget.product.views ?? 0;

    if (!ViewTracker.instance.isViewed(widget.product.id)) {
      _displayViews += 1;
      ViewTracker.instance.markViewed(widget.product.id);
      _registeredView = true;
    }

    _loadSellerName();
    _loadProductLocation();
    _fetchRelatedProducts();
    _fetchUniqueClicks();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _favoritesService.addListener(_onFavoritesChanged);
    });
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    setState(() {}); 
  }

  Future<void> _loadSellerName() async {
    final name = widget.product.seller?.fullName;
    setState(() {
      _sellerName = (name != null && name.isNotEmpty) ? name : 'Unknown Seller';
    });
  }

  Future<void> _loadProductLocation() async {
    if ((widget.product.location == null || widget.product.location!.isEmpty) &&
        widget.product.latitude != null &&
        widget.product.longitude != null &&
        _cachedLocation == null &&
        !_isLoadingLocation) {
      setState(() => _isLoadingLocation = true);

      try {
        final location = await getAddressFromLatLng(
            widget.product.latitude!, widget.product.longitude!);
        if (mounted) {
          setState(() {
            _cachedLocation = location;
            _isLoadingLocation = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading location: $e');
        if (mounted) {
          setState(() {
            _cachedLocation = 'Location unavailable';
            _isLoadingLocation = false;
          });
        }
      }
    }
  }

  Future<void> _toggleFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login to add favorites')));
      return;
    }

    try {
      if (_favoritesService.isFavorited(productId)) {
        final success = await _favoritesService.removeFromFavorites(productId);
        if (success) widget.onFavoriteChanged?.call();
      } else {
        final success = await _favoritesService.addToFavorites(productId);
        if (success) widget.onFavoriteChanged?.call();
      }
      setState(() {});
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Network error. Please try again.')));
    }
  }

  Future<void> _fetchRelatedProducts() async {
    setState(() => isLoadingRelated = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      setState(() => isLoadingRelated = false);
      return;
    }

    final uri =
        Uri.parse('https://api.junctionverse.com/product/related/${widget.product.id}');
    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) {
        setState(() => isLoadingRelated = false);
        return;
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['products'] ?? [];

      final List<Product> fetched = data.map<Product>((item) {
        final map = Map<String, dynamic>.from(item);
        final List<ProductImage> imageList = (map['images'] as List?)
                ?.map((imgRaw) {
                  final img = Map<String, dynamic>.from(imgRaw);
                  return ProductImage(
                    fileUrl: img['fileUrl'] ?? 'assets/placeholder.png',
                    fileType: img['fileType'],
                    filename: img['filename'],
                  );
                }).toList() ??
            [];

        final Seller? seller = map['seller'] != null
            ? Seller.fromJson(Map<String, dynamic>.from(map['seller']))
            : null;

        return Product(
          id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
          images: imageList,
          imageUrl: imageList.isNotEmpty
              ? imageList.first.fileUrl
              : (map['imageUrl']?.toString() ?? 'assets/placeholder.png'),
          title: map['title']?.toString() ?? 'No title',
          price: map['price'] != null ? '₹${map['price']}' : null,
          description: map['description']?.toString(),
          location: map['pickupLocation']?.toString() ??
              map['locationName']?.toString(),
          seller: seller,
          isAuction: map['isAuction'] == true,
          views: int.tryParse((map['views'] ?? map['viewCount'] ?? '0').toString()) ?? 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          relatedProducts = fetched;
          isLoadingRelated = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching related products: $e');
      if (mounted) setState(() => isLoadingRelated = false);
    }
  }

  Future<void> _fetchUniqueClicks() async {
    // try {
    //   final clicks = await ProductClickService.getUniqueClicks(widget.product.id);
    //   if (mounted) {
    //     setState(() {
    //       _displayViews = (_registeredView ? _displayViews : clicks);
    //     });
    //   }
    // } catch (e) {
    //   debugPrint('Error fetching unique clicks: $e');
    // }
    final result = await ProductClickService.getUniqueClicksFor([widget.product.id]);
    setState(() {
          _viewCount = result[widget.product.id] ?? 0;
        });
  }

  void startChat(BuildContext context) async {
    if (widget.product.seller?.id == _chatService.currentUserId) return;

    try {
      String sellerId = widget.product.seller?.id ?? '';
      String buyerId = _chatService.currentUserId;
      String productId = widget.product.id;
      String chatId = '${productId}_${sellerId}_$buyerId';
      final prefs = await SharedPreferences.getInstance();
      String buyerName = prefs.getString('fullName') ?? 'You';

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

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bool isSellerViewing = product.seller?.id == _chatService.currentUserId;
    final bool isProductForSale = product.status == 'For Sale';
    final bool isDealLocked = product.status == 'Sold' || product.status == 'Locked';

    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).padding.bottom + 80),
        children: [
          // Seller info
          Row(
            children: [
              Image.asset('assets/avatarpng.png', width: 12, height: 12),
              const SizedBox(width: 8),
              Text(_sellerName ?? 'Loading seller...',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Row(
                children: [
                  Image.asset('assets/ClockCountdown.png', width: 14, height: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    product.createdAt != null ? _timeAgo(product.createdAt!) : '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product images
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: PageView(
              children: product.images.isNotEmpty
                  ? product.images
                      .map((img) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              img.fileUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                            ),
                          ))
                      .toList()
                  : [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                      )
                    ],
            ),
          ),

          const SizedBox(height: 12),

          // Badges (Age, Usage, Condition)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (product.yearOfPurchase != null)
                _buildBadge('Age: > ${DateTime.now().year - product.yearOfPurchase!}Y'),
              if (product.usage != null) _buildBadge('Usage: ${product.usage}'),
              if (product.condition != null) _buildBadge('Condition: ${product.condition}'),
            ],
          ),
          const SizedBox(height: 16),

          if (product.category != null)
            Text(product.category!, style: const TextStyle(fontSize: 10, color: Color(0xFF505050))),

          const SizedBox(height: 12),

          // Title & Price
          Text(product.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(product.price ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF6705))),

          const SizedBox(height: 12),

          // Views & Location
          Row(
            children: [
              Image.asset('assets/Eye.png', width: 16, height: 16),
              const SizedBox(width: 4),
              // Text('Viewed by $_displayViews others'),
              Text('Viewed by $_viewCount others'),
              const Spacer(),
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: _buildLocationText(product)),
            ],
          ),
          const SizedBox(height: 16),
// Favorite & Share
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFFF9F9F9),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      // Favorite button
      Expanded(
        child: TextButton.icon(
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: _favoritesService.isLoading
              ? null
              : () => _toggleFavorite(product.id),
          icon: _favoritesService.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                )
              : Icon(
                  _favoritesService.isFavorited(product.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: _favoritesService.isFavorited(product.id)
                      ? Color(0xFFFF6705)
                      : Colors.black54,
                ),
          label: _favoritesService.isLoading
              ? const Text('Loading...')
              : Text(
                  _favoritesService.isFavorited(product.id)
                      ? 'Favourited'
                      : 'Favourite',
                ),
        ),
      ),

      // Divider
      Container(
        height: 40,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.grey.shade300,
      ),

      // Share button
      Expanded(
        child: TextButton.icon(
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {},
          icon: const Icon(Icons.share, color: Colors.black54),
          label: const Text('Share'),
        ),
      ),
    ],
  ),
),
const SizedBox(height: 16),


          // Description & Pickup Location
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Text(product.description ?? 'No description provided', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300, thickness: 1),
                const SizedBox(height: 16),
                const Text('Pickup Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                _buildLocationText(product),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Deal Status Badge
          if (isDealLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Product Deal is Locked!',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Related Products
          const Text('Related Products', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (isLoadingRelated)
            const Center(child: CircularProgressIndicator())
          else if (relatedProducts.isEmpty)
            const EmptyState(text: 'No related products found.')
          else
            ProductGridWidget(products: relatedProducts),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isSellerViewing, isProductForSale, isDealLocked),
    );
  }

  Widget? _buildBottomNavigationBar(bool isSellerViewing, bool isProductForSale, bool isDealLocked) {
    // Don't show bottom bar for seller viewing their own product
    if (isSellerViewing) {
      return null;
    }

    // If deal is locked, show appropriate buttons
    if (isDealLocked) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Mark as Sold button (for seller)
              if (widget.product.seller?.id == _chatService.currentUserId)
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _showMarkAsSoldDialog(),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark as Sold'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              
              // User Rating button (for buyer)
              if (widget.product.seller?.id != _chatService.currentUserId)
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _showUserRating(),
                      icon: const Icon(Icons.star_outline),
                      label: const Text('Rate User'),
                      style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFFFF6705),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // If product is not for sale, show disabled chat button
    if (!isProductForSale) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null, // Disabled
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.grey[600],
                side: const BorderSide(color: Color(0xFFE3E3E3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      );
    }

    // Default chat button for products that are for sale
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => startChat(context),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFE3E3E3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
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
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
    );
  }

  Widget _buildLocationText(Product product) {
    if (product.location != null && product.location!.isNotEmpty) {
      return Text(product.location!, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    if (_cachedLocation != null && _cachedLocation != 'Location unavailable') {
      return Text(_cachedLocation!, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    if (_isLoadingLocation) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey))),
          SizedBox(width: 8),
          Text('Loading location...', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      );
    }
    return const Text('Location not set', style: TextStyle(fontSize: 14, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minute(s) ago';
    return 'Just now';
  }

  void _showMarkAsSoldDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark as Sold'),
          content: const Text('Are you sure you want to mark this product as sold? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markProductAsSold();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Mark as Sold', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showUserRating() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rate User'),
          content: const Text('Rate your experience with this seller.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _rateUser();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6705)),
              child: const Text('Submit Rating', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markProductAsSold() async {
    try {
      // Call API to mark product as sold
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to perform this action')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('https://api.junctionverse.com/product/mark-sold'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productId': widget.product.id,
          'buyerId': _chatService.currentUserId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product marked as sold successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Update product status locally
        setState(() {
          // This would need to be handled by refreshing the product data
        });
      } else {
        throw Exception('Failed to mark product as sold');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rateUser() async {
    try {
      // Call API to rate user
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to perform this action')),
        );
        return;
      }

      // For now, just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
