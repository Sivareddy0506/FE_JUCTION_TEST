import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:junction/app_state.dart';
import '../app.dart';
import '../../../widgets/custom_appbar.dart';

import '../screens/products/add_product_images.dart';
import 'app_button.dart';

class TuneAuctionWidget extends StatefulWidget {
  final String selectedCategory;
  final String selectedSubCategory;
  final String title;
  final String price;
  final String description;
  final String productName;
  final String yearOfPurchase;
  final String brandName;
  final String usage;
  final String condition;

  const TuneAuctionWidget({
    super.key,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.title,
    required this.price,
    required this.description,
    required this.productName,
    required this.yearOfPurchase,
    required this.brandName,
    required this.usage,
    required this.condition,
  });
  @override
  State<TuneAuctionWidget> createState() => _TuneAuctionWidgetState();
}

class _TuneAuctionWidgetState extends State<TuneAuctionWidget> {
  DateTime? _selectedDate;
  String? _listingDuration;

  final List<String> durations = [
    '1 Day',
    '3 Days',
    '7 Days',
    '14 Days',
  ];

  Future<void> _pickAuctionDate() async {
    final now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple, // selected date color
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple, // cancel/confirm color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        AppState.instance.auctionDate = _selectedDate!.toUtc().toIso8601String();
      });
    }
  }

  void gotoNextPage(){
    Navigator.push(
      context,
      SlidePageRoute(
        page: AddProductImagesPage(
          selectedCategory: widget.selectedCategory,
          selectedSubCategory: widget.selectedSubCategory,
          title: widget.title,
          price: widget.price,
          description: widget.description,
          productName: widget.productName,
          yearOfPurchase: widget.yearOfPurchase,
          brandName: widget.brandName,
          usage: widget.usage,
          condition: widget.condition,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.black87, width: 1),
    );


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
                            "Tune Your Auction",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF262626)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Auction Settings',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 16),

                          // Auction Date
                          const Text('* Auction Date'),
                          const SizedBox(height: 4),
                          TextFormField(
                            readOnly: true,
                            onTap: _pickAuctionDate,
                            controller: TextEditingController(
                              text: _selectedDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                                  : '',
                            ),
                            decoration: InputDecoration(
                              hintText: 'DD/MM/YYYY',
                              suffixIcon: IconButton(
                                icon: Image.asset(
                                  'assets/DatePicker.png',
                                  height: 24,
                                  width: 24,
                                ),
                                onPressed: _pickAuctionDate,
                              ),
                              border: borderStyle,
                              enabledBorder: borderStyle,
                              focusedBorder: borderStyle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Start bid today or in 7 days'),
                          const SizedBox(height: 24),

                          // Listing Duration
                          const Text('* Listing Duration'),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _listingDuration,
                            decoration: InputDecoration(
                              hintText: 'Enter Duration',
                              border: borderStyle,
                              enabledBorder: borderStyle,
                              focusedBorder: borderStyle,
                            ),
                            items: durations.map((duration) {
                              return DropdownMenuItem(
                                value: duration,
                                child: Text(duration),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _listingDuration = value;
                                if(value != null){
                                  if(value =="1 Day"){
                                    value = value!.replaceAll(' Day', '');
                                  }else{
                                    value = value!.replaceAll(' Days', '');
                                  }
                                  AppState.instance.listingDuration = value!;
                                }
                              });
                            },
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
                  onPressed: (){
                    if(isFormValid){
                      gotoNextPage();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool get isFormValid {
    if(_listingDuration!.isEmpty || _selectedDate == null){
      return false;
    }
    return true;
  }

}