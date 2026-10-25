import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Single Kinship filter / category chip (32px pill).
class KinshipFilterChip extends StatelessWidget {
  const KinshipFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.leading,
    this.showCheckWhenSelected = true,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? leading;

  /// When selected, prepends a micro-check (DESIGN.md).
  final bool showCheckWhenSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extras = AppExtraColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    final bg = selected ? scheme.primaryContainer : extras.inputContainer;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;

    return Material(
      color: bg,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelected == null ? null : () => onSelected!(!selected),
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.chipHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected && showCheckWhenSelected) ...[
                  Icon(Icons.check, size: 14, color: fg),
                  const SizedBox(width: AppSpacing.xxs),
                ] else if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(color: fg, size: 14),
                    child: leading!,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                ],
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrolling row of [KinshipFilterChip]s.
class KinshipFilterChips extends StatelessWidget {
  const KinshipFilterChips({
    super.key,
    required this.children,
    this.padding,
    this.spacing = AppSpacing.xs,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  /// Convenience builder from string labels + selected index / set.
  factory KinshipFilterChips.labels({
    Key? key,
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    EdgeInsetsGeometry? padding,
    double spacing = AppSpacing.xs,
  }) {
    return KinshipFilterChips(
      key: key,
      padding: padding,
      spacing: spacing,
      children: [
        for (var i = 0; i < labels.length; i++)
          KinshipFilterChip(
            label: labels[i],
            selected: i == selectedIndex,
            onSelected: (_) => onSelected(i),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            children[i],
          ],
        ],
      ),
    );
  }
}
