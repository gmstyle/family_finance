import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Asymmetric primaryContainer hero for family balance totals.
///
/// Corner radii: TL 32 / TR 12 / BR 32 / BL 32 ([AppRadius.hero]).
class KinshipHeroBalance extends StatelessWidget {
  const KinshipHeroBalance({
    super.key,
    required this.label,
    required this.amountText,
    this.leading,
    this.trailing,
    this.subtitle,
    this.footer,
    this.padding,
    this.onTap,
  });

  /// Uppercase-ish caption (e.g. "Saldo Totale Famiglia").
  final String label;

  /// Pre-formatted tabular amount (screen owns locale / Money formatting).
  final String amountText;

  /// Optional icon beside [label] (defaults to wallet icon).
  final Widget? leading;

  /// Optional action (e.g. visibility toggle).
  final Widget? trailing;

  /// Optional pill / trend under the amount (e.g. net savings).
  final Widget? subtitle;

  /// Optional bottom row (e.g. income / expense mini metrics).
  final Widget? footer;

  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final extras = AppExtraColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTheme(
                data: IconThemeData(color: extras.onHeroSurface, size: 20),
                child:
                    leading ??
                    const Icon(Icons.account_balance_wallet_outlined),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: extras.onHeroSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            amountText,
            style: AppTextStyles.tabularAmountLg(context)
                ?.copyWith(color: scheme.onPrimary),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: Alignment.centerLeft, child: subtitle!),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    );

    return Material(
      color: extras.heroSurface,
      borderRadius: AppRadius.hero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.hero,
        child: Stack(
          children: [
            Positioned(
              right: -40,
              bottom: -48,
              child: IgnorePointer(
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -56,
              right: 64,
              child: IgnorePointer(
                child: Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primaryFixedDim.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}
