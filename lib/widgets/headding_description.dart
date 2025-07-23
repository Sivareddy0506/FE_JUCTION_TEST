import 'package:flutter/material.dart';

class HeadingWithDescription extends StatelessWidget {
  final String heading;
  final String description;

  const HeadingWithDescription({
    super.key,
    required this.heading,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF262626),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Color(0xFF323537),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
