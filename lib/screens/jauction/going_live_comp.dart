import 'dart:async';
import 'package:flutter/material.dart';

class AuctionCard extends StatefulWidget {
  final Map<String, dynamic> auctionData;

  const AuctionCard({super.key, required this.auctionData});

  @override
  State<AuctionCard> createState() => _AuctionCardState();
}

class _AuctionCardState extends State<AuctionCard> {
  late Timer _timer;
  Duration? _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final auction = widget.auctionData['auction'];
    if (auction == null) {
      setState(() {
        _timeLeft = null;
      });
      return;
    }
    final start = DateTime.tryParse(auction['auctionStartTime'] ?? '');
    if (start == null) {
      setState(() {
        _timeLeft = null;
      });
      return;
    }

    // Duration in hours
    final durationHours = auction['duration'] ?? 1;
    final end = start.add(Duration(hours: durationHours));

    final now = DateTime.now().toUtc();
    final diff = end.difference(now);
    if (diff.isNegative) {
      setState(() {
        _timeLeft = Duration.zero;
      });
    } else {
      setState(() {
        _timeLeft = diff;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.auctionData;
    final auction = product['auction'];
    final imageUrl = product['images'] != null && product['images'].isNotEmpty
        ? product['images'][0]['fileUrl']
        : null;

    final currentBid = auction?['currentBid'] ??
        auction?['startingPrice'] ??
        'No bids yet';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.image, size: 60)),
                      ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _timeLeft == null
                      ? const Text(
                          "No Timer",
                          style: TextStyle(color: Colors.white),
                        )
                      : Text(
                          _timeLeft!.inSeconds > 0
                              ? _formatDuration(_timeLeft!)
                              : "Ended",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.person, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text("3",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title'] ?? product['name'] ?? "Unknown",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  product['description'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "Current Bid: ",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      currentBid is int
                          ? "₹${currentBid.toString()}"
                          : currentBid.toString(),
                      style: const TextStyle(
                          color: const Color(0xFFFF6705),

                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Add your bidding logic here
                    },
                    child: const Text("Bid Now"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuctionCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> auctions;

  const AuctionCarousel({super.key, required this.auctions});

  @override
  State<AuctionCarousel> createState() => _AuctionCarouselState();
}

class _AuctionCarouselState extends State<AuctionCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.auctions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AuctionCard(auctionData: widget.auctions[index]),
          );
        },
      ),
    );
  }
}
