import 'package:flutter/material.dart';

class JauctionComingSoonWidget extends StatelessWidget {
  const JauctionComingSoonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/inventing.png', width: 200),
          const SizedBox(height: 16),
          const Text(
            'Something great coming here soon',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
