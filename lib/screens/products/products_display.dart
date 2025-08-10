import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/search_bar_widget.dart';
import '../services/api_service.dart';
import './product_detail.dart';

class ProductListingPage extends StatefulWidget {
  final String title;
  final String source; // "fresh", "trending", "lastViewed", "searched"

  const ProductListingPage({
    super.key,
    required this.title,
    required this.source,
  });

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSectionProducts();
  }

  Future<void> fetchSectionProducts() async {
    List<Product> result = [];

    switch (widget.source) {
      case 'fresh':
        result = await ApiService.fetchAllProducts();
        break;
      case 'trending':
        result = await ApiService.fetchMostClicked();
        break;
      case 'lastViewed':
        result = await ApiService.fetchLastOpened();
        break;
      case 'searched':
        result = await ApiService.fetchLastSearched();
        break;
      default:
        result = [];
    }

    setState(() {
      products = result;
      isLoading = false;
    });
  }

  Future<void> _handleProductClick(Product product) async {
    await ApiService.trackProductClick(product.id); // 🔥 track the click
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SearchBarWidget(),
            const SizedBox(height: 8),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return GestureDetector(
                      onTap: () => _handleProductClick(product),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 200,
                              child: PageView(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Image.asset('assets/images/placeholder.png'),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    children: const [
                                      Chip(label: Text('Age: > 2Y')),
                                      Chip(label: Text('Usage: Regular')),
                                      Chip(label: Text('Condition: Good')),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product.title,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.price ?? '',
                                    style: const TextStyle(color: Colors.orange),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.remove_red_eye, size: 16),
                                      const SizedBox(width: 4),
                                      const Text('Viewed by others'),
                                      const Spacer(),
                                      const Icon(Icons.location_on, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        product.latitude != null ? 'Near You' : 'Unknown',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
