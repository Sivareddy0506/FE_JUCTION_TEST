import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewScreen extends StatefulWidget {
  final String ratedUserId;
  final String ratedById;
  final bool fromProductSold; // true => rate buyer, false => rate seller

  ReviewScreen({
    required this.ratedUserId,
    required this.ratedById,
    this.fromProductSold = false,
  });

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String? q1, q2, q3;
  int stars = 0;
  final TextEditingController vibeController = TextEditingController();
  bool isLoading = false;

  Widget buildRadioQuestion(
      String question, List<String> options, String? groupValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        ...options.map((option) => RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: groupValue,
              onChanged: onChanged,
            )),
        SizedBox(height: 12),
      ],
    );
  }

  Widget buildStarRating() {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            Icons.star,
            color: index < stars ? Colors.deepOrange : Colors.grey.shade400,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              stars = index + 1;
            });
          },
        );
      }),
    );
  }

  Future<void> submitRating() async {
    if (stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a star rating")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    final response = await http.post(
        Uri.parse('https://api.junctionverse.com/ratings/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          "ratedUserId": widget.ratedUserId,
          "ratedById": widget.ratedById,
          "communication": q1,
          "reliability": q2,
          "tradeAgain": q3,
          "overallVibe": vibeController.text,
          "comments": vibeController.text,
          "stars": stars,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rating submitted successfully")),
        );
        Navigator.pop(context); // go back after success
      } else {
        final err = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${err["error"] ?? "Failed"}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String heading = widget.fromProductSold ? "Rate the Buyer" : "Rate the Seller";

    return Scaffold(
      appBar: AppBar(
        title: Text("Review"),
        actions: [
          TextButton(onPressed: () {}, child: Text("Skip", style: TextStyle(color: Colors.black)))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              SizedBox(height: 16),

              // Star Rating
              Text("Give a star rating", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              buildStarRating(),
              SizedBox(height: 16),

              buildRadioQuestion(
                "1. Did they communicate quickly?",
                ["Yes", "No", "Somewhat"],
                q1,
                (val) => setState(() => q1 = val),
              ),

              buildRadioQuestion(
                "2. Did they show up / complete the deal reliably?",
                ["Yes", "No", "Almost"],
                q2,
                (val) => setState(() => q2 = val),
              ),

              buildRadioQuestion(
                "3. Would you trade with them again?",
                ["Definitely", "No", "Maybe"],
                q3,
                (val) => setState(() => q3 = val),
              ),

              Text("4. Overall vibe?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              TextField(
                controller: vibeController,
                decoration: InputDecoration(
                  hintText: "General behaviour",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange, padding: EdgeInsets.all(16)),
                  onPressed: isLoading ? null : submitRating,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Submit"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
