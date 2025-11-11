import 'package:flutter/material.dart';
import './filter_widget.dart';
import '../screens/search/search_results_page.dart';
import '../app.dart'; // For SlidePageRoute

class SearchBarWidget extends StatefulWidget {
  final String? initialQuery;
  final Function(String)? onSearch;

  const SearchBarWidget({
    super.key,
    this.initialQuery,
    this.onSearch,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FilterModal(
        searchQuery: _searchController.text.trim(),
      ),
    );
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Call the onSearch callback if provided
      widget.onSearch?.call(query);

      // Navigate to search results page with enhanced search
      Navigator.push(
        context,
        SlidePageRoute(
          page: SearchResultsPage(
            searchQuery: query,
          ),
        ),
      ).then((_) {
        setState(() {
          _isSearching = false;
        });
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Search Error'),
            content: Text('Failed to perform search: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
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
          Expanded(
            child: GestureDetector(
              onTap: () {
                _searchFocusNode.requestFocus();
              },
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  hintText: "Search for 'Books'",
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 16),
                onSubmitted: (_) => _performSearch(),
                textInputAction: TextInputAction.search,
                onTap: () {
                  // Show search history or suggestions when tapped
                },
              ),
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
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
