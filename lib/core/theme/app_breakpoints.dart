import 'package:flutter/material.dart';

/// Responsive width classes for Family Finance.
///
/// Scale (Material 3 window size classes, mapped to the UI mock):
/// - [AppBreakpoint.mobile] (compact): width < 600 — mock ~390
/// - [AppBreakpoint.tablet] (medium): 600 ≤ width < 840 — mock ~768
/// - [AppBreakpoint.wide] (expanded): width ≥ 840 — mock ~1180
///
/// Navigation intent from the mock:
/// - mobile → bottom [NavigationBar] + FAB
/// - tablet → horizontal-ish bottom nav
/// - wide → [NavigationRail]
enum AppBreakpoint { mobile, tablet, wide }

/// Centralized breakpoint thresholds and helpers.
abstract final class AppBreakpoints {
  /// Upper bound exclusive for [AppBreakpoint.mobile].
  static const double compact = 600;

  /// Upper bound exclusive for [AppBreakpoint.tablet]; [wide] starts here.
  static const double medium = 840;

  /// Default max width for forms / auth / onboarding columns.
  static const double maxFormWidth = 420;

  /// Comfortable reading width for general page content on large screens.
  static const double maxContentWidth = 720;

  static AppBreakpoint of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compact) return AppBreakpoint.mobile;
    if (width < medium) return AppBreakpoint.tablet;
    return AppBreakpoint.wide;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == AppBreakpoint.mobile;

  static bool isTablet(BuildContext context) =>
      of(context) == AppBreakpoint.tablet;

  static bool isWide(BuildContext context) => of(context) == AppBreakpoint.wide;

  /// True when the shell should use a navigation rail (wide / expanded).
  static bool useNavigationRail(BuildContext context) => isWide(context);

  /// Content column max width; forms stay narrower.
  static double contentMaxWidth(BuildContext context, {bool form = false}) {
    if (form) return maxFormWidth;
    final bp = of(context);
    return switch (bp) {
      AppBreakpoint.mobile => double.infinity,
      AppBreakpoint.tablet => maxContentWidth,
      AppBreakpoint.wide => maxContentWidth,
    };
  }
}
