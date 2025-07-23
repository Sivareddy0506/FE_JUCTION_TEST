import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_appbar.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool isLoading = true;

  bool chatNotifications = false;
  bool listingActivity = false;
  bool biddingAuctions = false;
  bool offersTransactions = false;
  bool appUpdates = false;
  bool emailAlerts = false;

  @override
  void initState() {
    super.initState();
    _fetchPreferences();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> _fetchPreferences() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/user/notification-preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          chatNotifications = data['chatNotifications'] ?? false;
          listingActivity = data['listingActivity'] ?? false;
          biddingAuctions = data['biddingAuctions'] ?? false;
          offersTransactions = data['offersTransactions'] ?? false;
          appUpdates = data['appUpdates'] ?? false;
          emailAlerts = data['emailAlerts'] ?? false;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updatePreferences() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    final payload = {
      "chatNotifications": chatNotifications,
      "listingActivity": listingActivity,
      "biddingAuctions": biddingAuctions,
      "offersTransactions": offersTransactions,
      "appUpdates": appUpdates,
      "emailAlerts": emailAlerts,
    };

    await http.put(
      Uri.parse('https://api.junctionverse.com/user/notification-preferences'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
  }

  Widget buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8894),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1,
            child: SizedBox(
              width: 38,
              height: 23,
              child: FittedBox(
                fit: BoxFit.fill,
                child: Switch(
                  value: value,
                  onChanged: (bool newValue) async {
                    setState(() => onChanged(newValue));
                    await _updatePreferences();
                    await _fetchPreferences();
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFFFF6705),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFC9C8D3),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Notification Preferences"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPreferences,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                children: [
                  buildToggle(
                    title: "Chat Notifications",
                    subtitle: "Messages, replies, and new conversations with buyers or sellers.",
                    value: chatNotifications,
                    onChanged: (val) => chatNotifications = val,
                  ),
                  buildToggle(
                    title: "Listing Activity",
                    subtitle: "Updates when someone interacts with your listing.",
                    value: listingActivity,
                    onChanged: (val) => listingActivity = val,
                  ),
                  buildToggle(
                    title: "Bidding & Auctions",
                    subtitle: "Bids placed, outbids, auction ending reminders, and auction results.",
                    value: biddingAuctions,
                    onChanged: (val) => biddingAuctions = val,
                  ),
                  buildToggle(
                    title: "Offers & Transactions",
                    subtitle: "New offers, accepted deals, purchase confirmations, and payout updates.",
                    value: offersTransactions,
                    onChanged: (val) => offersTransactions = val,
                  ),
                  buildToggle(
                    title: "App Updates",
                    subtitle: "Feature updates, referral rewards, and important news from Junction.",
                    value: appUpdates,
                    onChanged: (val) => appUpdates = val,
                  ),
                  buildToggle(
                    title: "Email Alerts",
                    subtitle: "For important updates even when you're offline.",
                    value: emailAlerts,
                    onChanged: (val) => emailAlerts = val,
                  ),
                ],
              ),
            ),
    );
  }
}
