import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double bottomSpacing;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.bottomSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing), // Removed left/right
      child: SizedBox(
        width: double.infinity, // 100% width
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? const Color(0xFF262626),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
