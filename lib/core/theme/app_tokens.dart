import 'package:flutter/material.dart';

/// Stitch Kinship spacing (4px base). Prefer these over raw doubles in UI.
///
/// DESIGN.md map: `space-xs`→[xxs], `space-sm`→[xs], `space-md`→[md],
/// `space-lg`→[lg], `space-xl`→[xl]. [sm] is a denser intermediate (12).
abstract final class AppSpacing {
  /// DESIGN `space-xs` (0.25rem).
  static const double xxs = 4;

  /// DESIGN `space-sm` (0.5rem).
  static const double xs = 8;

  /// Intermediate between sm and md (12) — common compact padding.
  static const double sm = 12;

  /// DESIGN `space-md` (1rem).
  static const double md = 16;

  /// DESIGN `space-lg` (1.5rem).
  static const double lg = 24;

  /// DESIGN `space-xl` (2rem).
  static const double xl = 32;

  /// Extra-large section gap.
  static const double xxl = 48;

  /// Page outer margin (mobile): DESIGN `margin` = 1rem.
  static const double margin = md;
}

/// Corner radii from Kinship DESIGN.md (`rounded.*`).
abstract final class AppRadius {
  /// 0.5rem.
  static const double sm = 8;

  /// 1rem — inputs / default soft corners.
  static const double md = 16;

  /// 1.5rem — cards & surface tiles.
  static const double lg = 24;

  /// Alias for card radius (DESIGN cards = 1.5rem).
  static const double card = lg;

  /// 2rem.
  static const double xl = 32;

  /// 3rem.
  static const double xxl = 48;

  /// Pill primitives (`rounded-full`).
  static const double full = 9999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));

  /// Asymmetric hero: TL 2rem, TR 0.75rem, BR/BL 2rem (DESIGN.md).
  static const BorderRadius hero = BorderRadius.only(
    topLeft: Radius.circular(32),
    topRight: Radius.circular(12),
    bottomRight: Radius.circular(32),
    bottomLeft: Radius.circular(32),
  );
}

/// Component sizes from Kinship DESIGN / shell chrome.
abstract final class AppSizes {
  static const double navIndicatorCompact = 28;
  static const double navIndicatorHorizontal = 36;
  static const double navIndicatorRail = 48;
  static const double navIndicatorCompactWidth = 56;
  static const double avatar = 44;
  static const double progressBarHeight = 12;
  static const double chipHeight = 32;
  static const double iconButton = 40;
  static const double minTapTarget = 48;
  static const double progressStroke = 2;
  static const double buttonProgress = 20;
  static const double sidebarWidth = 288;
}

/// Common edge insets for pages and sections.
abstract final class AppInsets {
  static const EdgeInsets page = EdgeInsets.all(AppSpacing.margin);
  static const EdgeInsets pageCompact = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets section = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.sm,
  );
  static const EdgeInsets sectionTight = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
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

/// Kinship tonal elevation: L1 card border + ambient shadows (DESIGN.md).
abstract final class AppElevation {
  /// Teal used for L1 border / ambient glow (`#0D5C52`).
  static const Color _teal = Color(0xFF0D5C52);

  /// Slate for L2 lift / L3 scrim (`#191C1B`).
  static const Color _slate = Color(0xFF191C1B);

  /// L1 ultra-subtle border: `1px solid rgba(13, 92, 82, 0.08)`.
  static BorderSide cardBorder({double opacity = 0.08}) =>
      BorderSide(color: _teal.withValues(alpha: opacity));

  static ShapeBorder cardShape({
    BorderRadius borderRadius = AppRadius.cardAll,
    double borderOpacity = 0.08,
  }) => RoundedRectangleBorder(
    borderRadius: borderRadius,
    side: cardBorder(opacity: borderOpacity),
  );

  /// L1 ambient glow: `0 4px 20px -2px rgba(13, 92, 82, 0.04)`.
  static List<BoxShadow> level1Shadows({double opacity = 0.04}) => [
    BoxShadow(
      color: _teal.withValues(alpha: opacity),
      offset: const Offset(0, 4),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];

  /// L2 floating: `0 12px 32px -4px rgba(25, 28, 27, 0.08)`.
  static List<BoxShadow> level2Shadows({double opacity = 0.08}) => [
    BoxShadow(
      color: _slate.withValues(alpha: opacity),
      offset: const Offset(0, 12),
      blurRadius: 32,
      spreadRadius: -4,
    ),
  ];

  /// L3 modal scrim: `rgba(25, 28, 27, 0.4)`.
  static Color scrim({double opacity = 0.4}) =>
      _slate.withValues(alpha: opacity);

  /// Convenience L1 decoration (white surface + border + ambient shadow).
  static BoxDecoration level1Card({
    Color color = Colors.white,
    BorderRadius borderRadius = AppRadius.cardAll,
  }) => BoxDecoration(
    color: color,
    borderRadius: borderRadius,
    border: Border.fromBorderSide(cardBorder()),
    boxShadow: level1Shadows(),
  );
}

/// Explicit Stitch / Kinship ColorScheme seed values (light-first).
abstract final class AppPalette {
  static const Color primary = Color(0xFF00433B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0D5C52);
  static const Color onPrimaryContainer = Color(0xFF8ED2C5);

