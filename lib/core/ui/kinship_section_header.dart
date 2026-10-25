import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Section title row with optional trailing action link.
class KinshipSectionHeader extends StatelessWidget {
  const KinshipSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.action,
    this.padding,
  });

  final String title;

  /// Text action (e.g. "Gestisci", "Tutte"); ignored if [action] is set.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Custom trailing widget (overrides [actionLabel]).
  final Widget? action;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget? trailing = action;
    if (trailing == null && actionLabel != null) {
      trailing = TextButton(
        onPressed: onAction,
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          actionLabel!,
          style: textTheme.labelLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
