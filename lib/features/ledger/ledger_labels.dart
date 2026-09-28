import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../categories/data/categories_repository.dart';

/// Resolves system `nameKey` or custom `name` for display.
String categoryLabel(AppLocalizations l10n, Category category) {
  final key = category.nameKey;
  if (key != null && key.isNotEmpty) {
    return switch (key) {
      'categoryFood' => l10n.categoryFood,
      'categoryTransport' => l10n.categoryTransport,
      'categoryHousing' => l10n.categoryHousing,
      'categoryUtilities' => l10n.categoryUtilities,
      'categoryHealth' => l10n.categoryHealth,
      'categoryEntertainment' => l10n.categoryEntertainment,
      'categoryShopping' => l10n.categoryShopping,
      'categoryEducation' => l10n.categoryEducation,
      'categoryOtherExpense' => l10n.categoryOtherExpense,
      'categorySalary' => l10n.categorySalary,
      'categoryOtherIncome' => l10n.categoryOtherIncome,
      _ => key,
    };
  }
  return category.name ?? '';
}

/// Formats a [DateTime] as Firestore bookingDate `YYYY-MM-DD`.
String formatBookingDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime? parseBookingDate(String raw) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return null;
  return DateTime.tryParse(raw);
}

Future<String?> pickBookingDate(BuildContext context, {String? initial}) async {
  final initialDate = parseBookingDate(initial ?? '') ?? DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (picked == null) return null;
  return formatBookingDate(picked);
}
