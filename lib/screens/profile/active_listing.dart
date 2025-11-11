import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'empty_state.dart';
import '../../widgets/products_grid.dart';
import '../../../models/product.dart';

class ActiveListingRepository {
  static Future<List<Product>> fetchActiveListings({String? userId}) async {
    if (userId != null && userId.isNotEmpty) {
      final uri = Uri.parse('https://api.junctionverse.com/product/others/active?userId=$userId');
      final response = await http.get(uri, headers: const {'Content-Type': 'application/json'});
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch active listings (status ${response.statusCode})');
      }
      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> data = _normalizeList(decoded);
      return data.map<Product>((item) => _mapProduct(item)).toList(growable: false);
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      throw Exception('Auth token missing for active listings');
    }

    final uri = Uri.parse('https://api.junctionverse.com/product/me/active');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch active listings (status ${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> data = _normalizeList(decoded);
    return data.map<Product>((item) => _mapProduct(item)).toList(growable: false);
  }

  static List<dynamic> _normalizeList(dynamic decoded) {
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
  }

  static Product _mapProduct(dynamic rawItem) {
    final Map<String, dynamic> item = rawItem is Map<String, dynamic>
        ? rawItem
        : Map<String, dynamic>.from(rawItem as Map);

    final List<ProductImage> imageList = (item['images'] as List?)
            ?.map((imgRaw) {
              final Map<String, dynamic> img = imgRaw is Map<String, dynamic>
                  ? imgRaw
                  : Map<String, dynamic>.from(imgRaw as Map);
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
    final double? latitude = (loc is Map && loc['lat'] != null)
        ? (loc['lat'] as num).toDouble()
        : (item['lat'] is num ? (item['lat'] as num).toDouble() : null);
    final double? longitude = (loc is Map && loc['lng'] != null)
        ? (loc['lng'] as num).toDouble()
        : (item['lng'] is num ? (item['lng'] as num).toDouble() : null);

    final Auction? auction = (item['auction'] is Map<String, dynamic>)
        ? Auction.fromJson(Map<String, dynamic>.from(item['auction']))
        : null;

    DateTime? createdAt;
    try {
      final createdRaw = item['createdAt'] ?? item['created_at'];
      if (createdRaw != null) createdAt = DateTime.tryParse(createdRaw.toString());
    } catch (_) {
      createdAt = null;
    }

    final int views = int.tryParse((item['views'] ?? item['viewCount'] ?? '0').toString()) ?? 0;

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
      duration: item['duration'] is int
          ? item['duration'] as int
          : int.tryParse(item['duration']?.toString() ?? ''),
      latitude: latitude,
      longitude: longitude,
      description: item['description']?.toString(),
      location: item['pickupLocation']?.toString() ?? item['locationName']?.toString(),
      seller: seller,
      category: item['category']?.toString(),
      condition: item['condition']?.toString(),
      usage: item['usage']?.toString(),
      brand: item['brand']?.toString(),
      yearOfPurchase: item['yearOfPurchase'] is int
          ? item['yearOfPurchase'] as int
          : int.tryParse(item['yearOfPurchase']?.toString() ?? ''),
      createdAt: createdAt,
      views: views,
      auctionStatus: item['auctionStatus']?.toString(),
    );
  }
}

class ActiveAuctionsTab extends StatefulWidget {
  final bool hideLoadingIndicator;
  final bool startLoading;
  final String? userId;
  
  const ActiveAuctionsTab({
    super.key,
    this.hideLoadingIndicator = false,
    this.startLoading = true,
    this.userId,
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
    if (widget.startLoading) {
      _fetchAllData();
    }
  }

  Future<void> _fetchAllData() async {
    setState(() => isLoading = true);

    try {
      final items = await ActiveListingRepository.fetchActiveListings(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        allItems = items;
        isLoading = false;
      });
    } catch (e, st) {
      debugPrint('ActiveAuctionsTab: exception while fetching data: $e\n$st');
      if (mounted) setState(() => isLoading = false);
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
