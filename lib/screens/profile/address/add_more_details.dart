import 'package:flutter/material.dart';
import '../../../widgets/form_text.dart';
import '../../../widgets/custom_appbar.dart';

class AddMoreDetailsPage extends StatefulWidget {
  final String address;

  const AddMoreDetailsPage({super.key, required this.address});

  @override
  State<AddMoreDetailsPage> createState() => _AddMoreDetailsPageState();
}

class _AddMoreDetailsPageState extends State<AddMoreDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    addressController.text = widget.address;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Add More Details"),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppTextField(
              label: 'Name *',
              placeholder: 'Home or Office',
              controller: nameController,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Address',
              placeholder: 'fetched from location page',
              controller: addressController,
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
}