  static const Color secondary = Color(0xFFAB3425);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFC6F5A);
  static const Color onSecondaryContainer = Color(0xFF6D0300);

  static const Color tertiary = Color(0xFF553300);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF744800);
  static const Color onTertiaryContainer = Color(0xFFFFB759);

  /// Semantic amber for pending / review (DESIGN prose `#F59E0B`).
  static const Color amber = Color(0xFFF59E0B);

  /// Soft coral used in DESIGN prose for spend alerts (`#E05A47`).
  static const Color terracotta = Color(0xFFE05A47);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color surface = Color(0xFFF8FAF7);
  static const Color onSurface = Color(0xFF191C1B);
  static const Color onSurfaceVariant = Color(0xFF3F4946);
  static const Color surfaceDim = Color(0xFFD9DAD8);
  static const Color surfaceBright = Color(0xFFF8FAF7);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F2);
  static const Color surfaceContainer = Color(0xFFEDEEEC);
  static const Color surfaceContainerHigh = Color(0xFFE7E9E6);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E1);

  /// Input / inactive chip fill (DESIGN `#F0F4F3`).
  static const Color inputContainer = Color(0xFFF0F4F3);

  /// Budget meter track (DESIGN `#E5ECE9`).
  static const Color meterTrack = Color(0xFFE5ECE9);

  static const Color outline = Color(0xFF6F7976);
  static const Color outlineVariant = Color(0xFFBEC9C5);
  static const Color inverseSurface = Color(0xFF2E3130);
  static const Color inverseOnSurface = Color(0xFFF0F1EF);
  static const Color inversePrimary = Color(0xFF8FD3C6);
  static const Color surfaceTint = Color(0xFF21695F);

  static const Color primaryFixed = Color(0xFFABF0E2);
  static const Color primaryFixedDim = Color(0xFF8FD3C6);
  static const Color onPrimaryFixed = Color(0xFF00201C);
  static const Color onPrimaryFixedVariant = Color(0xFF005047);
  static const Color secondaryFixed = Color(0xFFFFDAD4);
  static const Color secondaryFixedDim = Color(0xFFFFB4A8);
  static const Color onSecondaryFixed = Color(0xFF410100);
  static const Color onSecondaryFixedVariant = Color(0xFF8A1C10);
  static const Color tertiaryFixed = Color(0xFFFFDDB8);
  static const Color tertiaryFixedDim = Color(0xFFFFB95F);
  static const Color onTertiaryFixed = Color(0xFF2A1700);
  static const Color onTertiaryFixedVariant = Color(0xFF653E00);

  static ColorScheme lightScheme() => const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: inverseOnSurface,
    inversePrimary: inversePrimary,
    surfaceTint: surfaceTint,
    primaryFixed: primaryFixed,
    primaryFixedDim: primaryFixedDim,
    onPrimaryFixed: onPrimaryFixed,
    onPrimaryFixedVariant: onPrimaryFixedVariant,
    secondaryFixed: secondaryFixed,
    secondaryFixedDim: secondaryFixedDim,
    onSecondaryFixed: onSecondaryFixed,
    onSecondaryFixedVariant: onSecondaryFixedVariant,
    tertiaryFixed: tertiaryFixed,
    tertiaryFixedDim: tertiaryFixedDim,
    onTertiaryFixed: onTertiaryFixed,
    onTertiaryFixedVariant: onTertiaryFixedVariant,
  );

  /// Dark scheme derived from the same Kinship brand (Stitch is light-first).
  static ColorScheme darkScheme() => const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8FD3C6),
    onPrimary: Color(0xFF00382F),
    primaryContainer: Color(0xFF0D5C52),
    onPrimaryContainer: Color(0xFFABF0E2),
    secondary: Color(0xFFFFB4A8),
    onSecondary: Color(0xFF690005),
    secondaryContainer: Color(0xFF8A1C10),
    onSecondaryContainer: Color(0xFFFFDAD4),
    tertiary: Color(0xFFFFB95F),
    onTertiary: Color(0xFF462A00),
    tertiaryContainer: Color(0xFF744800),
    onTertiaryContainer: Color(0xFFFFDDB8),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF111413),
    onSurface: Color(0xFFE1E3E1),
    onSurfaceVariant: Color(0xFFBEC9C5),
    surfaceDim: Color(0xFF111413),
    surfaceBright: Color(0xFF373A39),
    surfaceContainerLowest: Color(0xFF0C0F0E),
    surfaceContainerLow: Color(0xFF191C1B),
    surfaceContainer: Color(0xFF1D201F),
    surfaceContainerHigh: Color(0xFF272A29),
    surfaceContainerHighest: Color(0xFF323534),
    outline: Color(0xFF899390),
    outlineVariant: Color(0xFF3F4946),
    inverseSurface: Color(0xFFE1E3E1),
    onInverseSurface: Color(0xFF2E3130),
    inversePrimary: Color(0xFF006B5F),
    surfaceTint: Color(0xFF8FD3C6),
    primaryFixed: primaryFixed,
    primaryFixedDim: primaryFixedDim,
    onPrimaryFixed: onPrimaryFixed,
    onPrimaryFixedVariant: onPrimaryFixedVariant,
    secondaryFixed: secondaryFixed,
    secondaryFixedDim: secondaryFixedDim,
    onSecondaryFixed: onSecondaryFixed,
    onSecondaryFixedVariant: onSecondaryFixedVariant,
    tertiaryFixed: tertiaryFixed,
    tertiaryFixedDim: tertiaryFixedDim,
    onTertiaryFixed: onTertiaryFixed,
    onTertiaryFixedVariant: onTertiaryFixedVariant,
  );
}

