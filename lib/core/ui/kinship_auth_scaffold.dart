import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_tokens.dart';
import 'kinship_card.dart';

/// Max width for the auth form column (plan ~440px).
const double kKinshipAuthFormMaxWidth = 440;

/// L0 surface canvas for auth / onboarding routes.
///
/// - Compact: stacked body with [AppSpacing.margin] (16).
/// - Wide: centered column (~440) **or** brand + form split when [brandPanel]
///   is provided.
class KinshipAuthScaffold extends StatelessWidget {
  const KinshipAuthScaffold({
    super.key,
    required this.body,
    this.brandPanel,
    this.safeArea = true,
    this.backgroundColor,
    this.splitBreakpoint = AppBreakpoints.medium,
  });

  /// Typically a [KinshipAuthPanel] or a scrollable form column.
  final Widget body;

  /// Optional left brand fascia for wide split layouts (primaryContainer).
  final Widget? brandPanel;

  final bool safeArea;
  final Color? backgroundColor;

  /// Width at which split / centered wide layout engages.
  final double splitBreakpoint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= splitBreakpoint;

    Widget content;
    if (wide && brandPanel != null) {
      content = Row(
        children: [
          Expanded(child: brandPanel!),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: kKinshipAuthFormMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (wide) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kKinshipAuthFormMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: body,
          ),
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.all(AppSpacing.margin),
        child: body,
      );
    }

    if (safeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? scheme.surface,
      body: content,
    );
  }
}

/// L1 card panel for auth forms: logo, headline, reassuring body, then [child].
class KinshipAuthPanel extends StatelessWidget {
  const KinshipAuthPanel({
    super.key,
    required this.child,
    this.logo,
    this.brandName = 'Family Finance',
    this.headline,
    this.body,
    this.footer,
    this.padding,
    this.showCard = true,
  });

  final Widget child;

  /// Optional logo mark above the brand name.
  final Widget? logo;

  final String brandName;
  final String? headline;
  final String? body;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;

  /// When false, renders content without the L1 card chrome (for split layouts).
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (logo != null) ...[
          Align(alignment: Alignment.centerLeft, child: logo!),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          brandName,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        if (headline != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            headline!,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (body != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            body!,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        child,
        if (footer != null) ...[const SizedBox(height: AppSpacing.md), footer!],
      ],
    );

    final padded = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: content,
    );

    if (!showCard) return padded;

    return KinshipCard(child: padded);
  }
}

/// Ready-made brand fascia for [KinshipAuthScaffold.brandPanel] (wide split).
class KinshipAuthBrandPanel extends StatelessWidget {
  const KinshipAuthBrandPanel({
    super.key,
    this.title = 'Family Finance',
    this.subtitle,
    this.logo,
  });

  final String title;
  final String? subtitle;
  final Widget? logo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final extras = AppExtraColors.of(context);

    return ColoredBox(
      color: extras.heroSurface,
      child: Stack(
        children: [
          Positioned(
            right: -48,
            bottom: -64,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.35),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (logo != null) ...[
                  logo!,
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(
                  title,
                  style: textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: extras.onHeroSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
