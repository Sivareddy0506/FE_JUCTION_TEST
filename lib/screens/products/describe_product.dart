import 'package:flutter/material.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/form_text.dart';
import '../../../widgets/app_dropdown.dart';
import './add_product_images.dart';

class DescribeProductPage extends StatefulWidget {
  final String selectedCategory;

  const DescribeProductPage({super.key, required this.selectedCategory});

  @override
  State<DescribeProductPage> createState() => _DescribeProductPageState();
}

class ProductDetails {
  final String category;
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
  final List<String> conditionOptions = ['Good', 'Fair', 'Excellent'];

  String? selectedUsage;
  String? selectedCondition;

  bool get isFormValid {
    final isYearValid = RegExp(r'^\d{4}$').hasMatch(yearController.text);
    final isPriceValid = double.tryParse(priceController.text) != null;

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
    final productDetails = ProductDetails(
      category: widget.selectedCategory,
      title: titleController.text.trim(),
      price: priceController.text.trim(),
      description: descriptionController.text.trim(),
      productName: productNameController.text.trim(),
      year: yearController.text.trim(),
      usage: selectedUsage!,
      condition: selectedCondition!,
      brandName: brandController.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductImagesPage(
          selectedCategory: productDetails.category,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Place a Listing"),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
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
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF262626)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Selected Category: ${widget.selectedCategory}",
                            style: const TextStyle(fontSize: 12, color: Color(0xFF323537)),
                          ),
                          const SizedBox(height: 32),

                          const Text("Ad Details", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Title *',
                            placeholder: 'Eg: Samsung A14 for urgent sale',
                            controller: titleController,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Price *',
                            placeholder: '₹ 34,000',
                            controller: priceController,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Product Description',
                            placeholder: 'Good condition, box included',
                            controller: descriptionController,
                            maxLines: 5,
                          ),
                          const SizedBox(height: 32),

                          const Text("Product Details", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Product Name',
                            placeholder: 'Eg: Product Name',
                            controller: productNameController,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Year of Purchase',
                            placeholder: 'Eg: 2020',
                            controller: yearController,
                          ),
                          const SizedBox(height: 16),

                          AppDropdown(
                            label: 'Usage',
                            items: usageOptions,
                            value: selectedUsage,
                            onChanged: (val) => setState(() => selectedUsage = val),
                          ),
                          const SizedBox(height: 16),

                          AppDropdown(
                            label: 'Condition',
                            items: conditionOptions,
                            value: selectedCondition,
                            onChanged: (val) => setState(() => selectedCondition = val),
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            label: 'Brand Name',
                            placeholder: 'Eg: Samsung, Apple, etc.',
                            controller: brandController,
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
