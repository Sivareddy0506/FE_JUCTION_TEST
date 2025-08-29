import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/form_text.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with SingleTickerProviderStateMixin {
  Razorpay? _razorpay;
  String? token;
  String? buyerId;
  int? _lastPaymentAmount;

  int walletBalance = 0;
  List transactions = [];
  String activeTab = 'all';

  final TextEditingController _amountController = TextEditingController();

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _loadAuthData();
    _fetchWalletData();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("authToken");
      buyerId = prefs.getString("userId");
    });
  }

  Future<void> _fetchWalletData() async {
    if (buyerId == null || token == null) return;

    try {
      final res = await http.get(
        Uri.parse("https://api.junctionverse.com/transaction/get-transactions"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          walletBalance = data['walletBalance'] ?? 0;
          transactions = data['transactions'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching wallet data: $e");
    }
  }

  Future<void> _createOrder(int amount) async {
    if (buyerId == null || token == null) return;

    _lastPaymentAmount = amount;

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
    }
  }

  void _openRazorpayCheckout(String orderId, int amount) {
    final options = {
      'key': 'rzp_test_RAqPBWTsoaw61V',
      'amount': amount * 100,
      'name': 'Junctionverse',
      'description': 'Wallet Topup',
      'order_id': orderId,
    };
    _razorpay?.open(options);
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (buyerId == null || token == null || _lastPaymentAmount == null) return;

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
        "amount": _lastPaymentAmount,
      }),
    );

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);

      // Update wallet balance instantly
      setState(() {
        walletBalance = data['updatedWalletBalance'];
      });

      // Add new transaction at top of the list with animation
      transactions.insert(0, data['transaction']);
      _listKey.currentState?.insertItem(0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wallet Updated Successfully ✅")),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Failed ❌")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _showAddMoneyBottomSheet() {
    _amountController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Amount',
              placeholder: 'Enter Amount',
              isMandatory: true,
              keyboardType: TextInputType.number,
              controller: _amountController,
              onChanged: (val) {},
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Add Amount',
              backgroundColor: const Color(0xFF262626),
              onPressed: () {
                final amount = int.tryParse(_amountController.text);
                if (amount != null && amount > 0) {
                  Navigator.pop(context);
                  _createOrder(amount);
                }
              },
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Cancel',
              backgroundColor: const Color(0xFF262626),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String value) {
    final bool selected = activeTab == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: OutlinedButton(
        onPressed: () => setState(() => activeTab = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Colors.black : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black,
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildTransactionItem(Map txn, Animation<double> animation) {
    final isCredit = txn['creditDebitStatus'] == 'credit';
    final amountPrefix = isCredit ? '+ ₹' : '- ₹';
    final icon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;
    final dateStr = txn['createdAt'] != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(txn['createdAt']))
        : '';

    return SizeTransition(
      sizeFactor: animation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Icon(icon, color: isCredit ? Colors.green : Colors.red),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(txn['description'] ?? '', style: const TextStyle(fontSize: 15)),
                      Text(dateStr, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            Text('$amountPrefix${txn['amount']}', style: TextStyle(fontSize: 15, color: isCredit ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Manage Wallet"),
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Available Balance', style: TextStyle(fontSize: 14, color: Color(0xFF8A8894))),
                            const SizedBox(height: 4),
                            Text('₹$walletBalance', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        Image.asset('assets/wallet-img1.png', width: 37, height: 37),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTabButton('All Transaction', 'all'),
                        _buildTabButton('Top-Up', 'topup'),
                        _buildTabButton('Withdrawal', 'withdrawal'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedList(
                    key: _listKey,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    initialItemCount: transactions
                        .where((txn) =>
                            activeTab == 'all' ||
                            (activeTab == 'topup' && txn['creditDebitStatus'] == 'credit') ||
                            (activeTab == 'withdrawal' && txn['creditDebitStatus'] == 'debit'))
                        .length,
                    itemBuilder: (context, index, animation) {
                      final txn = transactions
                          .where((txn) =>
                              activeTab == 'all' ||
                              (activeTab == 'topup' && txn['creditDebitStatus'] == 'credit') ||
                              (activeTab == 'withdrawal' && txn['creditDebitStatus'] == 'debit'))
                          .toList()[index];
                      return _buildTransactionItem(txn, animation);
                    },
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Withdraw',
                          backgroundColor: const Color(0xFF262626),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          label: 'Add Balance',
                          backgroundColor: const Color(0xFF262626),
                          onPressed: _showAddMoneyBottomSheet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _amountController.dispose();
    super.dispose();
  }
}
