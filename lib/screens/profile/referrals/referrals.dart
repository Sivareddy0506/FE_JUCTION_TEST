import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/app_button.dart';

class ReferralsPage extends StatefulWidget {
  const ReferralsPage({super.key});

  @override
  State<ReferralsPage> createState() => _ReferralsPageState();
}

class _ReferralsPageState extends State<ReferralsPage> {
  List<dynamic> referrals = [];
  String referralCode = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    if (token.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final referralsResponse = await http.get(
        Uri.parse('https://api.junctionverse.com/user/my-referrals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final profileResponse = await http.get(
        Uri.parse('https://api.junctionverse.com/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (mounted) {
        setState(() {
          if (referralsResponse.statusCode == 200) {
            final decodedReferrals = jsonDecode(referralsResponse.body);
            referrals = decodedReferrals['referredUsers'] ?? [];
          }

          if (profileResponse.statusCode == 200) {
            final profileData = jsonDecode(profileResponse.body);
            referralCode = profileData['user']?['referralCode'] ?? '';
          }

          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied!')),
    );
  }

  void _shareReferral() {
    final message =
        "Join me on Junction! Use my referral code *$referralCode* and get started today.\n\n"
        "📱 Android: https://play.google.com/store/apps/details?id=com.junction.app\n"
        "🍏 iOS: https://apps.apple.com/app/idXXXXXXXX";

    Share.share(message);
  }

  Widget _buildReferralList() {
    if (referrals.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/noreferrals.png'),
          const SizedBox(height: 20),
          const Text(
            "Share your referral code and get ₹50 wallet credit when your friend signs up and posts their first listing.",
            style: TextStyle(fontSize: 14, color: Color(0xFF262626)),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Referrals", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Total: ${referrals.length}", style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: referrals.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final referral = referrals[index];
              final name = referral['fullName'] ?? 'User';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(name),
                trailing: const Text(
                  "Active",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReferralCodeBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF262626)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            referralCode.isNotEmpty ? referralCode : "Loading...",
            style: const TextStyle(fontSize: 16),
          ),
          GestureDetector(
            onTap: _copyReferralCode,
            child: const Text(
              "Copy",
              style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Referrals"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Expanded(child: _buildReferralList()),
                  _buildReferralCodeBox(),
                  AppButton(
                    bottomSpacing: 24,
                    label: "Invite Friend",
                    backgroundColor: const Color(0xFF262626),
                    onPressed: _shareReferral,
                  ),
                ],
              ),
            ),
    );
  }
}
