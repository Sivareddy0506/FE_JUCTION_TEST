class Product {
  final String imageUrl;
  final String title;
  final String? price;
  final String location;
  final bool isAuction;
  final DateTime? bidStartDate;
  final int? duration;

  Product({
    required this.imageUrl,
    required this.title,
    this.price,
    required this.location,
    this.isAuction = false,
    this.bidStartDate,
    this.duration,
  });
}
