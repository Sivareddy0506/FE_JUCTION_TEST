import 'package:flutter/material.dart';
import '../../../widgets/custom_appbar.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(title: "Contact Support"),
      body: Center(child: Text("Contact Support Page")),
    );
  }
}
