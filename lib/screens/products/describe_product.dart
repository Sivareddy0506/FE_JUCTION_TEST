import 'package:flutter/material.dart';
import 'package:junction/app_state.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/form_text.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/listing_progress_indicator.dart';
import '../../widgets/tune_auction.dart';
import './add_product_images.dart';
import '../../app.dart'; // For SlidePageRoute
import '../../constants/category_placeholders.dart';

class DescribeProductPage extends StatefulWidget {
  final String selectedCategory;
  final String selectedSubCategory;

  const DescribeProductPage({
    super.key,
    required this.selectedCategory,
    required this.selectedSubCategory,
  });

  @override
  State<DescribeProductPage> createState() => _DescribeProductPageState();
}

class ProductDetails {
  final String category;
  final String subCategory;
  final String title;
  final String price;
  final String description;
  final String productName;
  final String year;
  final String usage;
  final String condition;
  final String brandName;

  ProductDetails({
    required this.category,
    required this.subCategory,
    required this.title,
    required this.price,
    required this.description,
    required this.productName,
    required this.year,
    required this.usage,
    required this.condition,
    required this.brandName,
  });
}

class _DescribeProductPageState extends State<DescribeProductPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController brandController = TextEditingController();

  final List<String> usageOptions = ['Normal Usage', 'Heavy Usage', 'Like New'];
  final List<String> conditionOptions = ['Like New', 'Gently Used', 'Fair', 'Needs Fixing'];

  String? selectedUsage = '';
  String? selectedCondition;
  String? priceError;
  String? yearError;

  bool get isFormValid {
    final isYearValid = _validateYear(yearController.text) == null;
    final isPriceValid = _validatePrice(priceController.text) == null;

    return titleController.text.isNotEmpty &&
        priceController.text.isNotEmpty &&
        isPriceValid &&
        productNameController.text.isNotEmpty &&
        yearController.text.isNotEmpty &&
        isYearValid &&
        brandController.text.isNotEmpty &&
        selectedUsage != null &&
        selectedCondition != null;
  }

  String? _validatePrice(String value) {
  if (value.isEmpty) return null;

  // Remove any commas, spaces, and rupee symbols
  final cleanedValue = value
      .replaceAll(',', '')
      .replaceAll(' ', '')
      .replaceAll('₹', '')
      .replaceAll('Rs', '')
      .replaceAll('rs', '')
      .trim();

  // Check if starts with invalid characters
  if (cleanedValue.startsWith('.') || cleanedValue.startsWith(',')) {
    return 'Price cannot start with a decimal point';
  }

  // Check if starts with 0 followed by digits (like 0123)
  if (RegExp(r'^0\d+').hasMatch(cleanedValue)) {
    return 'Invalid price format';
  }

  // Check if it's a valid number
  final price = double.tryParse(cleanedValue);
  if (price == null) {
    return 'Please enter a valid price';
  }

  // Check if price is positive (handles 0 and negative)
  if (price <= 0) {
    return 'Price must be greater than 0';
  }

  return null;
}

  String? _validateYear(String value) {
    if (value.isEmpty) return null;

    final year = int.tryParse(value);
    final currentYear = DateTime.now().year;

    if (year == null) {
      return 'Please enter a valid year';
    }

    if (year < 1900) {
      return 'Year cannot be before 1900';
    }

    if (year > currentYear) {
      return 'Year cannot be in the future';
    }

    return null;
  }

  void _onPriceChanged(String value) {
    setState(() {
      priceError = _validatePrice(value);
    });
  }

  void _onYearChanged(String value) {
    setState(() {
      yearError = _validateYear(value);
    });
  }

  Future<void> _showYearPicker() async {
    final currentYear = DateTime.now().year;
    final selectedYear = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 450,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Select Year of Purchase',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF262626),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentYear - 1899,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final year = currentYear - index;
                      final isSelected = yearController.text == year.toString();
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(year),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF262626).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected
                                  ? const Color(0xFF262626)
                                  : const Color(0xFF212121),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                  backgroundColor: Colors.white,
                  borderColor: const Color(0xFF262626),
                  textColor: const Color(0xFF262626),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedYear != null) {
      yearController.text = selectedYear.toString();
      _onYearChanged(selectedYear.toString());
      _updateFormState();
    }
  }

  void _updateFormState() => setState(() {});

  @override
  void initState() {
    super.initState();
    titleController.addListener(_updateFormState);
    priceController.addListener(_updateFormState);
    productNameController.addListener(_updateFormState);
    yearController.addListener(_updateFormState);
    brandController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    productNameController.dispose();
    yearController.dispose();
    brandController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    final priceValidation = _validatePrice(priceController.text);
    final yearValidation = _validateYear(yearController.text);

    if (priceValidation != null || yearValidation != null) {
      setState(() {
        priceError = priceValidation;
        yearError = yearValidation;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before proceeding'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cleanedPrice = priceController.text
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('₹', '')
        .replaceAll('Rs', '')
        .replaceAll('rs', '')
        .trim();

    final productDetails = ProductDetails(
      category: widget.selectedCategory,
      subCategory: widget.selectedSubCategory,
      title: titleController.text.trim(),
      price: cleanedPrice,
      description: descriptionController.text.trim(),
      productName: productNameController.text.trim(),
      year: yearController.text.trim(),
      usage: selectedUsage!,
      condition: selectedCondition!,
      brandName: brandController.text.trim(),
    );

    if (AppState.instance.isJuction == true) {
      Navigator.push(
        context,
        SlidePageRoute(
          page: TuneAuctionWidget(
            selectedCategory: productDetails.category,
            selectedSubCategory: productDetails.subCategory,
            title: productDetails.title,
            price: productDetails.price,
            description: productDetails.description,
            productName: productDetails.productName,
            yearOfPurchase: productDetails.year,
            brandName: productDetails.brandName,
            usage: productDetails.usage,
            condition: productDetails.condition,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        SlidePageRoute(
          page: AddProductImagesPage(
            selectedCategory: productDetails.category,
            selectedSubCategory: productDetails.subCategory,
            title: productDetails.title,
            price: productDetails.price,
            description: productDetails.description,
            productName: productDetails.productName,
            yearOfPurchase: productDetails.year,
            brandName: productDetails.brandName,
            usage: productDetails.usage,
            condition: productDetails.condition,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Place a Listing"),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: const ListingProgressIndicator(currentStep: 2),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Describe Your Product",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF262626),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Category: ${widget.selectedCategory} | Subcategory: ${widget.selectedSubCategory}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF323537),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 1. Title
                          AppTextField(
                            label: 'Title *',
                            placeholder: CategoryPlaceholders.getPlaceholder(widget.selectedSubCategory, 'title'),
                            controller: titleController,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Color(0xFF8A8894),
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Include key words in title to ensure listing has improved visibility',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8A8894),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2. Product Name
                          AppTextField(
                            label: 'Product Name *',
                            placeholder: CategoryPlaceholders.getPlaceholder(widget.selectedSubCategory, 'productName'),
                            controller: productNameController,
                          ),
                          const SizedBox(height: 16),

                          // 3. Product Description
                          AppTextField(
                            label: 'Product Description *',
                            placeholder: CategoryPlaceholders.getPlaceholder(widget.selectedSubCategory, 'description'),
                            controller: descriptionController,
                            maxLines: 5,
                          ),
                          const SizedBox(height: 16),

                          // 4. Brand / Author / Artist
                          AppTextField(
                            label: 'Brand / Author / Artist *',
                            placeholder: CategoryPlaceholders.getPlaceholder(widget.selectedSubCategory, 'brandName'),
                            controller: brandController,
                          ),
                          const SizedBox(height: 16),

                          // 5. Condition
                          AppDropdown(
                            label: 'Condition *',
                            items: conditionOptions,
                            value: selectedCondition,
                            onChanged: (val) => setState(() => selectedCondition = val),
                          ),
                          const SizedBox(height: 16),

                          // 6. Year of Purchase
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _showYearPicker,
                                  child: AbsorbPointer(
                                    child: AppTextField(
                                      label: 'Year of Purchase *',
                                      placeholder: CategoryPlaceholders.getPlaceholder(widget.selectedSubCategory, 'year'),
                                      controller: yearController,
                                    ),
                                  ),
                              ),
                              if (yearError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 12),
                                  child: Text(
                                    yearError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: Color(0xFF8A8894),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tap to select year',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 7. Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextField(
                                label: 'Price *',
                                placeholder: CategoryPlaceholders.getPlaceholder(widget.selectedSubCategory, 'price'),
                                controller: priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: _onPriceChanged,
                                prefixText: '₹ ',
                              ),
                              if (priceError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 12),
                                  child: Text(
                                    priceError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: AppButton(
                  bottomSpacing: 0,
                  label: 'Next',
                  onPressed: isFormValid ? _goToNextPage : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}