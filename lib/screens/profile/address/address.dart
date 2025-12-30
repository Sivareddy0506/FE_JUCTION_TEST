import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../widgets/app_button.dart';
import '../../../widgets/custom_appbar.dart';
import 'address_response.dart';
import 'location_map.dart'; // adjust import if needed
import '../../../app.dart'; // For SlidePageRoute
import '../../../services/profile_service.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  List<Address> _addresses = [];
  String? _defaultAddressId;
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
        final addressResponse = AddressResponse.fromJson(data);

        setState(() {
          _addresses = addressResponse.addresses;
          _defaultAddressId = addressResponse.defaultAddressId;
          _isLoading = false;
        });
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

  Future<void> _setDefaultAddress(String addressId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse('https://api.junctionverse.com/user/set-default-address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'addressId': addressId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _defaultAddressId = addressId;
        });
        
        // Invalidate profile cache so location updates immediately
        await ProfileService.clearProfileCache();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default address updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception("Failed to set default address");
      }
    } catch (e) {
      print('Error setting default address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToEdit(bool isItFromEdit, {Address? editingAddress}) async {
    final result = await Navigator.push(
      context,
      SlidePageRoute(
        page: LocationMapPage(
          initialAddress: editingAddress,
          isItFromEdit: isItFromEdit,
        ),
      ),
    );

    if (result != null && result is Map) {
      _fetchAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,  // Block automatic pop to control result value
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Pop was blocked, manually pop and return true to trigger refresh
          Navigator.of(context).pop(true);
        }
        // If didPop is true (shouldn't happen with canPop: false), do nothing
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Manage Address"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Return true to trigger refresh in PersonalInfoPage
              Navigator.of(context).pop(true);
            },
          ),
        ),
        body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _addresses.isEmpty
                ? const Center(child: Text("No addresses found."))
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final addressObj = _addresses[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Radio<String>(
                              value: addressObj.id,
                              groupValue: _defaultAddressId,
                              onChanged: (value) async {
                                if (value != null) {
                                  await _setDefaultAddress(value);
                                }
                              },
                            ),
                            Text(
                              addressObj.label[0].toUpperCase() +
                                  addressObj.label.substring(1),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _navigateToEdit(true,
                                  editingAddress: addressObj),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 48),
                          child: Text(
                            addressObj.address,
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
              onPressed: () => _navigateToEdit(false),
            ),
          ),
        ],
      ),
      ),
    );
  }
}