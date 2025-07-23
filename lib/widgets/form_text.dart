import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final bool isMandatory;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final String? prefixText;

  const AppTextField({
    super.key,
    required this.label,
    required this.placeholder,
    this.isMandatory = false,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.onChanged,
    this.maxLines = 1,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
        color: Color(0xFF212121),
      ),
      decoration: InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelText: isMandatory ? '* $label' : label,
        labelStyle: const TextStyle(
          fontSize: 12,
          height: 14 / 12,
          color: Color(0xFF212121),
        ),
        hintText: placeholder,
        hintStyle: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Color(0xFF8A8894),
        ),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFF212121),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF212121), width: 1),
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF212121), width: 1),
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF212121), width: 1),
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}
