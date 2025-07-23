import 'package:flutter/material.dart';

class FilterModal extends StatelessWidget {
  const FilterModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 10),
                _buildSwitchRow("Near Me"),
                _buildButtonGroup("Listing Type", ["All", "Regular", "Junction"]),
                _buildButtonGroup("Category", [
                  "Electronics",
                  "Computers & Networking",
                  "Furniture",
                  "Books",
                  "Sports Equipment",
                  "Clothes",
                  "Gaming",
                  "Activities",
                  "Tickets"
                ]),
                _buildButtonGroup("Sort By", [
                  "All",
                  "Price Low to High",
                  "Price High to Low",
                  "Recently Added",
                  "Ending Soon"
                ]),
                _buildRangeSlider(),
                _buildButtonGroup("Condition", [
                  "All",
                  "Like New",
                  "Gently Used",
                  "Fair",
                  "Needs Fixing"
                ]),
                _buildButtonGroup("Pick-up Method", [
                  "Campus Pick-up",
                  "House Pick-up"
                ]),
                const SizedBox(height: 10),
                _buildFooterButtons()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.asset('assets/images/x.png', height: 24),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String label) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 17)),
            const Switch(value: false, onChanged: null),
          ],
        ),
        const Divider()
      ],
    );
  }

  Widget _buildButtonGroup(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((opt) => FilterOptionButton(
                    label: opt,
                    selected: opt == options.first, // default to first selected
                  ))
              .toList(),
        ),
        const Divider(height: 30),
      ],
    );
  }

  Widget _buildRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Price Range", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        const SizedBox(height: 14),
        Slider(
          value: 0,
          min: 0,
          max: 100000,
          divisions: 10,
          activeColor: const Color(0xFFFF6705),
          inactiveColor: Colors.grey[300],
          onChanged: (v) {},
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Low\n₹0", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            Text("High\n₹1,00,000+", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          ],
        ),
        const Divider(height: 30),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {},
            child: const Text("Clear All", style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.all(13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {},
            child: const Text("Done", style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

class FilterOptionButton extends StatelessWidget {
  final String label;
  final bool selected;

  const FilterOptionButton({super.key, required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: selected ? const Color(0xFFFF6705) : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black,
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}
