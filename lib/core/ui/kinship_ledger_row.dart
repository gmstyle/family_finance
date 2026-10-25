import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Compact transaction / ledger list row.
///
/// Leading rounded-square icon, two-line title + attribution/timestamp,
/// trailing tabular amount (income uses teal + optional leading `+`).
class KinshipLedgerRow extends StatelessWidget {
  const KinshipLedgerRow({
    super.key,
    required this.title,
    required this.amountText,
    this.isIncome = false,
    this.leading,
    this.leadingIcon,
    this.leadingBackground,
    this.leadingForeground,
    this.attribution,
    this.timestamp,
    this.categoryLabel,
    this.alertBadge,
    this.onTap,
    this.padding,
  });

  final String title;

  /// Pre-formatted amount (include sign if desired; income tint applied).
  final String amountText;

  /// When true, amount uses income (teal) color.
  final bool isIncome;

  /// Custom leading widget; overrides [leadingIcon].
  final Widget? leading;

  final IconData? leadingIcon;
  final Color? leadingBackground;
  final Color? leadingForeground;

  /// Member attribution pill text (e.g. "Elena").
  final String? attribution;

  /// Timestamp / secondary meta (e.g. "Oggi, 14:30").
  final String? timestamp;

  /// Trailing secondary label under amount (e.g. category).
  final String? categoryLabel;

  /// Optional terracotta threshold badge beside the amount.
  final Widget? alertBadge;

  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extras = AppExtraColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    final amountStyle = AppTextStyles.tabularAmountMd(context)
        ?.copyWith(color: isIncome ? extras.income : scheme.onSurface);

    final iconBg =
        leadingBackground ??
        (isIncome
            ? scheme.primaryFixed
            : scheme.primaryFixed.withValues(alpha: 0.4));
    final iconFg =
        leadingForeground ??
        (isIncome ? scheme.onPrimaryFixed : scheme.primary);

    final leadingWidget =
        leading ??
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(
            leadingIcon ??
                (isIncome
                    ? Icons.payments_outlined
                    : Icons.storefront_outlined),
            size: 20,
            color: iconFg,
          ),
        );

    final metaChildren = <Widget>[];
    if (attribution != null && attribution!.isNotEmpty) {
      metaChildren.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: scheme.secondaryFixed,
            borderRadius: AppRadius.fullAll,
          ),
          child: Text(
            attribution!,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryFixed,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      );
    }
    if (timestamp != null && timestamp!.isNotEmpty) {
      if (metaChildren.isNotEmpty) {
        metaChildren.add(
          Text(
            '•',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        );
      }
      metaChildren.add(
        Flexible(
          child: Text(
            timestamp!,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final row = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          leadingWidget,
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (metaChildren.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      for (var i = 0; i < metaChildren.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        metaChildren[i],
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (alertBadge != null) ...[
                    alertBadge!,
                    const SizedBox(width: AppSpacing.xxs),
                  ],
                  Text(amountText, style: amountStyle),
                ],
              ),
              if (categoryLabel != null && categoryLabel!.isNotEmpty)
                Text(
                  categoryLabel!,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, borderRadius: AppRadius.mdAll, child: row),
    );
  }
}
