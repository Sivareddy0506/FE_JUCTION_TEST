import 'package:flutter/material.dart';

class AppThemes {
static final lightTheme = ThemeData(
primaryColor: const Color(0xFF262626),
fontFamily: 'Manrope',
scaffoldBackgroundColor: Colors.white,
colorScheme: ColorScheme.fromSwatch().copyWith(
primary: const Color(0xFF262626),
),
textTheme: const TextTheme(
bodyMedium: TextStyle(color: Colors.black),
),
);
}