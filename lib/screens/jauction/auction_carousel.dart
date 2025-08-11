// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import './going_live_comp.dart';
// import '../services/auction_service.dart';

// class AuctionCarousel extends StatefulWidget {
//   final Future<List<Map<String, dynamic>>>? auctionsFuture;
//   final List<Map<String, dynamic>>? auctions;
//   final String? token;

//   const AuctionCarousel({
//     Key? key,
//     this.auctionsFuture,
//     this.auctions,
//     this.token,
//   })  : assert(auctionsFuture != null || auctions != null || token != null,
//             'Either auctionsFuture, auctions, or token must be provided'),
//         super(key: key);

//   @override
//   State<AuctionCarousel> createState() => _AuctionCarouselState();
// }

// class _AuctionCarouselState extends State<AuctionCarousel> {
//   late Future<List<Map<String, dynamic>>> _auctionsFuture;
//   final PageController _pageController = PageController(viewportFraction: 0.9);

//   @override
//   void initState() {
//     super.initState();
//     if (widget.auctionsFuture != null) {
//       _auctionsFuture = widget.auctionsFuture!;
//     } else if (widget.token != null) {
//       _auctionsFuture = AuctionService(widget.token!).getLiveTodayAuctions();
//     } else {
//       _auctionsFuture = Future.value(widget.auctions!);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<Map<String, dynamic>>>(
//       future: _auctionsFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('No auctions available'));
//         }

//         final auctions = snapshot.data!;
//         return SizedBox(
//           height: 350,
//           child: PageView.builder(
//             controller: _pageController,
//             itemCount: auctions.length,
//             itemBuilder: (context, index) {
//               return Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 8),
//                 child: AuctionCard(auctionData: auctions[index]),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }