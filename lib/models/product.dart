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
    return Seller(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class Product {
  final String id;                  // ✅ Product ID
  final String imageUrl;
  final String title;
  final String? price;
  final bool isAuction;
  final DateTime? bidStartDate;
  final int? duration;
  final double? latitude;
  final double? longitude;
  final String? description;       // ✅ Description
  final String? location;          // ✅ Pickup location
  final Seller? seller;            // ✅ Seller info

  Product({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.price,
    required this.isAuction,
    this.bidStartDate,
    this.duration,
    this.latitude,
    this.longitude,
    this.description,
    this.location,
    this.seller,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final images = json['images'];
    final imageUrl = (images != null && images is List && images.isNotEmpty)
    ? (images[0] is Map && images[0]['fileUrl'] != null && images[0]['fileUrl'].toString().isNotEmpty
        ? images[0]['fileUrl']
        : 'assets/images/placeholder.png')
    : 'assets/images/placeholder.png';


    return Product(
      id: json['_id'] ?? json['id'] ?? '', // Accept either `_id` or `id`
      imageUrl: imageUrl,
      title: json['title'] ?? 'No Title',
      price: json['price'] != null ? '₹${json['price']}' : null,
      isAuction: json['isAuction'] ?? false,
      bidStartDate: json['bidStartDate'] != null
          ? DateTime.tryParse(json['bidStartDate'])
          : null,
      duration: json['duration'],
      latitude: json['latitude']?.toDouble() ??
          json['location']?['lat']?.toDouble(),
      longitude: json['longitude']?.toDouble() ??
          json['location']?['lng']?.toDouble(),
      description: json['description'],
      location: json['pickupLocation'] ?? json['locationName'],
      seller: json['seller'] != null ? Seller.fromJson(json['seller']) : null,
    );
  }
}
