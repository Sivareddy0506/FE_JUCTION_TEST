import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'empty_state.dart';
import '../../widgets/products_grid.dart';
import '../../../models/product.dart';

class ActiveAuctionsTab extends StatefulWidget {
  final bool hideLoadingIndicator;
  final bool startLoading;
  
  const ActiveAuctionsTab({
    super.key,
    this.hideLoadingIndicator = false,
    this.startLoading = true,
  });

  @override
  State<ActiveAuctionsTab> createState() => _ActiveAuctionsTabState();
}

class _ActiveAuctionsTabState extends State<ActiveAuctionsTab> {
  List<Product> allItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Only start fetching data if we're supposed to start loading
    if (widget.startLoading) {
      _fetchAllData();
    }
  }

  Future<void> _fetchAllData() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      debugPrint('ActiveAuctionsTab: no auth token found.');
      setState(() => isLoading = false);
      return;
    }

    final uri = Uri.parse('https://api.junctionverse.com/product/me/active');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) {
        debugPrint('ActiveAuctionsTab: API Error ${response.statusCode}');
        setState(() => isLoading = false);
        return;
      }

      final dynamic decoded = jsonDecode(response.body);

      // Normalize to List<dynamic>
      final List<dynamic> data = () {
        if (decoded == null) return <dynamic>[];
        if (decoded is List) return decoded;
        if (decoded is Map<String, dynamic>) {
          if (decoded['products'] is List) return decoded['products'];
          if (decoded['data'] is List) return decoded['data'];
          // maybe the API returns { items: [...] }
          if (decoded['items'] is List) return decoded['items'];
          // fallback: try to find first list inside the map
          final found = decoded.values.firstWhere(
            (v) => v is List,
            orElse: () => <dynamic>[],
          );
          return found is List ? found : <dynamic>[];
        }
        return <dynamic>[];
      }();

      // Map each item to Product
      final List<Product> fetched = data.map<Product>((rawItem) {
        // ensure item is a Map<String, dynamic>
        final Map<String, dynamic> item =
            rawItem is Map<String, dynamic> ? rawItem : Map<String, dynamic>.from(rawItem as Map);

        // images => List<ProductImage>
        final List<ProductImage> imageList = (item['images'] as List?)
                ?.map((imgRaw) {
                  final Map<String, dynamic> img =
                      imgRaw is Map<String, dynamic> ? imgRaw : Map<String, dynamic>.from(imgRaw as Map);
                  return ProductImage(
                    fileUrl: img['fileUrl']?.toString() ?? 'assets/placeholder.png',
                    fileType: img['fileType']?.toString(),
                    filename: img['filename']?.toString(),
                  );
                })
                .whereType<ProductImage>()
                .toList() ??
            <ProductImage>[];

        final String imageUrl = imageList.isNotEmpty
            ? imageList.first.fileUrl
            : (item['imageUrl']?.toString() ?? 'assets/placeholder.png');

        final bool isAuction = item['isAuction'] == true;

        final dynamic loc = item['location'];
        final double? latitude = (loc is Map && loc['lat'] != null) ? (loc['lat'] as num).toDouble() : (item['lat'] is num ? (item['lat'] as num).toDouble() : null);
        final double? longitude = (loc is Map && loc['lng'] != null) ? (loc['lng'] as num).toDouble() : (item['lng'] is num ? (item['lng'] as num).toDouble() : null);

        // Attempt to parse auction object (if you want Auction typed object)
        final Auction? auction = (item['auction'] is Map<String, dynamic>)
            ? Auction.fromJson(Map<String, dynamic>.from(item['auction']))
            : null;

        // Parse createdAt safely
        DateTime? createdAt;
        try {
          final createdRaw = item['createdAt'] ?? item['created_at'];
          if (createdRaw != null) createdAt = DateTime.tryParse(createdRaw.toString());
        } catch (_) {
          createdAt = null;
        }

        // views
        final int views = int.tryParse((item['views'] ?? item['viewCount'] ?? '0').toString()) ?? 0;

        // seller
        final Seller? seller = (item['seller'] is Map<String, dynamic>)
            ? Seller.fromJson(Map<String, dynamic>.from(item['seller']))
            : null;

        return Product(
          id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
          images: imageList,
          imageUrl: imageUrl,
          title: item['title']?.toString() ?? item['name']?.toString() ?? 'No title',
          price: item['price'] != null ? '₹${item['price']}' : null,
          isAuction: isAuction,
          auction: auction,
          bidStartDate: item['bidStartDate'] != null
              ? DateTime.tryParse(item['bidStartDate'].toString())
              : auction?.auctionStartTime,
          duration: item['duration'] is int ? item['duration'] as int : int.tryParse(item['duration']?.toString() ?? ''),
          latitude: latitude,
          longitude: longitude,
          description: item['description']?.toString(),
          location: item['pickupLocation']?.toString() ?? item['locationName']?.toString(),
          seller: seller,
          category: item['category']?.toString(),
          condition: item['condition']?.toString(),
          usage: item['usage']?.toString(),
          brand: item['brand']?.toString(),
          yearOfPurchase: item['yearOfPurchase'] is int ? item['yearOfPurchase'] as int : int.tryParse(item['yearOfPurchase']?.toString() ?? ''),
          createdAt: createdAt,
          views: views,
          auctionStatus: item['auctionStatus']?.toString(),
        );
      }).toList(growable: false);

      setState(() {
        allItems = fetched;
        isLoading = false;
      });
    } catch (e, st) {
      debugPrint('ActiveAuctionsTab: exception while fetching data: $e\n$st');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && !widget.hideLoadingIndicator) {
      return const Center(child: CircularProgressIndicator());
    }
    if (allItems.isEmpty) {
      return const EmptyState(text: 'No products or auctions available.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ProductGridWidget(products: allItems),
    );
  }
}
