import 'package:flutter/material.dart';
import 'dart:async';  
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../screens/products/product_detail.dart';
import '../screens/services/location_helper.dart';  // Assuming you have a utility for location

// Inside your ProductGridWidget:

class ProductGridWidget extends StatefulWidget {
  final List<Product> products;

  const ProductGridWidget({super.key, required this.products});

  @override
  State<ProductGridWidget> createState() => _ProductGridWidgetState();
}

class _ProductGridWidgetState extends State<ProductGridWidget> {
  Set<String> favoriteProductIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null || token.isEmpty) return;

      final uri = Uri.parse('https://api.junctionverse.com/user/my-favourites');
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final List favList = jsonDecode(response.body);
        setState(() {
          favoriteProductIds = favList.map<String>((item) => item['id'].toString()).toSet();
        });
      }
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
    }
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

  Future<void> _toggleFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null || token.isEmpty) return;

    final isFav = favoriteProductIds.contains(productId);
    // Example endpoint - Adjust according to your API for toggling favorite
    final uri = Uri.parse('https://api.junctionverse.com/user/favourite-toggle');

    final response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'productId': productId, 'favorite': !isFav}),
    );

    if (response.statusCode == 200) {
      setState(() {
        if (isFav) {
          favoriteProductIds.remove(productId);
        } else {
          favoriteProductIds.add(productId);
        }
      });
    } else {
      debugPrint('Failed to toggle favorite');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final product = widget.products[index];
        final isFav = favoriteProductIds.contains(product.id);

        return InkWell(
          onTap: () {
            _sendTrackRequest(product.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1.2,
              ),
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
                    // Product Image with rounded corners
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: AspectRatio(
                        aspectRatio: 1.05,
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset('assets/images/placeholder.png'),
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
                            // Title
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF262626),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Price & Auction Timer (no Ends in text here, handled separately)
                            if (product.isAuction &&
                                product.bidStartDate != null &&
                                product.duration != null) ...[
                              Text(
                                product.price ?? '',
                                style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ] else if (!product.isAuction) ...[
                              Text(
                                product.price ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12,
                                  color: Color(0xFFFF6705),
                                ),
                              ),
                            ],

                            const Spacer(),

                            // Location
                            if (product.latitude != null && product.longitude != null)
                              FutureBuilder<String>(
                                future: getAddressFromLatLng(
                                    product.latitude!, product.longitude!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text(
                                      'Loading location...',
                                      style: TextStyle(
                                          fontSize: 8, color: Color(0xFF8A8894)),
                                    );
                                  } else if (snapshot.hasError || !snapshot.hasData) {
                                    return const Text(
                                      'Location unavailable',
                                      style: TextStyle(
                                          fontSize: 8, color: Color(0xFF8A8894)),
                                    );
                                  } else {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 14, color: Color(0xFF8A8894)),
                                        Expanded(
                                          child: Text(
                                            snapshot.data!,
                                            style: const TextStyle(
                                                fontSize: 8, color: Color(0xFF8A8894)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (product.isAuction &&
                                            product.bidStartDate != null)
                                          Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEEEFF0),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _formatDate(product.bidStartDate!),
                                              style: const TextStyle(
                                                  fontSize: 8, color: Colors.black87),
                                            ),
                                          ),
                                      ],
                                    );
                                  }
                                },
                              )
                            else
                              const Text(
                                'Location not set',
                                style:
                                    TextStyle(fontSize: 8, color: Color(0xFF8A8894)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Auction Timer overlapped top right, only if isAuction true
                if (product.isAuction &&
                    product.bidStartDate != null &&
                    product.duration != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: AuctionTimerWidget(
                      startDate: product.bidStartDate!,
                      durationDays: product.duration!,
                    ),
                  ),

                // Love icon overlapped bottom right, only if NOT auction product
                if (!product.isAuction)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(product.id),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.deepOrange : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month]} ${date.year}';
  }

  // Your existing _trackProductClick and _sendTrackRequest methods ...
}


// New widget for Auction Timer display
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
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (remaining == Duration.zero) {
      // Show LIVE box
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.deepOrange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'LIVE',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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


  