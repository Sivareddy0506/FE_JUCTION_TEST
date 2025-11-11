import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/form_text.dart';

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
  List<Map<String, dynamic>> transactions = [];
  String activeTab = 'all';

  bool _isLoading = true;
  String? amountError;
  bool isValidAmount = false;

  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _loadAuthData();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString("authToken");
    final savedBuyerId = prefs.getString("userId");

    if (savedToken != null && savedBuyerId != null) {
      setState(() {
        token = savedToken;
        buyerId = savedBuyerId;
      });
      await _fetchWalletData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchWalletData() async {
    if (buyerId == null || token == null) return;

    setState(() => _isLoading = true);

    try {
      final res = await http.get(
        Uri.parse("https://api.junctionverse.com/transaction/get-transactions"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          walletBalance = (data['walletBalance'] as num).toInt();
          transactions = (data['transactions'] as List)
              .map<Map<String, dynamic>>((txn) => Map<String, dynamic>.from(txn))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching wallet data: $e");
      setState(() => _isLoading = false);
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

      setState(() {
        walletBalance = (data['updatedWalletBalance'] as num).toInt();
      });

      final txn = Map<String, dynamic>.from(data['transaction']);
      txn['creditDebitStatus'] = 'credit'; // ensure top-up is credit

      transactions.insert(0, txn);
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
    page: StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {

        String? validateAmount(String value) {
  if (value.isEmpty) return null;

  // First check for invalid characters or patterns
  // Allow only digits, commas, and spaces
  if (!RegExp(r'^[\d,\s]+$').hasMatch(value)) {
    return 'Amount can only contain digits';
  }

  // Check for consecutive commas or invalid comma usage
  if (value.contains(',,') || value.startsWith(',') || value.endsWith(',')) {
    return 'Invalid amount format';
  }

  // Remove spaces and commas for parsing
  final cleanedValue = value.replaceAll(',', '').replaceAll(' ', '').trim();

  // After cleaning, check if it's empty (means only commas/spaces were entered)
  if (cleanedValue.isEmpty) {
    return 'Please enter a valid amount';
  }

  // Check if it contains only digits after cleaning
  if (!RegExp(r'^\d+$').hasMatch(cleanedValue)) {
    return 'Amount can only contain digits';
  }

  // Parse the amount
  final amount = int.tryParse(cleanedValue);
  if (amount == null) {
    return 'Please enter a valid amount';
  }

  // Check if amount is positive
  if (amount <= 0) {
    return 'Amount must be greater than 0';
  }

  // Check minimum amount
  if (amount < 10) {
    return 'Minimum amount is ₹10';
  }

  // Check maximum amount
  if (amount > 100000) {
    return 'Maximum amount is ₹1,00,000';
  }

  return null;
}

        void onAmountChanged(String value) {
          setModalState(() {
            amountError = validateAmount(value);
            isValidAmount = amountError == null && value.isNotEmpty;
          });
        }

        return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Money to Wallet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF262626),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Amount',
                    placeholder: 'Enter Amount',
                    isMandatory: true,
                    keyboardType: TextInputType.number,
                    controller: _amountController,
                    onChanged: onAmountChanged,
                    prefixText: '₹ ',
                  ),
                  if (amountError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: Text(
                        amountError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (amountError == null && _amountController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: Text(
                        'Amount between ₹10 and ₹1,00,000',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Add Amount',
                backgroundColor: isValidAmount 
                    ? const Color(0xFF262626) 
                    : const Color(0xFF8C8C8C),
                onPressed: isValidAmount
                    ? () {
                        final amount = int.tryParse(_amountController.text);
                        if (amount != null && amount > 0) {
                          Navigator.pop(context);
                          _createOrder(amount);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Cancel',
                backgroundColor: const Color(0xFF8C8C8C),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    ),
  );
}

  Widget _buildTabButton(String label, String value) {
    final bool selected = activeTab == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: AppButton(
        label: label,
        onPressed: () => setState(() => activeTab = value),
        backgroundColor: selected ? Colors.black : Colors.white,
        textColor: selected ? Colors.white : Colors.black,
        borderColor: Colors.grey,
        height: 40,
        expand: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredTransactions() {
    return transactions.where((txn) {
      if (activeTab == 'all') return true;
      if (activeTab == 'topup' && txn['creditDebitStatus'] == 'credit') return true;
      if (activeTab == 'withdrawal' && txn['creditDebitStatus'] == 'debit') return true;
      return false;
    }).toList();
  }

  Widget _buildTransactionItem(Map<String, dynamic> txn, Animation<double> animation) {
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
    final filteredTransactions = _filteredTransactions();

    return Scaffold(
      appBar: const CustomAppBar(title: "Manage Wallet"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
                        filteredTransactions.isEmpty
                            ? const Center(child: Text("No transactions yet."))
                            : AnimatedList(
                                key: _listKey,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                initialItemCount: filteredTransactions.length,
                                itemBuilder: (context, index, animation) {
                                  final txn = filteredTransactions[index];
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
