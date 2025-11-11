import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/app_button.dart';
import './signup/signup_page.dart';
import '../app.dart'; // For SlidePageRoute

class AppOverviewScreen extends StatelessWidget {
  const AppOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: false,
        logoAssets: [
          'assets/logo-a.png',
          'assets/logo-b.png',
          'assets/logo-c.png',
          'assets/logo-d.png',
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Secure Your Spot,\nGet Verified in Minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Step indicator section using Stack for proper line alignment
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                       Padding(
                          padding: const EdgeInsets.only(left: 15, top: 15),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              // Vertical line
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                              // Step bubbles
                              Column(
                                children: [
                                  _buildStepNumber('1'),
                                  const SizedBox(height: 49),
                                  _buildStepNumber('2'),
                                  const SizedBox(height: 49),
                                  _buildStepNumber('3'),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Step descriptions
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStepDescription(
                                title: 'Enter College Email',
                                subtitle:
                                    'Sign up with your official college email\n(e.g, yourname@college.edu).',
                              ),
                              const SizedBox(height: 31),
                              _buildStepDescription(
                                title: 'Confirm Your Identity',
                                subtitle:
                                    'Receive a verification OTP in your inbox\nand add other details.',
                              ),
                              const SizedBox(height: 31),
                              _buildStepDescription(
                                title: 'Start Buying & Selling',
                                subtitle:
                                    'Once verified, explore listings, post items,\nand connect with students.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // CTA Button
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppButton(
              label: 'Get Started',
              backgroundColor: Colors.black,
              bottomSpacing: 24,
              onPressed: () async{
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isFirstTime', false);
                Navigator.push(
                  context,
                  SlidePageRoute(page: const SignupPage()),
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepNumber(String number) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6705),
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildStepDescription({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF323537),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
