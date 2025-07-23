import 'package:flutter/material.dart';

class AppDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          height: 14 / 12,
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
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
