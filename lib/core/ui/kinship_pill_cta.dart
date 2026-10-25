import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Kinship pill CTA helpers (primary / secondary / destructive).
///
/// Prefer these over ad-hoc [FilledButton] styling so feature screens stay
/// aligned with DESIGN.md (48px min height, full pill, 24px horizontal pad).
abstract final class KinshipPillCta {
  KinshipPillCta._();

  static ButtonStyle _base(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(64, AppSizes.minTapTarget),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: WidgetStatePropertyAll(
        textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Solid primaryContainer fill + onPrimary text.
  static ButtonStyle primary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _base(context).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.pressed)) {
          return scheme.primary; // tint toward #083C35-ish / primary
        }
        return scheme.primaryContainer;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.onPrimary;
      }),
    );
  }

  /// Ghost / outlined teal pill.
  static ButtonStyle secondary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _base(context).copyWith(
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: WidgetStatePropertyAll(scheme.primaryContainer),
      side: WidgetStatePropertyAll(
        BorderSide(color: scheme.primaryContainer, width: 1.5),
      ),
    );
  }

  /// Terracotta spend / destructive pill.
  static ButtonStyle destructive(BuildContext context) {
    return _base(context).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppPalette.terracotta.withValues(alpha: 0.4);
        }
        return AppPalette.terracotta;
      }),
      foregroundColor: const WidgetStatePropertyAll(AppPalette.onPrimary),
    );
  }
}

/// Primary pill filled button.
class KinshipPrimaryPillButton extends StatelessWidget {
  const KinshipPrimaryPillButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final style = KinshipPillCta.primary(context);
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return FilledButton(onPressed: onPressed, style: style, child: child);
  }
}

/// Outlined / ghost pill button.
class KinshipSecondaryPillButton extends StatelessWidget {
  const KinshipSecondaryPillButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final style = KinshipPillCta.secondary(context);
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}

/// Terracotta destructive / spend-alert pill.
class KinshipDestructivePillButton extends StatelessWidget {
  const KinshipDestructivePillButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final style = KinshipPillCta.destructive(context);
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return FilledButton(onPressed: onPressed, style: style, child: child);
  }
}
