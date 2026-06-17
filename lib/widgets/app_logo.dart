import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final bool showImage;
  final double imageSize;

  const AppLogo({
    super.key,
    this.fontSize = 18,
    this.showImage = false,
    this.imageSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (showImage) {
      // Use the actual logo image
      return Image.asset(
        'assets/images/logo.png',
        height: imageSize,
        width: imageSize,
        fit: BoxFit.contain,
      );
    }

    // Default: text-based logo
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: fontSize + 4,
          width: fontSize + 4,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Shubh',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  fontFamily: 'Roboto',
                ),
              ),
              TextSpan(
                text: 'labh',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
