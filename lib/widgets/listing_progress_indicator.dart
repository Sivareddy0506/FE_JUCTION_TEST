import 'package:flutter/material.dart';
import '../app_state.dart';

/// Reusable progress indicator for listing flow
/// Shows 5 progress bars, with [currentStep] bars filled (1-5)
class ListingProgressIndicator extends StatelessWidget {
  final int currentStep; // 1-5

  const ListingProgressIndicator({
    super.key,
    required this.currentStep,
  }) : assert(currentStep >= 1 && currentStep <= 5, 'currentStep must be between 1 and 5');

  @override
  Widget build(BuildContext context) {
    final activeColor = AppState.instance.isJuction
        ? const Color(0xFFC105FF)
        : const Color(0xFFFF6705);
    final inactiveColor = const Color(0xFFE9E9E9);

    return Row(
      children: List.generate(
        5,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            decoration: BoxDecoration(
              color: index < currentStep ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
