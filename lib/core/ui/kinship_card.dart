import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// L1 Kinship surface tile (white + teal border + ambient shadow).
///
/// Use [elevated] for L2 floating sheets / interactive lift.
class KinshipCard extends StatelessWidget {
  const KinshipCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.onTap,
    this.elevated = false,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final bool elevated;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? AppRadius.cardAll;
    final bg = color ?? scheme.surfaceContainerLowest;

    final decoration = elevated
        ? BoxDecoration(
            color: bg,
            borderRadius: radius,
            boxShadow: AppElevation.level2Shadows(),
          )
        : AppElevation.level1Card(color: bg, borderRadius: radius);

    Widget content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: radius, child: content),
      );
    }

    return Container(
      margin: margin,
      decoration: decoration,
      clipBehavior: clipBehavior,
      child: content,
    );
  }
}
