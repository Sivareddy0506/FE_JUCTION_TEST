import 'package:flutter/material.dart';
import 'dart:async';  
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../screens/products/product_detail.dart';
import '../screens/services/location_helper.dart';
import '../services/favorites_service.dart';

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
      await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'productId': productId}),
      );
    } catch (e) {
      debugPrint('Error tracking product click: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = 170.0;
        int crossAxisCount = (constraints.maxWidth / tileWidth).floor();
        if (crossAxisCount < 2) crossAxisCount = 2;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.70,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final product = widget.products[index];
            return ProductCard(
              product: product,
              onFavoriteChanged: widget.onFavoriteChanged,
              onTap: () {
                _sendTrackRequest(product.id);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(
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
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1.2),
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
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1.05,
                    child: Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset('assets/placeholder.png'),
                    ),
                  ),
                ),

                // Product Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF262626),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Price
                        Text(
                          widget.product.price ?? '',
                          style: TextStyle(
                            color: widget.product.isAuction ? Colors.deepOrange : const Color(0xFFFF6705),
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Bottom row: Location left, favorite right
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildLocationWidget()),
                            if (!widget.product.isAuction)
                              _favoritesService.isLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () => _toggleFavorite(widget.product.id),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          isFav ? Icons.favorite : Icons.favorite_border,
                                          color: isFav ? Colors.deepOrange : Colors.grey,
                                          size: 16,
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

            // Auction Timer top-right
            if (widget.product.isAuction &&
                widget.product.bidStartDate != null &&
                widget.product.duration != null)
              Positioned(
                top: 10,
                right: 10,
                child: AuctionTimerWidget(
                  startDate: widget.product.bidStartDate!,
                  durationDays: widget.product.duration!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationWidget() {
    if (widget.product.location != null && widget.product.location!.isNotEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/MapPin.png', width: 10, height: 10, color: const Color(0xFF8A8894)),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              widget.product.location!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 8, color: Color(0xFF8A8894)),
            ),
          ),
        ],
      );
    }

    if (widget.product.latitude != null && widget.product.longitude != null) {
      if (_cachedLocation != null && _cachedLocation != 'Location unavailable') {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 14, color: Color(0xFF8A8894)),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                _cachedLocation!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 7, color: Color(0xFF8A8894)),
              ),
            ),
          ],
        );
      } else if (_isLoadingLocation) {
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 14, color: Color(0xFF8A8894)),
            SizedBox(width: 2),
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A8894)),
              ),
            ),
          ],
        );
      }
    }

    return const Text(
      'Location not set',
      style: TextStyle(fontSize: 7, color: Color(0xFF8A8894)),
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
          color: Colors.deepOrange,
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
