// Simple in-memory tracker ensuring a product is counted as viewed only once per app session.
class ViewTracker {
  ViewTracker._internal();
  static final ViewTracker _instance = ViewTracker._internal();
  static ViewTracker get instance => _instance;

  final Set<String> _viewedProductIds = <String>{};

  bool isViewed(String productId) => _viewedProductIds.contains(productId);

  void markViewed(String productId) {
    _viewedProductIds.add(productId);
  }
}
