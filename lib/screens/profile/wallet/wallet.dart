import 'package:flutter/material.dart';
import '../../../widgets/custom_appbar.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  String activeTab = 'all';

  void setTab(String tab) {
    setState(() => activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Manage Wallet"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Available Balance', style: TextStyle(fontSize: 14, color: Color(0xFF8A8894))),
                          SizedBox(height: 4),
                          Text('₹1,200', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Image.asset('assets/wallet-img1.png', width: 37, height: 37),
                    ],
                  ),
                  const Spacer(),
                  const Text('John Doe', style: TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildTabButton('All Transaction', 'all'),
                _buildTabButton('Top-Up', 'topup'),
                _buildTabButton('Withdrawal', 'withdrawal'),
              ],
            ),
            const SizedBox(height: 14),
            if (activeTab == 'all' || activeTab == 'topup')
              _buildTransactionItem('Wallet Top-Up', 'Gpay / 9405284-60249524', '+ ₹250', 'assets/ArrowDownLeft.png'),
            if (activeTab == 'all' || activeTab == 'withdrawal')
              _buildTransactionItem('Withdrawal', 'Netbanking / 123434-2343', '+ ₹550', 'assets/ArrowUpRight.png'),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton('Withdraw', false),
                _buildActionButton('Add Balance', true),
              ],
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
        onPressed: () => setTab(value),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Colors.black : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black,
          side: const BorderSide(color: Colors.grey),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, String iconPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(iconPath, width: 24, height: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ],
          ),
          Text(amount, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, bool isPrimary) {
    return ElevatedButton(
      onPressed: () {},
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
