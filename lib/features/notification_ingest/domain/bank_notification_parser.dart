import 'captured_notification.dart';
import 'notification_parse_patterns.dart';

/// Parsed fields from a bank / wallet notification (in-memory only).
class ParsedBankNotification {
  const ParsedBankNotification({
    required this.packageName,
    this.amountMinor,
    this.bookingDate,
    this.merchant,
  });

  final String packageName;
  final int? amountMinor;
  final String? bookingDate;
  final String? merchant;

  bool get hasAnyField =>
      amountMinor != null ||
      (bookingDate != null && bookingDate!.isNotEmpty) ||
      (merchant != null && merchant!.trim().isNotEmpty);
}

/// Pure-Dart parser for Italian / bank-style payment notifications.
///
/// Driven by [NotificationParsePatterns] (Remote Config or built-in defaults).
/// Never stores raw notification text.
class BankNotificationParser {
  BankNotificationParser({NotificationParsePatterns? patterns})
    : patterns = patterns ?? NotificationParsePatterns.defaults();

  final NotificationParsePatterns patterns;

  /// Parses [captured] into draft fields. Uses [postTimeMs] as booking-date
  /// fallback when no date appears in the text.
  ParsedBankNotification parse(CapturedNotification captured) {
    final text = captured.combinedText;
    final amount = _extractAmount(text);
    final merchant = _extractMerchant(text);
    final dateFromText = _extractDate(text);
    final bookingDate =
        dateFromText ?? _bookingDateFromMillis(captured.postTimeMs);

    return ParsedBankNotification(
      packageName: captured.packageName,
      amountMinor: amount,
      bookingDate: bookingDate,
      merchant: merchant,
    );
  }

  /// Convenience for unit tests — parse a free-form string.
  ParsedBankNotification parseText({
    required String text,
    required String packageName,
    int postTimeMs = 0,
  }) {
    return parse(
      CapturedNotification(
        packageName: packageName,
        title: '',
        text: text,
        postTimeMs: postTimeMs,
      ),
    );
  }

  int? _extractAmount(String text) {
    for (final re in patterns.amountPatterns) {
      final match = re.firstMatch(text);
      if (match == null) continue;
      final token = match.groupCount >= 1
          ? (match.group(1) ?? match.group(0))
          : match.group(0);
      if (token == null) continue;
      final minor = _parseAmountToken(token);
      if (minor != null && minor > 0) return minor;
    }
    return null;
  }

  String? _extractMerchant(String text) {
    for (final re in patterns.merchantPatterns) {
      final match = re.firstMatch(text);
      if (match == null) continue;
      final raw = match.groupCount >= 1 ? match.group(1) : match.group(0);
      if (raw == null) continue;
      final cleaned = _cleanMerchant(raw);
      if (cleaned != null) return cleaned;
    }
    return null;
  }

  String? _extractDate(String text) {
    for (final re in patterns.datePatterns) {
      final match = re.firstMatch(text);
      if (match == null) continue;
      final iso = _matchToIsoDate(match);
      if (iso != null) return iso;
    }
    return null;
  }

  String? _bookingDateFromMillis(int ms) {
    if (ms <= 0) return null;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? _matchToIsoDate(RegExpMatch match) {
    // ISO yyyy-MM-dd (groups: y, m, d)
    if (match.groupCount >= 3) {
      final g1 = match.group(1)!;
      final g2 = match.group(2)!;
      final g3 = match.group(3)!;
      if (g1.length == 4) {
        return _iso(int.parse(g1), int.parse(g2), int.parse(g3));
      }
      // dd/MM/yyyy or dd/MM/yy
      var year = int.parse(g3);
      if (year < 100) year += 2000;
      return _iso(year, int.parse(g2), int.parse(g1));
    }
    return null;
  }

  String? _iso(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 2000 || year > 2100) return null;
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  int? _parseAmountToken(String raw) {
    var s = raw.trim();
    s = s.replaceAll('€', '').replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll(RegExp(r'eur|euro', caseSensitive: false), '');
    if (s.isEmpty) return null;

    // Italian: 1.234,56 / 12,50 — English: 1,234.56 / 12.50
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        // 1.234,56
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // 1,234.56
        s = s.replaceAll(',', '');
      }
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }

    final value = double.tryParse(s);
    if (value == null || value <= 0) return null;
    return (value * 100).round();
  }

  String? _cleanMerchant(String raw) {
    var s = raw.trim();
    // Cut trailing sentence / amount / date noise.
    s = s.split(RegExp(r'[.!?\n]')).first.trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll('€', '');
    s = s.replaceAll(
      RegExp(
        r'\s*(?:eur|euro)?\s*\d{1,3}(?:[.\s]\d{3})*,\d{2}.*$',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceAll(RegExp(r'\s*(?:eur|euro)\s*$', caseSensitive: false), '');
    // "CONAD il 07/11/2026" / "Amazon on 2026-10-03"
    s = s.replaceAll(
      RegExp(r'\s+(?:il|del|on|the)\s+\d{1,4}.*$', caseSensitive: false),
      '',
    );
    s = s.trim();
    // Reject pure noise / too short.
    if (s.length < 2) return null;
    if (RegExp(r'^\d').hasMatch(s)) return null;
    final lower = s.toLowerCase();
    if (lower == 'in' ||
        lower.startsWith('in ') ||
        lower == 'il' ||
        lower == 'lo' ||
        lower == 'la') {
      return null;
    }
    // Title-case-ish for display.
    return s
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          if (w.length <= 3 && w == w.toUpperCase()) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
