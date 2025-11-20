import 'package:flutter/material.dart';
import '../screens/search/search_results_page.dart';
import '../services/filter_state_service.dart';
import '../app.dart'; // For SlidePageRoute
import 'app_button.dart';

class FilterModal extends StatefulWidget {
  final String? searchQuery;
  
  const FilterModal({super.key, this.searchQuery});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  // Filter state
  String selectedListingType = "All";
  List<String> selectedCategories = []; // Changed to list for multiple selection
  String selectedSortBy = "Distance";
  List<String> selectedConditions = []; // Changed to list for multiple selection
  String selectedPickupMethod = "All";
  RangeValues priceRange = const RangeValues(0, 100000);

  // Loading state
  bool isLoading = false;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadFilterState();
  }

  /// Load filter state from cache
  Future<void> _loadFilterState() async {
    try {
      final savedState = await FilterStateService.getFilterState();
      if (savedState != null) {
        setState(() {
          selectedListingType = savedState['listingType'] ?? "All";
          selectedCategories = List<String>.from(savedState['categories'] ?? []);
          selectedSortBy = savedState['sortBy'] ?? "Distance";
          selectedConditions = List<String>.from(savedState['conditions'] ?? []);
          selectedPickupMethod = savedState['pickupMethod'] ?? "All";
          priceRange = RangeValues(
            (savedState['minPrice'] ?? 0.0).toDouble(),
            (savedState['maxPrice'] ?? 100000.0).toDouble(),
          );
          isInitialized = true;
        });
        print('FilterWidget: Filter state loaded from cache');
      } else {
        setState(() {
          isInitialized = true;
        });
        print('FilterWidget: No saved filter state found');
      }
    } catch (e) {
      print('FilterWidget: Error loading filter state: $e');
      setState(() {
        isInitialized = true;
      });
    }
  }

  /// Save current filter state to cache
  Future<void> _saveFilterState() async {
    try {
      final filterState = {
        'listingType': selectedListingType,
        'categories': selectedCategories,
        'sortBy': selectedSortBy,
        'conditions': selectedConditions,
        'pickupMethod': selectedPickupMethod,
        'minPrice': priceRange.start,
        'maxPrice': priceRange.end,
      };
      
      await FilterStateService.saveFilterState(filterState);
      print('FilterWidget: Filter state saved to cache');
    } catch (e) {
      print('FilterWidget: Error saving filter state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
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
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

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
                _buildButtonGroup("Listing Type", ["All", "Regular", "Jauction"], selectedListingType, (value) {
                  setState(() => selectedListingType = value);
                  _saveFilterState(); // Save state when changed
                }),
                _buildMultiSelectButtonGroup("Category", [
                  "Electronics",
                  "Furniture",
                  "Books",
                  "Sports",
                  "Fashion",
                  "Gaming",
                  "Hobbies",
                  "Tickets",
                  "Vehicles",
                  "Miscellaneous"
                ], selectedCategories, (value) {
                  setState(() => selectedCategories = value);
                  _saveFilterState(); // Save state when changed
                }),
                _buildButtonGroup("Sort By", [
                  "Distance",
                  "Price Low to High",
                  "Price High to Low",
                  "Recently Added",
                  "Ending Soon"
                ], selectedSortBy, (value) {
                  setState(() => selectedSortBy = value);
                  _saveFilterState(); // Save state when changed
                }),
                _buildRangeSlider(),
                _buildMultiSelectButtonGroup("Condition", [
                  "Like New",
                  "Gently Used",
                  "Fair",
                  "Needs Fixing"
                ], selectedConditions, (value) {
                  setState(() => selectedConditions = value);
                  _saveFilterState(); // Save state when changed
                }),
                _buildButtonGroup("Pick-up Method", [
                  "All",
                  "Campus Pick-up",
                  "House Pick-up"
                ], selectedPickupMethod, (value) {
                  setState(() => selectedPickupMethod = value);
                  _saveFilterState(); // Save state when changed
                }),
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
          child: Image.asset('assets/X.png', height: 24),
        ),
      ],
    );
  }



  Widget _buildButtonGroup(String title, List<String> options, String selectedValue, Function(String) onChanged) {
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
                    selected: opt == selectedValue,
                    onPressed: () => onChanged(opt),
                  ))
              .toList(),
        ),
        const Divider(height: 30),
      ],
    );
  }

  Widget _buildMultiSelectButtonGroup(String title, List<String> options, List<String> selectedValues, Function(List<String>) onChanged) {
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
                    selected: selectedValues.contains(opt),
                    onPressed: () {
                      final newValues = List<String>.from(selectedValues);
                      if (newValues.contains(opt)) {
                        newValues.remove(opt);
                      } else {
                        newValues.add(opt);
                      }
                      onChanged(newValues);
                    },
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
        RangeSlider(
          values: priceRange,
          min: 0,
          max: 100000,
          divisions: 10,
          activeColor: const Color(0xFFFF6705),
          inactiveColor: Colors.grey[300],
          onChanged: (values) {
            setState(() => priceRange = values);
            _saveFilterState(); // Save state when changed
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Low\n₹${priceRange.start.round()}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            Text("High\n₹${priceRange.end.round()}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
        const Divider(height: 30),
      ],
    );
  }

  Widget _buildFooterButtons() {
  return SafeArea( // ✅ prevents buttons from going behind Android system buttons
    minimum: const EdgeInsets.all(16), // padding for safe distance
    child: Row(
      children: [
        // CLEAR ALL button
        Expanded(
          child: AppButton(
            label: "Clear All",
            onPressed: _clearAllFilters,
            backgroundColor: Colors.white,
            borderColor: Colors.black,
            textColor: Colors.black,
          ),
        ),

        const SizedBox(width: 10),

        // APPLY FILTERS button
        Expanded(
          child: AppButton(
            label: isLoading ? 'Applying...' : "Apply Filters",
            onPressed: isLoading ? null : _applyFilters,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            customChild: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : null,
          ),
        ),
      ],
    ),
  );
}


  void _clearAllFilters() {
    setState(() {
      selectedListingType = "All";
      selectedCategories = [];
      selectedSortBy = "Distance";
      selectedConditions = [];
      selectedPickupMethod = "All";
      priceRange = const RangeValues(0, 100000);
    });
    // Clear the filter state cache
    FilterStateService.clearFilterState();
  }

  void _applyFilters() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Build filters map
      final filters = {
        'listingType': selectedListingType,
        'category': selectedCategories.isNotEmpty ? selectedCategories : null,
        'condition': selectedConditions.isNotEmpty ? selectedConditions : null,
        'pickupMethod': selectedPickupMethod,
        'minPrice': priceRange.start,
        'maxPrice': priceRange.end,
      };

      // Close filter modal
      Navigator.pop(context);
      
      // Navigate to search results with filters
      Navigator.push(
        context,
        SlidePageRoute(
          page: SearchResultsPage(
            searchQuery: widget.searchQuery ?? '',
            appliedFilters: filters,
            sortBy: selectedSortBy,
          ),
        ),
      );
    } catch (e) {
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Filter Error'),
            content: Text('Failed to apply filters: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}

class FilterOptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  const FilterOptionButton({
    super.key, 
    required this.label, 
    required this.selected,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
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