/// Semantic colors beyond [ColorScheme] (money polarity, pending, hero).
@immutable
class AppExtraColors extends ThemeExtension<AppExtraColors> {
  const AppExtraColors({
    required this.income,
    required this.onIncome,
    required this.expense,
    required this.onExpense,
    required this.pending,
    required this.onPending,
    required this.heroSurface,
    required this.onHeroSurface,
    required this.inputContainer,
    required this.meterTrack,
  });

  final Color income;
  final Color onIncome;
  final Color expense;
  final Color onExpense;
  final Color pending;
  final Color onPending;
  final Color heroSurface;
  final Color onHeroSurface;
  final Color inputContainer;
  final Color meterTrack;

  static AppExtraColors light(ColorScheme scheme) => AppExtraColors(
    income: AppPalette.primaryContainer,
    onIncome: AppPalette.onPrimary,
    expense: AppPalette.secondary,
    onExpense: AppPalette.onSecondary,
    pending: AppPalette.amber,
    onPending: AppPalette.onTertiaryFixed,
    heroSurface: scheme.primaryContainer,
    onHeroSurface: scheme.onPrimaryContainer,
    inputContainer: AppPalette.inputContainer,
    meterTrack: AppPalette.meterTrack,
  );

  static AppExtraColors dark(ColorScheme scheme) => AppExtraColors(
    income: scheme.primary,
    onIncome: scheme.onPrimary,
    expense: scheme.secondary,
    onExpense: scheme.onSecondary,
    pending: AppPalette.amber,
    onPending: AppPalette.onTertiaryFixed,
    heroSurface: scheme.primaryContainer,
    onHeroSurface: scheme.onPrimaryContainer,
    inputContainer: scheme.surfaceContainerHighest,
    meterTrack: scheme.surfaceContainerHighest,
  );

  static AppExtraColors of(BuildContext context) =>
      Theme.of(context).extension<AppExtraColors>()!;

  @override
  AppExtraColors copyWith({
    Color? income,
    Color? onIncome,
    Color? expense,
    Color? onExpense,
    Color? pending,
    Color? onPending,
    Color? heroSurface,
    Color? onHeroSurface,
    Color? inputContainer,
    Color? meterTrack,
  }) {
    return AppExtraColors(
      income: income ?? this.income,
      onIncome: onIncome ?? this.onIncome,
      expense: expense ?? this.expense,
      onExpense: onExpense ?? this.onExpense,
      pending: pending ?? this.pending,
      onPending: onPending ?? this.onPending,
      heroSurface: heroSurface ?? this.heroSurface,
      onHeroSurface: onHeroSurface ?? this.onHeroSurface,
      inputContainer: inputContainer ?? this.inputContainer,
      meterTrack: meterTrack ?? this.meterTrack,
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
      pending: Color.lerp(pending, other.pending, t)!,
      onPending: Color.lerp(onPending, other.onPending, t)!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      onHeroSurface: Color.lerp(onHeroSurface, other.onHeroSurface, t)!,
      inputContainer: Color.lerp(inputContainer, other.inputContainer, t)!,
      meterTrack: Color.lerp(meterTrack, other.meterTrack, t)!,
    );
  }
}
