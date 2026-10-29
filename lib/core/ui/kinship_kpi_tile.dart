import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'kinship_card.dart';

/// Compact financial KPI card (dashboard web / summary strips).
///
/// Sizes to its content (no Expanded/Spacer) so it can sit in a [Wrap] or
/// unbounded-height parent without RenderFlex overflow.
class KinshipKpiTile extends StatelessWidget {
  const KinshipKpiTile({
    super.key,
    required this.label,
    required this.amountText,
    this.icon,
    this.iconBackground,
    this.iconColor,
    this.amountColor,
    this.trend,
    this.footer,
    this.onTap,
    this.padding,
  });

  /// Uppercase-ish metric caption.
  final String label;

  /// Pre-formatted tabular amount.
  final String amountText;

  final IconData? icon;
  final Color? iconBackground;
  final Color? iconColor;
  final Color? amountColor;

  /// Optional trend row under the amount.
  final Widget? trend;

  /// Optional footer (member breakdown, etc.).
  final Widget? footer;

  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final amountStyle = footer != null
        ? AppTextStyles.tabularAmountMd(context)
        : AppTextStyles.tabularAmountLg(context);

    return KinshipCard(
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (icon != null)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        iconBackground ??
                        scheme.primaryFixed.withValues(alpha: 0.3),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: iconColor ?? scheme.primaryContainer,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            amountText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: amountStyle?.copyWith(
              color: amountColor ?? scheme.onSurface,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            trend!,
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.sm),
            footer!,
          ],
        ],
      ),
    );
  }
}
