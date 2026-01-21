import 'package:flutter/material.dart';
import '../constants/ui_spacing.dart';
import 'app_button.dart';

/// Reusable bottom button layout component for signup/onboarding flows.
/// 
/// Handles keyboard-aware spacing, optional container styling, and flexible
/// content above/below the button while maintaining consistent design.
/// 
/// When [useContainer] is true, the container handles bottom spacing automatically,
/// so set [buttonBottomSpacing] to 0. When [useContainer] is false, you can
/// use [buttonBottomSpacing] to apply spacing to the button itself.
class BottomButtonLayout extends StatelessWidget {
  /// The main button widget (typically AppButton)
  /// Note: If using [useContainer], set AppButton's bottomSpacing to 0
  /// to avoid double spacing
  final Widget button;

  /// Optional content to display above the button (e.g., links, PrivacyPolicyLink)
  final Widget? contentAboveButton;

  /// Optional secondary button/widget below the main button (e.g., "Skip" button)
  final Widget? secondaryButton;

  /// Optional help text displayed below the button
  final String? helpText;

  /// Whether to use a white container background (default: false)
  /// When true, applies white background and keyboard-aware bottom padding
  final bool useContainer;

  /// Whether to show border and shadow on container (default: false)
  /// Only applies when useContainer is true
  final bool showContainerBorder;

  /// Custom bottom padding (default: uses keyboard-aware spacing)
  final double? customBottomPadding;

  /// Horizontal padding for the content (default: 24)
  final double horizontalPadding;

  /// Top padding for the content area (default: 16 for container, 0 otherwise)
  final double? topPadding;

  const BottomButtonLayout({
    super.key,
    required this.button,
    this.contentAboveButton,
    this.secondaryButton,
    this.helpText,
    this.useContainer = false,
    this.showContainerBorder = false,
    this.customBottomPadding,
    this.horizontalPadding = 24,
    this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    // Get keyboard height for keyboard-aware spacing
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    
    // Determine bottom padding based on options
    final double effectiveBottomPadding = customBottomPadding ??
        (useContainer
            ? (viewInsets > 0 ? viewInsets + 16 : kSignupFlowButtonBottomSpacing)
            : 0); // When not using container, button handles its own spacing

    // Determine top padding
    final double effectiveTopPadding = topPadding ?? (useContainer ? 16 : 0);

    // Build the content
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (contentAboveButton != null) ...[
          contentAboveButton!,
          const SizedBox(height: 12),
        ],
        button,
        if (secondaryButton != null) ...[
          const SizedBox(height: 12),
          secondaryButton!,
        ],
        if (helpText != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              helpText!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );

    // Apply padding
    content = Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: effectiveTopPadding,
        bottom: effectiveBottomPadding,
      ),
      child: content,
    );

    // Wrap in container if needed
    if (useContainer) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: showContainerBorder
              ? Border(
                  top: BorderSide(color: Colors.grey[200]!),
                )
              : null,
          boxShadow: showContainerBorder
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ]
              : null,
        ),
        child: content,
      );
    }

    return content;
  }
}
