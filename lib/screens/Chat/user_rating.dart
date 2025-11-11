import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/error_handler.dart';
import '../../widgets/app_button.dart';

class ReviewScreen extends StatefulWidget {
  final String ratedUserId;
  final String ratedById;
  final bool fromProductSold; // true => rate buyer, false => rate seller

  const ReviewScreen({super.key, 
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
            color: index < stars ? Color(0xFFFF6705) : Colors.grey.shade400,
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

    String comments = vibeController.text;
    if (comments.isEmpty) comments = "N/A";

    final response = await http.post(
      Uri.parse('https://api.junctionverse.com/ratings/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        "ratedUserId": widget.ratedUserId,
        "ratedById": widget.ratedById,
        "communication": q1 ?? "N/A",
        "reliability": q2 ?? "N/A",
        "tradeAgain": q3 ?? "N/A",
        "overallVibe": comments,
        "comments": comments,
        "stars": stars,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final msg = json.decode(response.body)["message"] ?? "Rating submitted";
      ErrorHandler.showSuccessSnackBar(context, msg);
      Navigator.pop(context); // go back after success
    } else {
      ErrorHandler.showErrorSnackBar(context, null, response: response);
    }
  } catch (e) {
    ErrorHandler.showErrorSnackBar(context, e);
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
          TextButton(onPressed: () {
            Navigator.pop(context);
          }, child: Text("Skip", style: TextStyle(color: Colors.black)))
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
                ["Yes", "No"],
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

              AppButton(
                label: isLoading ? 'Submitting...' : 'Submit',
                onPressed: isLoading ? null : submitRating,
                backgroundColor: const Color(0xFFFF6705),
                textColor: Colors.white,
                customChild: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : null,
              )
            ],
          ),
        ),
      ),
    );
  }
}
