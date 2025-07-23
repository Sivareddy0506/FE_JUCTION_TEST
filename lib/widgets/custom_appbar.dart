import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.asset('assets/back.png', width: 24, height: 24),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF262626),
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: const Color(0xFFE3E3E3),
          height: 1,
        ),
      ),
      foregroundColor: const Color(0xFF262626),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
