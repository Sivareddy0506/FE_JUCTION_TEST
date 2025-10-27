import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/form_text.dart';
import '../../../widgets/custom_appbar.dart';
import 'package:http/http.dart' as http;

import 'address.dart';


class AddMoreDetailsPage extends StatefulWidget {
  final String address;
  final String id;
  final bool isEditable;

  const AddMoreDetailsPage(
      {super.key,required this.id, required this.address, required this.isEditable});

  @override
  State<AddMoreDetailsPage> createState() => _AddMoreDetailsPageState();
}

class _AddMoreDetailsPageState extends State<AddMoreDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  bool isLoading = false;

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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: AppButton(
          bottomSpacing: 0, // or remove it if handled by Padding
          label: isLoading ? 'Saving...' : 'Save',
          backgroundColor: const Color(0xFF262626),
          onPressed: _submit,
        ),
      ),
    );

  }

  bool get isFormValid {
    if (nameController.text.isEmpty || addressController.text.isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!isFormValid) return;

    setState(() => isLoading = true);
    Uri uri;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    Map<String, dynamic> map = {};

    if (widget.isEditable) {
      uri = Uri.parse('https://api.junctionverse.com/user/update-address');
      map = {
        "addressId": widget.id,
        "label": nameController.text,
        "address": addressController.text,
      };
    } else {
      uri = Uri.parse('https://api.junctionverse.com/user/addnew-address');
      map = {
        "label": nameController.text,
        "address": addressController.text,
        "setAsDefault": true,
      };
    }

    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = widget.isEditable
          ? await http.put(uri, headers: headers, body: json.encode(map))
          : await http.post(uri, headers: headers, body: json.encode(map));

      if (response.statusCode == 200) {
        // Show success message
        String text = widget.isEditable
            ? "Address update successfully"
            : "Address added successfully";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text)),
        );

        int count = 0;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AddressPage()),
              (Route<dynamic> route) {
            return count++ >= 3; // keep the 3rd screen and above
          },
        );
      } else {
        // Show error from response body or fallback message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.body.isNotEmpty
                ? response.body
                : 'Something went wrong'}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

}
