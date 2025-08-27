class ProductImage {
  final String fileUrl;
  final String? fileType;
  final String? filename;

  ProductImage({
    required this.fileUrl,
    this.fileType,
    this.filename,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'],
      filename: json['filename'],
    );
  }
}

class Auction {
  final String? id;
  final String? productId;
  final int? startingPrice;
  final int? currentBid;
  final int? reservePrice;
  final DateTime? auctionStartTime;
  final DateTime? auctionEndTime;
  final int? duration;
  final String? highestBidderId;

  Auction({
    this.id,
    this.productId,
    this.startingPrice,
    this.currentBid,
    this.reservePrice,
    this.auctionStartTime,
    this.auctionEndTime,
    this.duration,
    this.highestBidderId,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: json['id'],
      productId: json['productId'],
      startingPrice: json['startingPrice'] != null ? int.tryParse(json['startingPrice'].toString()) : null,
      currentBid: json['currentBid'] != null ? int.tryParse(json['currentBid'].toString()) : null,
      reservePrice: json['reservePrice'] != null ? int.tryParse(json['reservePrice'].toString()) : null,
      auctionStartTime: json['auctionStartTime'] != null ? DateTime.tryParse(json['auctionStartTime']) : null,
      auctionEndTime: json['auctionEndTime'] != null ? DateTime.tryParse(json['auctionEndTime']) : null,
      duration: json['duration'],
      highestBidderId: json['highestBidderId'],
    );
  }
}

class Seller {
  final String id;
  final String fullName;
  final String email;

  Seller({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    // API sometimes uses 'fullName' or 'name'
    return Seller(
      id: json['id'] ?? json['_id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  get imageUrl => null;
  
  @override
  String toString() {
    return 'Seller(id: $id, fullName: $fullName, email: $email)';
  }
}

class Product {
  final String id;
  final List<ProductImage> images;      // now matches API images[]
  final String imageUrl;               // convenience: first image or placeholder
  final String title;
  final String? price;                 // formatted (e.g. '₹4000') or null
  final bool isAuction;
  final Auction? auction;
  final DateTime? bidStartDate;
  final int? duration;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? location;              // human readable location/pickup
  final Seller? seller;
  final String? category;
  final String? condition;
  final String? usage;
  final String? brand;
  final int? yearOfPurchase;
  final DateTime? createdAt;
  final int? views;
  final String? auctionStatus;

  Product({
    required this.id,
    required this.images,
    required this.imageUrl,
    required this.title,
    this.price,
    required this.isAuction,
    this.auction,
    this.bidStartDate,
    this.duration,
    this.latitude,
    this.longitude,
    this.description,
    this.location,
    this.seller,
    this.category,
    this.condition,
    this.usage,
    this.brand,
    this.yearOfPurchase,
    this.createdAt,
    this.views,
    this.auctionStatus,
  });

  // Helpful formatted price: show fixed price or auction starting price
  String get displayPrice {
    if (price != null && price!.isNotEmpty) return price!;
    if (auction?.startingPrice != null) return '₹${auction!.startingPrice}';
    return '—';
  }

  String? get sellerName => seller?.fullName;

  static Seller? _parseSeller(Map<String, dynamic> json) {
    
    // Try different possible seller field names and structures
    if (json['seller'] is Map<String, dynamic>) {
      return Seller.fromJson(Map<String, dynamic>.from(json['seller']));
    }
    
    // Check if seller is a string (ID) and we have separate name fields
    if (json['seller'] is String && json['sellerName'] != null) {
      return Seller(
        id: json['seller'],
        fullName: json['sellerName'],
        email: json['sellerEmail'] ?? '',
      );
    }
    
    // Check if owner field contains seller info
    if (json['owner'] is Map<String, dynamic>) {
      return Seller.fromJson(Map<String, dynamic>.from(json['owner']));
    }
    
    // Check if user field contains seller info
    if (json['user'] is Map<String, dynamic>) {
      return Seller.fromJson(Map<String, dynamic>.from(json['user']));
    }
    
    // If seller is just a string (ID), try to create a basic seller
    if (json['seller'] is String) {
      return Seller(
        id: json['seller'],
        fullName: json['sellerName'] ?? 'Unknown Seller',
        email: json['sellerEmail'] ?? '',
      );
    }
    
    // Check if sellerId exists (common case from API)
    if (json['sellerId'] is String) {
      return Seller(
        id: json['sellerId'],
        fullName: json['sellerName'] ?? 'Seller ${json['sellerId'].substring(0, 8)}...',
        email: json['sellerEmail'] ?? '',
      );
    }
    
    return null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
  final imageList = (json['images'] as List?)
          ?.map((img) => ProductImage.fromJson(Map<String, dynamic>.from(img)))
          .toList() ??
      [];

  final imageUrl = imageList.isNotEmpty
      ? imageList[0].fileUrl
      : (json['imageUrl'] ?? 'assets/images/placeholder.png');

  final auction = json['auction'] != null && json['auction'] is Map<String, dynamic>
      ? Auction.fromJson(Map<String, dynamic>.from(json['auction']))
      : null;

  final priceString = json['price'] != null ? '₹${json['price']}' : null;

  return Product(
    id: json['_id'] ?? json['id'] ?? '',
    images: imageList, // ✅ Added required argument
    imageUrl: imageUrl,
    title: json['title'] ?? json['name'] ?? 'No Title',
    price: priceString,
    isAuction: json['isAuction'] ?? false,
    auction: auction,
    bidStartDate: json['bidStartDate'] != null
        ? DateTime.tryParse(json['bidStartDate'])
        : auction?.auctionStartTime,
    duration: json['duration'] ?? auction?.duration,
    latitude: (json['location']?['lat'] ?? json['lat'])?.toDouble(),
    longitude: (json['location']?['lng'] ?? json['lng'])?.toDouble(),
    description: json['description'],
    location: json['pickupLocation'] ??
        json['locationName'] ??
        json['location']?['name'],
    seller: _parseSeller(json),
    category: json['category'],
    condition: json['condition'],
    usage: json['usage'],
    brand: json['brand'],
    yearOfPurchase: json['yearOfPurchase'],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'])
        : null,
    views: int.tryParse(
            (json['views'] ?? json['viewCount'])?.toString() ?? '0') ??
        0,
    auctionStatus: json['auctionStatus'],
  );
}
}