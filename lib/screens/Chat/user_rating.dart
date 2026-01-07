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

  const ReviewScreen({
    super.key,
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
  int characterCount = 0;
  static const int maxCharacters = 200;

  @override
  void initState() {
    super.initState();
    vibeController.addListener(() {
      setState(() {
        characterCount = vibeController.text.length;
      });
    });
  }

  @override
  void dispose() {
    vibeController.dispose();
    super.dispose();
  }

  Widget buildStarRating() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            'GIVE A STAR RATING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    stars = index + 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.star,
                    color: index < stars ? const Color(0xFFFBBF24) : Colors.grey.shade300,
                    size: 36,
                    shadows: index < stars
                        ? [const Shadow(color: Colors.black12, blurRadius: 2)]
                        : [],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget buildRadioQuestion(
    String question,
    List<String> options,
    String? groupValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF1F2937),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        ...options.map((option) => _buildCustomRadioTile(option, groupValue, onChanged)),
      ],
    );
  }

  Widget _buildCustomRadioTile(
    String value,
    String? groupValue,
    Function(String?) onChanged,
  ) {
    final isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF111827) : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 10 : 0,
                    height: isSelected ? 10 : 0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> submitRating() async {
    if (stars == 0) {
      ErrorHandler.showErrorSnackBar(
        context,
        null,
        customMessage: "Please select a star rating",
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken');

      String comments = vibeController.text.trim();

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
        Navigator.pop(context);
      } else {
        ErrorHandler.showErrorSnackBar(context, null, response: response);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String heading = widget.fromProductSold ? "Rate the Buyer" : "Rate the Seller";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Review",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Skip",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading
                Text(
                  heading,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),

                // Star Rating Card
                buildStarRating(),
                const SizedBox(height: 32),

                // Question 1
                buildRadioQuestion(
                  "1. Did they communicate quickly?",
                  ["Yes", "No", "Somewhat"],
                  q1,
                  (val) => setState(() => q1 = val),
                ),
                const SizedBox(height: 32),

                // Question 2
                buildRadioQuestion(
                  "2. Did they show up / complete the deal reliably?",
                  ["Yes", "No"],
                  q2,
                  (val) => setState(() => q2 = val),
                ),
                const SizedBox(height: 32),

                // Question 3
                buildRadioQuestion(
                  "3. Would you trade with them again?",
                  ["Definitely", "No", "Maybe"],
                  q3,
                  (val) => setState(() => q3 = val),
                ),
                const SizedBox(height: 32),

                // Overall vibe textarea
                const Text(
                  "4. Overall vibe?",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    TextField(
                      controller: vibeController,
                      maxLength: maxCharacters,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Share details about general behavior, punctuality, or item condition...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF111827), width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        counterText: '', // Hide default counter
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Text(
                        '$characterCount/$maxCharacters',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Fixed bottom button with gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.8),
                    Colors.white,
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: AppButton(
                label: isLoading ? '' : 'Submit Review',
                onPressed: isLoading ? null : submitRating,
                backgroundColor: const Color(0xFFF97316),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

