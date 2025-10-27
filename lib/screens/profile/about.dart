import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AboutTab extends StatefulWidget {
  const AboutTab({super.key});

  @override
  _AboutTabState createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> {
  double avgRating = 0.0;
  List<dynamic> reviews = [];
  int productsSoldCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRatings();
  }

  Future<void> fetchRatings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("userId");
      if (userId == null) {
        setState(() {
          avgRating = 0.0;
          reviews = [];
          productsSoldCount = 0;
          isLoading = false;
        });
        return;
      }

      final authToken = prefs.getString('authToken');
      final url = Uri.parse("https://api.junctionverse.com/ratings/$userId");
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          avgRating = (data["avgRating"] ?? 0).toDouble();
          reviews = data["ratings"] ?? [];
          productsSoldCount = data["productsSoldCount"] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() {
          avgRating = 0.0;
          reviews = [];
          productsSoldCount = 0;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        avgRating = 0.0;
        reviews = [];
        productsSoldCount = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Badges Row
        // Row(
        //   children: [
        //     _buildBadgeIcon('1', 'Hustler', Colors.purple.shade400),
        //     const SizedBox(width: 12),
        //     _buildBadgeIcon('2', 'Bid Boss', Colors.green.shade400),
        //   ],
        // ),
        const SizedBox(height: 20),

        // Ratings & Items Sold
        Row(
          children: [
            _buildSummaryCard(
              icon: Icons.star,
              title: avgRating.toStringAsFixed(1),
              subtitle: 'Ratings',
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              icon: Icons.shopping_bag,
              title: productsSoldCount.toString(),
              subtitle: 'Items Sold',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Reviews header
        const Text("Reviews", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),

        // Reviews list
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            final reviewer = review["ratedBy"] ?? {};
            final avatarUrl = reviewer["avatarUrl"];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewer["fullName"] ?? "Anonymous",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(review["comments"] ?? "No comments"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${review["stars"] ?? 0} ★",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6705)
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildBadgeIcon(String number, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildSummaryCard({required IconData icon, required String title, required String subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
