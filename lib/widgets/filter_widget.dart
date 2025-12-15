import 'package:flutter/material.dart';
import '../screens/search/search_results_page.dart';
import '../services/filter_state_service.dart';
import '../constants/category_subcategories.dart';
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
  List<String> selectedSubCategories = []; // Subcategory selection
  String selectedSortBy = "Distance";
  List<String> selectedConditions = []; // Changed to list for multiple selection
  String selectedPickupMethod = "All";
  RangeValues priceRange = const RangeValues(0, 100000);
  double? selectedRadius = 50.0; // Default radius in km (null means unlimited)

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
          selectedSubCategories = List<String>.from(savedState['subCategories'] ?? []);
          selectedSortBy = savedState['sortBy'] ?? "Distance";
          selectedConditions = List<String>.from(savedState['conditions'] ?? []);
          selectedPickupMethod = savedState['pickupMethod'] ?? "All";
          priceRange = RangeValues(
            (savedState['minPrice'] ?? 0.0).toDouble(),
            (savedState['maxPrice'] ?? 100000.0).toDouble(),
          );
          // Handle radius: null means unlimited, otherwise use saved value or default to 50
          final savedRadius = savedState['radius'];
          selectedRadius = savedRadius == null ? 50.0 : (savedRadius is double ? savedRadius : savedRadius.toDouble());
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
        'subCategories': selectedSubCategories,
        'sortBy': selectedSortBy,
        'conditions': selectedConditions,
        'pickupMethod': selectedPickupMethod,
        'minPrice': priceRange.start,
        'maxPrice': priceRange.end,
        'radius': selectedRadius,
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
                  "Hobbies",
                  "Vehicles",
                  "Other"
                ], selectedCategories, (value) {
                  setState(() {
                    selectedCategories = value;
                    // Clear subcategories that don't belong to selected categories
                    _updateSubCategoriesForSelectedCategories();
                  });
                  _saveFilterState(); // Save state when changed
                }),
                // Show subcategories only if categories are selected
                if (selectedCategories.isNotEmpty) _buildSubCategorySection(),
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
                _buildRadiusSlider(),
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

  Widget _buildRadiusSlider() {
    // Define radius options: [50, 100, 150, 200, 250, 300, 400, 500, 750, 1000, null (unlimited)]
    // null represents unlimited/no limit
    final List<double?> radiusOptions = [50, 100, 150, 200, 250, 300, 400, 500, 750, 1000, null];
    
    // Find current index - handle null comparison properly
    int currentIndex = 0;
    if (selectedRadius == null) {
      currentIndex = radiusOptions.length - 1; // Last option is unlimited
    } else {
      currentIndex = radiusOptions.indexWhere((r) => r == selectedRadius);
      if (currentIndex < 0) {
        currentIndex = 0; // Default to first if not found
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Search Radius", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        const SizedBox(height: 14),
        Slider(
          value: currentIndex.toDouble(),
          min: 0,
          max: (radiusOptions.length - 1).toDouble(),
          divisions: radiusOptions.length - 1,
          activeColor: const Color(0xFFFF6705),
          inactiveColor: Colors.grey[300],
          onChanged: (value) {
            final index = value.round();
            setState(() {
              selectedRadius = radiusOptions[index];
            });
            _saveFilterState(); // Save state when changed
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              selectedRadius == null 
                ? "No Limit" 
                : "${selectedRadius!.round()} km",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFF6705),
              ),
            ),
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


  /// Get all subcategories for selected categories (excluding "Other" for filters)
  List<String> _getAvailableSubCategories() {
    final Set<String> allSubCategories = {};
    for (final category in selectedCategories) {
      final subCategories = CategorySubcategories.getSubcategories(category);
      // Filter out "Other" subcategory as it's not used in filters
      allSubCategories.addAll(subCategories.where((subCat) => subCat != 'Other'));
    }
    return allSubCategories.toList()..sort();
  }

  /// Update subcategories list to only include those from selected categories
  void _updateSubCategoriesForSelectedCategories() {
    final availableSubCategories = _getAvailableSubCategories();
    selectedSubCategories.removeWhere(
      (subCat) => !availableSubCategories.contains(subCat),
    );
  }

  /// Build subcategory selection section
  Widget _buildSubCategorySection() {
    final availableSubCategories = _getAvailableSubCategories();
    
    if (availableSubCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildMultiSelectButtonGroup("Subcategory", availableSubCategories, selectedSubCategories, (value) {
      setState(() => selectedSubCategories = value);
      _saveFilterState(); // Save state when changed
    });
  }

  void _clearAllFilters() {
    setState(() {
      selectedListingType = "All";
      selectedCategories = [];
      selectedSubCategories = [];
      selectedSortBy = "Distance";
      selectedConditions = [];
      selectedPickupMethod = "All";
      priceRange = const RangeValues(0, 100000);
      selectedRadius = 50.0;
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
        'subCategory': selectedSubCategories.isNotEmpty ? selectedSubCategories : null,
        'condition': selectedConditions.isNotEmpty ? selectedConditions : null,
        'pickupMethod': selectedPickupMethod,
        'minPrice': priceRange.start,
        'maxPrice': priceRange.end,
        'radius': selectedRadius, // null means unlimited
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
