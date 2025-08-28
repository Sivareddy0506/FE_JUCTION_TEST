import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../widgets/custom_appbar.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  String activeTab = 'all';
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void setTab(String tab) {
    setState(() => activeTab = tab);
  }

  // Fetch token & buyerId from SharedPreferences
  Future<Map<String, String?>> _getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final buyerId = prefs.getString("buyerId");
    return {"token": token, "buyerId": buyerId};
  }

  // Create Razorpay Order via backend
  Future<void> _createOrder(int amount) async {
    final authData = await _getAuthData();
    final buyerId = authData["buyerId"];
    final token = authData["token"];

    if (buyerId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in ❌")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse("https://api.junctionverse.com/transaction/createtransaction"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "productId": "razorpay",
        "creditDebitStatus": "credit",
        "amount": amount,
        "buyerId": buyerId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data["orderId"] != null) {
      _openRazorpayCheckout(data["orderId"], amount);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create Razorpay order ❌")),
      );
    }
  }

  // Open Razorpay Checkout
  void _openRazorpayCheckout(String orderId, int amount) {
    var options = {
      'key': 'rzp_test_RAqPBWTsoaw61V', 
      'amount': amount * 100, 
      'currency': 'INR',
      'name': 'My App Wallet',
      'description': 'Wallet Top-Up',
      'order_id': orderId,
      'prefill': {
        'contact': '9876543210',
        'email': 'testuser@example.com',
      },
      'theme': {'color': '#3399cc'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // Handle Payment Success
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final authData = await _getAuthData();
    final buyerId = authData["buyerId"];
    final token = authData["token"];

    if (buyerId == null || token == null) return;

    
    const amount = 250;

    final res = await http.post(
      Uri.parse("https://api.junctionverse.com/transaction/verify-payment"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "razorpay_payment_id": response.paymentId,
        "razorpay_order_id": response.orderId,
        "razorpay_signature": response.signature,
        "buyerId": buyerId,
        "amount": amount,
      }),
    );

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wallet Updated Successfully ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment verification failed ❌")),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Failed ❌")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
    );
  }

  /// 🔹 Show dialog for entering custom amount
  void _showAmountDialog() {
    final TextEditingController _amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Balance"),
        content: TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter amount in ₹"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(_amountController.text);
              if (amount != null && amount > 0) {
                Navigator.pop(ctx);
                _createOrder(amount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter valid amount")),
                );
              }
            },
            child: const Text("Proceed"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Manage Wallet"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // ... you can show wallet balance here later
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton('Withdraw', false, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Withdraw flow coming soon 🚀")),
                  );
                }),
                _buildActionButton('Add Balance', true, _showAmountDialog),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, bool isPrimary, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
        backgroundColor: isPrimary ? Colors.black : Colors.white,
        foregroundColor: isPrimary ? Colors.white : Colors.black,
        side: isPrimary ? BorderSide.none : const BorderSide(color: Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 15)),
    );
  }
}
