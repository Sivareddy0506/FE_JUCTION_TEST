import 'package:flutter/material.dart';
import '../../../widgets/custom_appbar.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final List<_FaqItem> _items = [
    _FaqItem(
      question: "What is Junction?",
      answer:
          "Junction is a secure buy-and-sell marketplace exclusively for college students and verified vendors. You can list items, buy second-hand products, or bid in auctions all within your college community.",
    ),
    _FaqItem(
      question: "How does Junction ensure user safety?",
      answer:
          "Junction ensures user safety by verifying all student accounts via college email IDs and thoroughly screening vendors before approval.",
    ),
    _FaqItem(
      question: "What can I sell on Junction?",
      answer:
          "You can sell textbooks, electronics, accessories, clothing, and any other items allowed under our community guidelines.",
    ),
    _FaqItem(
      question: "How do auctions work?",
      answer:
          "Sellers can list items for auction, and buyers can place bids. The highest bid before the deadline wins the auction.",
    ),
    _FaqItem(
      question: "How does bidding work?",
      answer:
          "Buyers can place bids on auctioned items. The bid must be higher than the current highest bid to be considered valid.",
    ),
    _FaqItem(
      question: "What happens if I win an auction?",
      answer:
          "If you win, you'll be notified and asked to complete the payment and arrange for delivery or pickup with the seller.",
    ),
    _FaqItem(
      question: "Who can register as a vendor?",
      answer:
          "Only verified business vendors approved by the Junction team can register and list products.",
    ),
    _FaqItem(
      question: "Are there any charges for vendors?",
      answer:
          "Vendors may be subject to a nominal listing or transaction fee. Details are shared during the onboarding process.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "FAQ"),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const Text(
              'Got questions? We\'ve got answers',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Whether you\'re a student looking to buy or sell, or a vendor listing your products, this section covers everything you need to know about using Junction. From account setup to bidding and transactions, find quick solutions and helpful tips right here.',
              style: TextStyle(
                fontSize: 12,
                height: 1.33,
                color: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 24),
            ..._items.map((item) => _FaqTile(item: item)).toList(),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  bool isExpanded;

  _FaqItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;

  const _FaqTile({required this.item, super.key});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.item.isExpanded;
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF8A8894), width: 1),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              height: 56,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF262626),
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF262626),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.item.answer,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.33,
                    color: Color(0xFF8A8894),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
