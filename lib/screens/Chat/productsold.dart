import 'package:flutter/material.dart';
import 'package:junction/screens/Chat/user_rating.dart';

class ProductSoldScreen extends StatefulWidget {
  final String productName;
  final String ratedUserId;
  final String ratedById;
  final bool fromProductSold;

  const ProductSoldScreen({super.key, 
    required this.productName,
    required this.ratedUserId,
    required this.ratedById,
    this.fromProductSold = false,
    });

  @override
  State<ProductSoldScreen> createState() => _ProductSoldScreenState();
}

class _ProductSoldScreenState extends State<ProductSoldScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToRatingsPage();
  }

void _navigateToRatingsPage() {
  Future.delayed(const Duration(seconds: 3), () {
    Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewScreen(
              ratedUserId: widget.ratedUserId,
              ratedById: widget.ratedById,
              fromProductSold: widget.fromProductSold,
            ),
          ),
        );
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Illustration
                Image.asset(
                  "assets/productsold.png",
                  height: 200,
                ),
                SizedBox(height: 32),

                // Title
                Text(
                  "Yay! Your item is sold",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),

                // Subtitle
                Text(
                  "You've successfully sold your product ${widget.productName}.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Go back or redirect
                    },
                    child: Text(
                      "Continue",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
