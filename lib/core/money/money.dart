import 'package:intl/intl.dart';

/// Money amounts are stored as positive integers in minor units (cents).
///
/// Parsing and formatting follow the UI [locale] decimal conventions:
/// - Italian (`it`): `1.234,56`
/// - English (`en`): `1,234.56`
class Money {
  Money._();

  /// Parses a locale-formatted decimal string into minor units (cents).
  ///
  /// Throws [FormatException] when the input is empty or not a valid number.
  static int parseToMinor(String input, String locale) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty money input');
    }

    final normalized = _normalizeToPlainDecimal(trimmed, locale);
    final value = double.tryParse(normalized);
    if (value == null || value.isNaN || value.isInfinite) {
      throw FormatException('Invalid money input: $input');
    }
    if (value < 0) {
      throw FormatException('Negative money input: $input');
    }

    // Round to nearest cent to avoid floating-point drift (e.g. 1.10).
    return (value * 100).round();
  }

  /// Formats [amountMinor] as a locale-aware decimal string (no currency symbol).
  static String formatFromMinor(int amountMinor, String locale) {
    if (amountMinor < 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be >= 0');
    }
    final major = amountMinor / 100.0;
    final formatter = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    return formatter.format(major);
  }

  /// Strips grouping separators and converts the decimal separator to `.`.
  static String _normalizeToPlainDecimal(String input, String locale) {
    final format = NumberFormat.decimalPattern(locale);
    final symbols = format.symbols;
    final group = symbols.GROUP_SEP;
    final decimal = symbols.DECIMAL_SEP;

    var cleaned = input.replaceAll(group, '');
    if (decimal != '.') {
      cleaned = cleaned.replaceAll(decimal, '.');
    }

    // Reject leftover unexpected separators (e.g. mixed en/it input).
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(cleaned)) {
      throw FormatException('Invalid money input for locale $locale: $input');
    }
    return cleaned;
  }
}
