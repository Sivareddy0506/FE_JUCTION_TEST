import 'package:flutter/material.dart';

class MainLandingScreen extends StatelessWidget {
  const MainLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Landing'),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Text(
          'No products available',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ),
    );
  }
}
