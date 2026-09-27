import 'package:flutter/material.dart';

/// Spacing scale (4pt base). Prefer these over raw doubles in UI.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii aligned to Material 3 Expressive mock shapes.
abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));

  /// Asymmetric “expressive” hero: large top-left / bottom-right.
  static const BorderRadius hero = BorderRadius.only(
    topLeft: Radius.circular(32),
    topRight: Radius.circular(16),
    bottomRight: Radius.circular(32),
    bottomLeft: Radius.circular(16),
  );
}

/// Component sizes from the UI mock (nav indicators, avatars, progress, FAB).
abstract final class AppSizes {
  static const double navIndicatorCompact = 28;
  static const double navIndicatorHorizontal = 36;
  static const double navIndicatorRail = 48;
  static const double navIndicatorCompactWidth = 56;
  static const double avatar = 44;
  static const double progressBarHeight = 12;
  static const double iconButton = 40;
  static const double minTapTarget = 48;
  static const double progressStroke = 2;
  static const double buttonProgress = 20;
}

/// Common edge insets for pages and sections.
abstract final class AppInsets {
  static const EdgeInsets page = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets pageCompact = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets section = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.xs,
  );
  static const EdgeInsets sectionTight = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.xs,
  );
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.sm);
  static const EdgeInsets fabPadding = EdgeInsets.all(AppSpacing.md);
}

/// Motion durations for intentional, low-noise transitions.
abstract final class AppDurations {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration long = Duration(milliseconds: 400);
}

/// Semantic colors beyond [ColorScheme] (money polarity, soft surfaces).
@immutable
class AppExtraColors extends ThemeExtension<AppExtraColors> {
  const AppExtraColors({
    required this.income,
    required this.onIncome,
    required this.expense,
    required this.onExpense,
    required this.heroSurface,
    required this.onHeroSurface,
  });

  final Color income;
  final Color onIncome;
  final Color expense;
  final Color onExpense;
  final Color heroSurface;
  final Color onHeroSurface;

  static AppExtraColors light(ColorScheme scheme) => AppExtraColors(
    income: const Color(0xFF1B6B4A),
    onIncome: Colors.white,
    expense: const Color(0xFFB3261E),
    onExpense: Colors.white,
    heroSurface: Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.12),
      scheme.surfaceContainerHighest,
    ),
    onHeroSurface: scheme.onSurface,
  );

  static AppExtraColors dark(ColorScheme scheme) => AppExtraColors(
    income: const Color(0xFF7DCEA0),
    onIncome: const Color(0xFF003920),
    expense: const Color(0xFFFFB4AB),
    onExpense: const Color(0xFF690005),
    heroSurface: Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.18),
      scheme.surfaceContainerHighest,
    ),
    onHeroSurface: scheme.onSurface,
  );

  static AppExtraColors of(BuildContext context) =>
      Theme.of(context).extension<AppExtraColors>()!;

  @override
  AppExtraColors copyWith({
    Color? income,
    Color? onIncome,
    Color? expense,
    Color? onExpense,
    Color? heroSurface,
    Color? onHeroSurface,
  }) {
    return AppExtraColors(
      income: income ?? this.income,
      onIncome: onIncome ?? this.onIncome,
      expense: expense ?? this.expense,
      onExpense: onExpense ?? this.onExpense,
      heroSurface: heroSurface ?? this.heroSurface,
      onHeroSurface: onHeroSurface ?? this.onHeroSurface,
    );
  }

  @override
  AppExtraColors lerp(ThemeExtension<AppExtraColors>? other, double t) {
    if (other is! AppExtraColors) return this;
    return AppExtraColors(
      income: Color.lerp(income, other.income, t)!,
      onIncome: Color.lerp(onIncome, other.onIncome, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      onExpense: Color.lerp(onExpense, other.onExpense, t)!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      onHeroSurface: Color.lerp(onHeroSurface, other.onHeroSurface, t)!,
    );
  }
}
