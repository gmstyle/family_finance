import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Expressive capsule budget progress meter (12px track).
///
/// Fill colors:
/// - under 80%: [ColorScheme.primaryContainer]
/// - ≥ 80% and ≤ 100%: amber ([AppPalette.amber] / pending)
/// - over 100%: terracotta ([AppPalette.terracotta])
class KinshipBudgetMeter extends StatelessWidget {
  const KinshipBudgetMeter({
    super.key,
    required this.progress,
    this.height = AppSizes.progressBarHeight,
    this.trackColor,
    this.duration = AppDurations.medium,
  });

  /// Spent / limit ratio. Values above 1.0 show overdrawn (clamped visually to 1).
  final double progress;

  final double height;
  final Color? trackColor;
  final Duration duration;

  /// Amber warning threshold (DESIGN.md).
  static const double warningThreshold = 0.8;

  Color _fillColor(BuildContext context) {
    final extras = AppExtraColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (progress > 1.0) return AppPalette.terracotta;
    if (progress >= warningThreshold) return extras.pending;
    return scheme.primaryContainer;
  }

  @override
  Widget build(BuildContext context) {
    final extras = AppExtraColors.of(context);
    final clamped = progress.isNaN || progress.isInfinite
        ? 0.0
        : progress.clamp(0.0, 1.0);
    final fill = _fillColor(context);

    return Semantics(
      label: 'Budget progress ${(progress * 100).round()} percent',
      child: ClipRRect(
        borderRadius: AppRadius.fullAll,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: trackColor ?? extras.meterTrack),
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  widthFactor: clamped,
                  heightFactor: 1,
                  alignment: Alignment.centerLeft,
                  child: ColoredBox(color: fill),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
