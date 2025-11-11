import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AboutTab extends StatefulWidget {
  final String? userId;

  const AboutTab({super.key, this.userId});

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
      String? userId = widget.userId ?? prefs.getString("userId");

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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE3E3E3),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    bool isStar = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxHeight: 76),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isStar)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/Star.png", width: 24, height: 24),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF8A8894),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("About"),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                title: avgRating.toStringAsFixed(1),
                subtitle: 'Ratings',
                isStar: true,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: productsSoldCount.toString(),
                subtitle: 'Items Sold',
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildSectionHeader("Reviews"),
          const SizedBox(height: 20),
          if (reviews.isEmpty)
            const Text("No reviews yet", style: TextStyle(color: Colors.grey)),
          ...reviews.map((review) {
            final reviewer = review["ratedBy"] ?? {};
            final avatarUrl = reviewer["avatarUrl"];
            final name = reviewer["fullName"] ?? "Anonymous";
            final comment = review["comments"] ?? "No comments";

            return Container(
              margin: const EdgeInsets.only(bottom: 30),
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        comment,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -10,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 8,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : const AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

Widget _buildStatCard({
  required String title,
  required String subtitle,
  bool isStar = false,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(
        maxHeight: 76, 
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isStar)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/Star.png", width: 24, height: 24),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8A8894),
            ),
          ),
        ],
      ),
    ),
  );
}
  