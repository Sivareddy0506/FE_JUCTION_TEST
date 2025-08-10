import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // ✅ Only this is needed

class AuctionCarouselWidget extends StatelessWidget {
  const AuctionCarouselWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> dummyAuctions = [
      {
        'title': 'AirPods Pro Auction',
        'image': 'https://via.placeholder.com/300x200?text=Auction+1',
      },
      {
        'title': 'iPhone 14 Bidding Starts',
        'image': 'https://via.placeholder.com/300x200?text=Auction+2',
      },
      {
        'title': 'Samsung S22 Ultra Sale',
        'image': 'https://via.placeholder.com/300x200?text=Auction+3',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Upcoming Auctions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        CarouselSlider(
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.85,
          ),
          items: dummyAuctions.map((item) {
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              elevation: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['title']!,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
