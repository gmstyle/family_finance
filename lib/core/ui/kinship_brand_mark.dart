import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Official Family Finance mark (Stitch Opzione B).
class KinshipBrandMark extends StatelessWidget {
  const KinshipBrandMark({super.key, this.size = 40, this.borderRadius});

  static const assetPath = 'assets/branding/app_icon.png';

  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.mdAll;
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Family Finance',
      ),
    );
  }
}
