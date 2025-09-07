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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRatings();
  }

  Future<void> fetchRatings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("userId"); // logged-in user id

      if (userId == null) {
        setState(() {
          avgRating = 0.0;
          reviews = [];
          isLoading = false;
        });
        return;
      }

      final url = Uri.parse("https://api.junctionverse.com/ratings/$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          avgRating = (data["avgRating"] ?? 0).toDouble();
          reviews = data["ratings"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          avgRating = 0.0;
          reviews = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching ratings: $e");
      setState(() {
        avgRating = 0.0;
        reviews = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Ratings Summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const Icon(Icons.star, color: Colors.black, size: 30),
                const SizedBox(height: 5),
                Text(avgRating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text("Ratings"),
              ],
            ),
            Column(
              children: [
                const Icon(Icons.shopping_bag, color: Colors.black, size: 30),
                const SizedBox(height: 5),
                Text("12", // Replace with API value if available
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text("Items Sold"),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        const Text("Reviews", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),

        Expanded(
          child: reviews.isEmpty
              ? const Center(
                  child: Text(
                    "No ratings found",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(review["ratedBy"]["fullName"] ?? "Anonymous"),
                        subtitle: Text(review["comments"] ?? "No comments"),
                        trailing: Text(
                          "${review["stars"]} ★",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
