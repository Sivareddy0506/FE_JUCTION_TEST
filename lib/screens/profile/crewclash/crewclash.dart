import 'package:flutter/material.dart';
import '../../../widgets/custom_appbar.dart';

class CrewClashPage extends StatelessWidget {
  const CrewClashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(title: "Crew Clash"),
      body: Center(child: Text("Crew Clash Page")),
    );
  }
}
