import 'package:flutter/material.dart';
import 'dart:async';  
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../screens/products/product_detail.dart';
import '../screens/services/location_helper.dart';
import '../services/favorites_service.dart';
import '../../app.dart'; // For SlidePageRoute
import '../services/cache_manager.dart';

class ProductGridWidget extends StatefulWidget {
  final List<Product> products;
  final VoidCallback? onFavoriteChanged;

  const ProductGridWidget({
    super.key, 
    required this.products,
    this.onFavoriteChanged,
  });

  @override
  State<ProductGridWidget> createState() => _ProductGridWidgetState();
}

class _ProductGridWidgetState extends State<ProductGridWidget> {
  late FavoritesService _favoritesService;

  @override
  void initState() {
    super.initState();
    _favoritesService = FavoritesService();
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
    if (mounted) setState(() {});
  }

  Future<void> _sendTrackRequest(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null || token.isEmpty) return;

      final uri = Uri.parse('https://api.junctionverse.com/api/history/track-click');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'productId': productId}),
      );

      if (response.statusCode == 200) {
        await CacheManager().invalidateCache(CacheConfig.lastViewedKey);
      }
    } catch (e) {
      debugPrint('Error tracking product click: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final idealWidth = screenWidth > 800 ? 210.0 : 170.0;
        int crossAxisCount = (constraints.maxWidth / idealWidth).clamp(2, 4).toInt();
        if (crossAxisCount < 2) crossAxisCount = 2;
        final itemCount = widget.products.length;
        final remainder = itemCount % crossAxisCount;
        final totalCount = remainder == 0 ? itemCount : itemCount + (crossAxisCount - remainder);
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: totalCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.65,
            crossAxisSpacing: screenWidth < 600 ? 8 : 12,
            mainAxisSpacing: screenWidth < 600 ? 8 : 12,
          ),
          itemBuilder: (context, index) {
            if (index >= itemCount) {
              return const SizedBox.shrink();
            }
            final product = widget.products[index];
            return ProductCard(
              product: product,
              onFavoriteChanged: widget.onFavoriteChanged,
              onTap: () {
                _sendTrackRequest(product.id);
                Navigator.push(
                  context,
                  SlidePageRoute(
                    page: ProductDetailPage(
                      product: product,
                      onFavoriteChanged: widget.onFavoriteChanged,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ------------------------- Product Card -------------------------
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onFavoriteChanged;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onFavoriteChanged,
    required this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late FavoritesService _favoritesService;
  String? _cachedLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _favoritesService = FavoritesService();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    if (widget.product.latitude != null &&
        widget.product.longitude != null &&
        _cachedLocation == null &&
        !_isLoadingLocation) {
      setState(() => _isLoadingLocation = true);

      try {
        final location = await getAddressFromLatLng(
          widget.product.latitude!,
          widget.product.longitude!,
        );

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add favorites')),
      );
      return;
    }

    final isFav = _favoritesService.isFavorited(productId);

    try {
      bool success;
      if (isFav) {
        success = await _favoritesService.removeFromFavorites(productId);
        if (success) {
          widget.onFavoriteChanged?.call();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites'), duration: Duration(seconds: 1)),
          );
        }
      } else {
        success = await _favoritesService.addToFavorites(productId);
        if (success) {
          widget.onFavoriteChanged?.call();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
  }
@override
Widget build(BuildContext context) {
  final isFav = _favoritesService.isFavorited(widget.product.id);

  return InkWell(
    onTap: widget.onTap,
    child: Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- IMAGE SECTION ----------------
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1.05,
                    child: Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset('assets/placeholder.png'),
                    ),
                  ),
                ),

                // ❤️ Favourite Icon — now bottom-right
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(widget.product.id),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0x33000000), // 0.2 opacity black
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? const Color(0xFFFF6705) : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ---------------- DETAILS SECTION ----------------
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product title
                    Text(
                      widget.product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF262626),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.3, // ~16px line height
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Price text
                    Text(
                      widget.product.price ?? '',
                      style: const TextStyle(
                        color: Color(0xFFFF6705),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Location Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/MapPin.png',
                          width: 10,
                          height: 10,
                          color: const Color(0xFF8A8894),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _cachedLocation ??
                                widget.product.location ??
                                'Location not set',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 8,
                              color: Color(0xFF8A8894),
                              fontWeight: FontWeight.normal,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}


// ------------------------- Auction Timer -------------------------
class AuctionTimerWidget extends StatefulWidget {
  final DateTime startDate;
  final int durationDays;

  const AuctionTimerWidget({
    super.key,
    required this.startDate,
    required this.durationDays,
  });

  @override
  State<AuctionTimerWidget> createState() => _AuctionTimerWidgetState();
}

class _AuctionTimerWidgetState extends State<AuctionTimerWidget> {
  late Duration remaining;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateRemaining());
  }

  void _calculateRemaining() {
    final endDate = widget.startDate.add(Duration(days: widget.durationDays));
    final now = DateTime.now();
    final diff = endDate.difference(now);
    setState(() {
      remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Widget _buildTimeBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (remaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Color(0xFFFF6705),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'LIVE',
          style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimeBox(hours),
        const Text(':', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        _buildTimeBox(minutes),
        const Text(':', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        _buildTimeBox(seconds),
      ],
    );
  }
}
