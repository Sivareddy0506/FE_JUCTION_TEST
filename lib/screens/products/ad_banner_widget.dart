import 'package:flutter/material.dart';

class AdBannerWidget extends StatelessWidget {
  final String mediaUrl;
  final String fallbackUrl;

  const AdBannerWidget({
    super.key,
    required this.mediaUrl,
    this.fallbackUrl = 'https://products-junction.s3.us-east-1.amazonaws.com/uploads/1754634610919-0.jpg',
  });

  @override
  Widget build(BuildContext context) {
    print('🔎 Trying to load Ad Image: $mediaUrl');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          mediaUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ Failed to load ad image: $mediaUrl');
            return Image.network(
              fallbackUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: Text("Ad not loaded")),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
