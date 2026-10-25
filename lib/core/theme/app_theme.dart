import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Material 3 Kinship Finance theme (Stitch DESIGN.md).
///
/// Explicit teal/terracotta/amber palette + Plus Jakarta Sans; pill controls;
/// L1 tonal cards. Dark theme is derived from the same brand tokens.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = brightness == Brightness.light
        ? AppPalette.lightScheme()
        : AppPalette.darkScheme();
    final extras = brightness == Brightness.light
        ? AppExtraColors.light(colorScheme)
        : AppExtraColors.dark(colorScheme);
    final textTheme = _textTheme(colorScheme);

    final pill = RoundedRectangleBorder(borderRadius: AppRadius.fullAll);
    final inputRadius = AppRadius.mdAll;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      extensions: [extras],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLowest,
        shape: AppElevation.cardShape(),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shadowColor: AppPalette.primaryContainer.withValues(alpha: 0.04),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSizes.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: pill,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSizes.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: pill,
          side: BorderSide(color: colorScheme.primaryContainer, width: 1.5),
          foregroundColor: colorScheme.primaryContainer,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, AppSizes.minTapTarget),
          shape: pill,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: pill,
        extendedPadding: AppInsets.fabPadding,
        elevation: 2,
        highlightElevation: 4,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.16),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.16),
        indicatorShape: const StadiumBorder(),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
        selectedIconTheme: IconThemeData(color: colorScheme.primaryContainer),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: extras.inputContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: colorScheme.primaryContainer, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: extras.inputContainer,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(extras.inputContainer),
        shape: WidgetStatePropertyAll(pill),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        backgroundColor: colorScheme.surfaceContainerLowest,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearMinHeight: AppSizes.progressBarHeight,
        color: colorScheme.primaryContainer,
        linearTrackColor: extras.meterTrack,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }

  /// Plus Jakarta Sans text theme aligned to DESIGN.md type ramp.
  static TextTheme _textTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: colorScheme.brightness).textTheme,
    );
    final onSurface = colorScheme.onSurface;

    TextStyle? style(
      TextStyle? source, {
      required double size,
      required FontWeight weight,
      required double height,
      double letterSpacing = 0,
    }) {
      return source?.copyWith(
        fontSize: size,
        fontWeight: weight,
        height: height / size,
        letterSpacing: letterSpacing,
        color: onSurface,
      );
    }

    return base.copyWith(
      displayLarge: style(
        base.displayLarge,
        size: 57,
        weight: FontWeight.w700,
        height: 64,
        letterSpacing: -0.25,
      ),
      displayMedium: style(
        base.displayMedium,
        size: 45,
        weight: FontWeight.w700,
        height: 52,
        letterSpacing: -0.25,
      ),
      displaySmall: style(
        base.displaySmall,
        size: 36,
        weight: FontWeight.w700,
        height: 44,
      ),
      headlineLarge: style(
        base.headlineLarge,
        size: 32,
        weight: FontWeight.w700,
        height: 40,
      ),
      headlineMedium: style(
        base.headlineMedium,
        size: 24,
        weight: FontWeight.w600,
        height: 32,
      ),
      headlineSmall: style(
        base.headlineSmall,
        size: 20,
        weight: FontWeight.w600,
        height: 28,
      ),
      titleLarge: style(
        base.titleLarge,
        size: 22,
        weight: FontWeight.w600,
        height: 28,
      ),
      titleMedium: style(
        base.titleMedium,
        size: 16,
        weight: FontWeight.w600,
        height: 24,
        letterSpacing: 0.15,
      ),
      titleSmall: style(
        base.titleSmall,
        size: 14,
        weight: FontWeight.w600,
        height: 20,
        letterSpacing: 0.1,
      ),
      bodyLarge: style(
        base.bodyLarge,
        size: 16,
        weight: FontWeight.w400,
        height: 24,
        letterSpacing: 0.5,
      ),
      bodyMedium: style(
        base.bodyMedium,
        size: 14,
        weight: FontWeight.w400,
        height: 20,
        letterSpacing: 0.25,
      ),
      bodySmall: style(
        base.bodySmall,
        size: 12,
        weight: FontWeight.w400,
        height: 16,
        letterSpacing: 0.4,
      ),
      labelLarge: style(
        base.labelLarge,
        size: 14,
        weight: FontWeight.w600,
        height: 20,
        letterSpacing: 0.1,
      ),
      labelMedium: style(
        base.labelMedium,
        size: 12,
        weight: FontWeight.w500,
        height: 16,
        letterSpacing: 0.5,
      ),
      labelSmall: style(
        base.labelSmall,
        size: 11,
        weight: FontWeight.w500,
        height: 16,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Text styles for money amounts (DESIGN `tabular-amount-lg` / `md`).
abstract final class AppTextStyles {
  static const _tabular = [FontFeature.tabularFigures()];

  /// Hero / dashboard total balance — DESIGN `tabular-amount-lg`.
  static TextStyle? displayAmount(BuildContext context) {
    final theme = Theme.of(context);
    return GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      height: 40 / 32,
      letterSpacing: -0.5,
      color: theme.colorScheme.onSurface,
      fontFeatures: _tabular,
    );
  }

  /// Amount in transaction / account rows — DESIGN `tabular-amount-md`.
  static TextStyle? listAmount(BuildContext context) {
    final theme = Theme.of(context);
    return GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 24 / 18,
      letterSpacing: 0,
      color: theme.colorScheme.onSurface,
      fontFeatures: _tabular,
    );
  }

  /// Alias for [displayAmount].
  static TextStyle? tabularAmountLg(BuildContext context) =>
      displayAmount(context);

  /// Alias for [listAmount].
  static TextStyle? tabularAmountMd(BuildContext context) =>
      listAmount(context);
}
