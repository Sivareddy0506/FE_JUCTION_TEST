import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app.dart';
import '../../../widgets/custom_appbar.dart';
import '../address/address.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  bool isLoading = true;

  String name = '';
  String email = '';
  String mobile = '';
  String currentAddress = '';
  String college = '';
  String enrollmentYear = '';
  String graduationYear = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
Future<void> _loadUserProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) return;

    final uri = Uri.parse('https://api.junctionverse.com/user/profile');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = data['user'];

      // ✅ Fetch the homeAddress from addressJson by matching the homeAddress ID
      String addressText = '';
      final homeAddressId = user['homeAddress'];
      dynamic addressJson = user['addressJson'];

      // Parse addressJson if it's a string (JSON string from database)
      if (addressJson is String) {
        try {
          addressJson = jsonDecode(addressJson);
        } catch (e) {
          print("Error parsing addressJson string: $e");
          addressJson = null;
        }
      }

      if (homeAddressId != null && addressJson is List) {
        final defaultAddress = addressJson.firstWhere(
          (addr) => addr['id'] == homeAddressId || addr['id']?.toString() == homeAddressId.toString(),
          orElse: () => null,
        );
        
        if (defaultAddress != null) {
          addressText = "${defaultAddress['label'] ?? ''} — ${defaultAddress['address'] ?? ''}";
        }
      }

      setState(() {
        name = user['fullName'] ?? '';
        email = user['email'] ?? '';
        mobile = user['phoneNumber'] ?? '';
        currentAddress = addressText;
        college = user['university'] ?? '';
        enrollmentYear =
            "${user['enrollmentMonth'] ?? 'June'} ${user['enrollmentYear'] ?? '2023'}";
        graduationYear =
            "${user['graduationMonth'] ?? 'May'} ${user['graduationYear'] ?? '2027'}";
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  } catch (e) {
    print("Error: $e");
    setState(() => isLoading = false);
  }
}


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF262626),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool showEdit = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8894),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF262626),
                  ),
                ),
              ],
            ),
          ),
          if (showEdit)
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
              onPressed: () async {
                // Wait for result and refresh data when returning
                final result = await Navigator.push(
                  context,
                  SlidePageRoute(page: const AddressPage()),
                );
                
                // Refresh profile data when returning from address page
                if (result != null || mounted) {
                  _loadUserProfile();
                }
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Personal Information"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Personal Details"),
                  _buildDetailItem("Name", name),
                  _buildDetailItem("Mobile Number", mobile),
                  _buildDetailItem("Email ID", email),
                  _buildDetailItem("Current Address", currentAddress, showEdit: true),

                  _buildSectionTitle("Academic Details"),
                  _buildDetailItem("College", college),
                  _buildDetailItem("Enrollment Year", enrollmentYear),
                  _buildDetailItem("Graduation Year", graduationYear),
                ],
              ),
            ),
    );
  }
}
