import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<String> logoAssets;

  const CustomAppBar({
    super.key,
    this.showBackButton = true,
    this.onBackPressed,
    required this.logoAssets,
  });

  @override
  Size get preferredSize => const Size.fromHeight(108); // 48 + 40 padding from top

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 40), // top padding of 40
      child: SizedBox(
        height: 108, // height of the inner row with icons/logos remains 48
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                const SizedBox(width: 10),
                if (showBackButton)
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: Image.asset('assets/back.png', width: 24),
                    onPressed: onBackPressed ?? () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: logoAssets
                  .map((asset) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Image.asset(asset, height: 30), // logos 30px height
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
