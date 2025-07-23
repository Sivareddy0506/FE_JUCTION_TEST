import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';
import 'location_map.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  Map<String, String> _addressMap = {};
  String? _selectedAddressLabel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/user/get-address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addresses = data['addressJson']?['addresses'] as Map<String, dynamic>?;
        final defaultAddress = data['addressJson']?['default'] as String?;

        if (addresses != null) {
          setState(() {
            _addressMap = addresses.map((k, v) => MapEntry(k, v.toString()));
            _selectedAddressLabel = defaultAddress;
            _isLoading = false;
          });
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Failed to load addresses");
      }
    } catch (e) {
      print('Error fetching addresses: $e');
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _navigateToEdit({String? editingAddress}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationMapPage(initialAddress: editingAddress)
      ),
    );

    if (result != null && result is Map) {
      _fetchAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Manage Address"),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _addressMap.isEmpty
                    ? const Center(child: Text("No addresses found."))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _addressMap.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final label = _addressMap.keys.elementAt(index);
                          final address = _addressMap[label]!;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Radio<String>(
                                        value: label,
                                        groupValue: _selectedAddressLabel,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedAddressLabel = value;
                                          });
                                        },
                                      ),
                                      Text(label[0].toUpperCase() + label.substring(1)),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _navigateToEdit(editingAddress: address),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 48),
                                    child: Text(
                                      address,
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppButton(
              bottomSpacing: 20,
              label: 'Add New Address',
              backgroundColor: const Color(0xFF262626),
              onPressed: () => _navigateToEdit(),
            ),
          ),
        ],
      ),
    );
  }
}
