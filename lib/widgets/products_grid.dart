import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../screens/services/location_helper.dart';

class ProductGridWidget extends StatelessWidget {
  final List<Product> products;

  const ProductGridWidget({super.key, required this.products});

  // 👇 Function to track product click
  Future<void> _trackProductClick(String productId) async {
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

      if (response.statusCode != 200) {
        debugPrint('Tracking failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error tracking product click: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final product = products[index];

        return InkWell(
          onTap: () async {
            await _trackProductClick(product.id); // 👈 Tracking call
            Navigator.pushNamed(context, '/product-detail', arguments: product);
          },
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: SizedBox(
              height: 270,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset('assets/images/placeholder.png'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (product.isAuction &&
                            product.bidStartDate != null &&
                            product.duration != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.price ?? '',
                                style: const TextStyle(color: Colors.deepOrange),
                              ),
                              const SizedBox(height: 4),
                              CountdownTimer(
                                startDate: product.bidStartDate!,
                                durationDays: product.duration!,
                              ),
                            ],
                          )
                        else if (!product.isAuction)
                          Text(
                            product.price ?? '',
                            style: const TextStyle(color: Colors.green),
                          ),
                        const SizedBox(height: 6),
                        if (product.latitude != null && product.longitude != null)
                          FutureBuilder<String>(
                            future: getAddressFromLatLng(product.latitude!, product.longitude!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text(
                                  'Loading location...',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                );
                              } else if (snapshot.hasError || !snapshot.hasData) {
                                return const Text(
                                  'Location unavailable',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                );
                              } else {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    Expanded(
                                      child: Text(
                                        snapshot.data!,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (product.isAuction && product.bidStartDate != null)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _formatDate(product.bidStartDate!),
                                          style: const TextStyle(fontSize: 11, color: Colors.black87),
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
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

class CountdownTimer extends StatefulWidget {
  final DateTime startDate;
  final int durationDays;

  const CountdownTimer({
    super.key,
    required this.startDate,
    required this.durationDays,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration remaining;
  Timer? timer;

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
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = remaining.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Text(
      'Ends in: $hours:$minutes:$seconds',
      style: const TextStyle(fontSize: 12, color: Colors.redAccent),
    );
  }
}
