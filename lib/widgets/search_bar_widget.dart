import 'package:flutter/material.dart';
import './filter_widget.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const FilterModal(), 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Image.asset('assets/MagnifyingGlass.png', height: 20, width: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Search for 'Books'",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          GestureDetector(
            onTap: () => _showFilterModal(context),
            child: Image.asset('assets/Filter.png', height: 20, width: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
