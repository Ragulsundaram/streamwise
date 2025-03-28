import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../constants/colors.dart';

class AppLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Color? color;

  const AppLogo({
    super.key,
    this.iconSize = 40,
    this.fontSize = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppColors.primary;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Iconsax.video_play,
          size: iconSize,
          color: logoColor,
        ),
        const SizedBox(width: 10),
        Text(
          'StreamWise',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: logoColor,
          ),
        ),
      ],
    );
  }
}