import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Numeric count badge (nav / inbox).
///
/// Standalone when [child] is null; otherwise overlays the badge at top-right.
class KinshipBadgeCount extends StatelessWidget {
  const KinshipBadgeCount({
    super.key,
    required this.count,
    this.child,
    this.maxCount = 99,
    this.backgroundColor,
    this.foregroundColor,
    this.showZero = false,
    this.top = -2,
    this.right = -4,
  });

  /// Count to display. Hidden when ≤ 0 unless [showZero].
  final int count;

  /// When set, wraps [child] and overlays the badge at top-right.
  final Widget? child;

  final int maxCount;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showZero;

  /// Overlay offsets when wrapping [child].
  final double top;
  final double right;

  bool get _visible => count > 0 || (showZero && count == 0);

  String get _label {
    if (count > maxCount) return '$maxCount+';
    return '$count';
  }

  Widget _badge(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bg = backgroundColor ?? scheme.tertiaryContainer;
    final fg = foregroundColor ?? scheme.onTertiaryContainer;

    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.fullAll),
      alignment: Alignment.center,
      child: Text(
        _label,
        style: textTheme.labelSmall?.copyWith(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return child ?? const SizedBox.shrink();
    }

    final badge = _badge(context);
    if (child == null) return badge;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        Positioned(top: top, right: right, child: badge),
      ],
    );
  }
}
