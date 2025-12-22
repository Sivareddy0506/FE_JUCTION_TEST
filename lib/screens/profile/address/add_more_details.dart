import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/form_text.dart';
import '../../../widgets/custom_appbar.dart';
import 'package:http/http.dart' as http;
import '../../../app.dart'; // For SlidePageRoute
import 'address.dart';
import 'address_response.dart';


class AddMoreDetailsPage extends StatefulWidget {
  final String address;
  final String id;
  final bool isEditable;
  final double? latitude;
  final double? longitude;

  const AddMoreDetailsPage({
    super.key,
    required this.id,
    required this.address,
    required this.isEditable,
    this.latitude,
    this.longitude,
  });

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

  /// Fetch existing addresses to check for duplicate names
  Future<List<Address>> _fetchExistingAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) return [];

      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/user/get-address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addressResponse = AddressResponse.fromJson(data);
        return addressResponse.addresses;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
      return [];
    }
  }

  /// Check if address name already exists (case-insensitive)
  /// When editing, exclude the current address from the check
  Future<bool> _isDuplicateName(String name) async {
    final existingAddresses = await _fetchExistingAddresses();
    final nameLower = name.trim().toLowerCase();

    for (final address in existingAddresses) {
      // When editing, skip the current address being edited
      if (widget.isEditable && address.id == widget.id) {
        continue;
      }
      
      // Check for duplicate name (case-insensitive)
      if (address.label.trim().toLowerCase() == nameLower) {
        return true;
      }
    }
    return false;
  }

  Future<void> _submit() async {
    if (!isFormValid) return;

    // Check for duplicate name before submitting
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the address')),
      );
      return;
    }

    // Check for duplicate name
    setState(() => isLoading = true);
    final isDuplicate = await _isDuplicateName(name);
    
    if (isDuplicate) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An address with this name already exists. Please use a different name.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
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
      // Add coordinates if available
      if (widget.latitude != null && widget.longitude != null) {
        map["latitude"] = widget.latitude;
        map["longitude"] = widget.longitude;
      }
    } else {
      uri = Uri.parse('https://api.junctionverse.com/user/addnew-address');
      map = {
        "label": nameController.text,
        "address": addressController.text,
        "setAsDefault": true,
      };
      // Add coordinates if available
      if (widget.latitude != null && widget.longitude != null) {
        map["latitude"] = widget.latitude;
        map["longitude"] = widget.longitude;
      }
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
          SlidePageRoute(page: const AddressPage()),
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
