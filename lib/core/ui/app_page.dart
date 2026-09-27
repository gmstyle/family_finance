import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_tokens.dart';

/// Centered max-width content wrapper (auth forms, settings sections, etc.).
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.form = false,
    this.padding,
    this.safeArea = false,
  });

  final Widget child;

  /// When true, uses [AppBreakpoints.maxFormWidth].
  final bool form;

  final EdgeInsetsGeometry? padding;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final maxWidth = form
        ? AppBreakpoints.maxFormWidth
        : AppBreakpoints.contentMaxWidth(context);

    Widget body = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth.isFinite ? maxWidth : double.infinity,
        ),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (safeArea) {
      body = SafeArea(child: body);
    }
    return body;
  }
}

/// Section heading used on settings / family lists.
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(
    this.text, {
    super.key,
    this.padding = AppInsets.section,
  });

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
