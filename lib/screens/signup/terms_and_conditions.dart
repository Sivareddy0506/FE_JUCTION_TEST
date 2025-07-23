import 'package:flutter/material.dart';
import '../../widgets/headding_description.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';
import './welcome_page.dart'; 


class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  bool isChecked = false;

  void _onSubmit() {
   Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const WelcomePage()),
);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: CustomAppBar(
        showBackButton: true,
        logoAssets: [
          'assets/logo-a.png',
          'assets/logo-b.png',
          'assets/logo-c.png',
          'assets/logo-d.png',
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeadingWithDescription(
              heading: 'Terms & Conditions',
              description:
                  "You're almost done! Please take a moment to review the Terms & Conditions before proceeding.",
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle("1. Eligibility"),
                    _BulletText("Must be a currently enrolled student at a recognized educational institution."),
                    _BulletText("Must be at least 18 years old or have consent from a parent/legal guardian."),
                    SizedBox(height: 16),
                    _SectionTitle("2. Account Registration"),
                    _BulletText("Agree to provide accurate and complete info."),
                    _BulletText("Responsible for your own credentials."),
                    _BulletText("Cannot share your credentials."),
                    _BulletText("No fake accounts."),
                    SizedBox(height: 16),
                    _SectionTitle("3. Use of Platform"),
                    _BulletText("Platform is for student-exclusive marketplace use."),
                    _BulletText("No misuse, fraud, or illegal activity."),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: isChecked,
                  activeColor: Colors.orange,
                  onChanged: (val) {
                    setState(() {
                      isChecked = val ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    "I have read and agree to the Terms & Conditions",
                    style: TextStyle(fontSize: 12, color: Color(0xFF212121)),
                  ),
                ),
              ],
            ),
            AppButton(
              bottomSpacing: 30,
              label: 'Done',
              onPressed: isChecked ? _onSubmit : null,
              backgroundColor: isChecked ? Colors.orange : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF212121),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;

  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 12, color: Color(0xFF212121)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF212121), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
