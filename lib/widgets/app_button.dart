import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double bottomSpacing;
  final IconData? icon;
  final Widget? customChild; // For custom content like loading indicators
  final double? height;
  final bool expand;
  final EdgeInsetsGeometry? contentPadding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.bottomSpacing = 0,
    this.icon,
    this.customChild,
    this.height,
    this.expand = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    // If we have a border and white background, use OutlinedButton for better styling
    final bool useOutlined = borderColor != null && backgroundColor == Colors.white;

    final EdgeInsetsGeometry effectivePadding = contentPadding ?? EdgeInsets.zero;
    final double effectiveHeight = height ?? 56;

    Widget buttonChild;

    if (useOutlined) {
      buttonChild = OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: borderColor!, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: effectivePadding,
        ),
        child: Center(
          child: customChild ?? (icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: textColor ?? const Color(0xFF262626), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        color: textColor ?? const Color(0xFF262626),
                      ),
                    ),
                  ],
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    color: textColor ?? const Color(0xFF262626),
                  ),
                )),
        ),
      );
    } else {
      buttonChild = ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFF262626),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderColor != null
                ? BorderSide(color: borderColor!, width: 1)
                : BorderSide.none,
          ),
          padding: effectivePadding,
        ),
        child: Center(
          child: customChild ?? (icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: textColor ?? Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        color: textColor ?? Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    color: textColor ?? Colors.white,
                  ),
                )),
        ),
      );
    }

    final Widget buttonWidget = SizedBox(
      height: effectiveHeight,
      child: buttonChild,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: expand
          ? SizedBox(
              width: double.infinity,
              child: buttonWidget,
            )
          : buttonWidget,
    );
  }
}
