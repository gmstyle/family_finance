/// Parsed fields from Italian receipt OCR lines (in-memory only).
///
/// Raw OCR text / photos are never persisted — only these draft fields.
class ParsedReceipt {
  const ParsedReceipt({this.amountMinor, this.bookingDate, this.merchant});

  /// Total in minor units (cents), always positive when present.
  final int? amountMinor;

  /// Booking date as `YYYY-MM-DD` when parsed.
  final String? bookingDate;

  /// Likely merchant / store name from the header.
  final String? merchant;

  bool get hasAnyField =>
      amountMinor != null ||
      (bookingDate != null && bookingDate!.isNotEmpty) ||
      (merchant != null && merchant!.trim().isNotEmpty);
}

/// Pure-Dart parser for Italian fiscal receipts / scontrini.
class ItalianReceiptParser {
  const ItalianReceiptParser();

  static final _datePatterns = <RegExp>[
    // 03/10/2026 or 03-10-2026 or 03.10.2026
    RegExp(r'\b(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})\b'),
    // 2026-10-03
    RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b'),
  ];

  static final _totalLabel = RegExp(
    r'(?:totale|tot\.?|importo|euro|eur|pagato|da\s+pagare|non\s+pagato|'
    r'total|amount\s+due|carta|contanti)',
    caseSensitive: false,
  );

  static final _amountToken = RegExp(
    r'(?:€\s*)?(\d{1,3}(?:[.\s]\d{3})*,\d{2}|\d+,\d{2}|\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2})(?:\s*€)?',
  );

  static final _noiseLine = RegExp(
    r'^(?:via|viale|piazza|corso|p\.?zza|tel|telefono|p\.?\s*iva|partita|'
    r'cf|c\.?f\.?|scontrino|documento|doc\.?|cassa|operatore|grazie|'
    r'arrivederci|www\.|http|iva|imponibile|non\s+fiscale|fattura|'
    r'copie|copia|cliente|server|transazione|auth|aid|pan)',
    caseSensitive: false,
  );

  /// Parses OCR [lines] (top-to-bottom) into draft receipt fields.
  ParsedReceipt parse(List<String> lines) {
    final cleaned = lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);

    return ParsedReceipt(
      amountMinor: _extractAmount(cleaned),
      bookingDate: _extractDate(cleaned),
      merchant: _extractMerchant(cleaned),
    );
  }

  int? _extractAmount(List<String> lines) {
    int? labeled;
    int? labeledPriority;
    int? largest;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final hasLabel = _totalLabel.hasMatch(line);
      final amountsOnLine = _amountsOnLine(line);
      var tookLabeledOnLine = false;

      for (final minor in amountsOnLine) {
        if (largest == null || minor > largest) {
          largest = minor;
        }

        if (hasLabel) {
          // Prefer "TOTALE" over weaker labels; later labeled wins on ties.
          final priority = _labelPriority(line);
          final current = labeled;
          if (current == null ||
              priority > (labeledPriority ?? -1) ||
              (priority == labeledPriority && minor >= current)) {
            labeled = minor;
            labeledPriority = priority;
            tookLabeledOnLine = true;
          }
        }
      }

      // Amount often sits on the next line after "TOTALE" (only if missing here).
      if (hasLabel && !tookLabeledOnLine && i + 1 < lines.length) {
        final nextAmounts = _amountsOnLine(lines[i + 1]);
        if (nextAmounts.isNotEmpty) {
          final next = nextAmounts.last;
          final priority = _labelPriority(line);
          if (labeled == null || priority > (labeledPriority ?? -1)) {
            labeled = next;
            labeledPriority = priority;
          }
        }
      }
    }

    return labeled ?? largest;
  }

  int _labelPriority(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('totale') || lower.contains('tot.')) return 3;
    if (lower.contains('importo') || lower.contains('pagato')) return 2;
    if (lower.contains('euro') ||
        lower.contains('eur') ||
        lower.contains('€')) {
      return 1;
    }
    return 0;
  }

  List<int> _amountsOnLine(String line) {
    final values = <int>[];
    for (final match in _amountToken.allMatches(line)) {
      final raw = match.group(1)!;
      // Skip fragments that are clearly part of a date (e.g. 01.12.2024).
      if (_isDateFragment(line, match.start, match.end)) continue;
      final minor = _parseItalianOrPlainAmount(raw);
      if (minor != null && minor > 0) values.add(minor);
    }
    return values;
  }

  bool _isDateFragment(String line, int start, int end) {
    final matched = line.substring(start, end).trim();
    // `01.12` inside `01.12.2024` / `01/12/2024`, or a full date token.
    if (_datePatterns.any((p) => p.stringMatch(matched) == matched)) {
      return true;
    }
    if (RegExp(r'^\d{1,2}[./\-]\d{1,2}$').hasMatch(matched)) {
      final after = end < line.length ? line.substring(end) : '';
      if (RegExp(r'^[./\-]\d{2,4}\b').hasMatch(after)) return true;
    }
    return false;
  }

  /// Accepts Italian `1.234,56` / `12,50` and English `1,234.56` / `12.50`.
  int? _parseItalianOrPlainAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\s'), '');
    final hasComma = cleaned.contains(',');
    final hasDot = cleaned.contains('.');

    String normalized;
    if (hasComma && hasDot) {
      // Decide decimal separator by last occurrence.
      if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
        // 1.234,56
        normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // 1,234.56
        normalized = cleaned.replaceAll(',', '');
      }
    } else if (hasComma) {
      // 12,50 or 1.234 with wrong sep — treat comma as decimal when 2 digits follow.
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts[1].length == 2) {
        normalized = '${parts[0].replaceAll('.', '')}.${parts[1]}';
      } else {
        return null;
      }
    } else if (hasDot) {
      final parts = cleaned.split('.');
      if (parts.length == 2 && parts[1].length == 2) {
        normalized = cleaned; // 12.50
      } else if (parts.every((p) => p.length == 3 || p == parts.first)) {
        // Thousands only: 1.234 → unlikely as total without cents; skip.
        return null;
      } else {
        normalized = cleaned;
      }
    } else {
      // Integer euros → cents.
      final euros = int.tryParse(cleaned);
      if (euros == null) return null;
      return euros * 100;
    }

    final value = double.tryParse(normalized);
    if (value == null || value.isNaN || value.isInfinite || value < 0) {
      return null;
    }
    return (value * 100).round();
  }

  String? _extractDate(List<String> lines) {
    for (final line in lines) {
      for (final pattern in _datePatterns) {
        final match = pattern.firstMatch(line);
        if (match == null) continue;
        final iso = _toIsoDate(match);
        if (iso != null) return iso;
      }
    }
    return null;
  }

  String? _toIsoDate(RegExpMatch match) {
    // Pattern A: d/m/y — groups 1,2,3
    // Pattern B: y-m-d — groups 1,2,3 with year first
    final g1 = match.group(1)!;
    final g2 = match.group(2)!;
    final g3 = match.group(3)!;

    late final int year;
    late final int month;
    late final int day;

    if (g1.length == 4) {
      year = int.parse(g1);
      month = int.parse(g2);
      day = int.parse(g3);
    } else {
      day = int.parse(g1);
      month = int.parse(g2);
      var y = int.parse(g3);
      if (y < 100) y += 2000;
      year = y;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 2000 || year > 2100) return null;

    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? _extractMerchant(List<String> lines) {
    for (final line in lines.take(8)) {
      if (line.length < 3) continue;
      if (_noiseLine.hasMatch(line)) continue;
      if (_datePatterns.any((p) => p.hasMatch(line))) continue;
      if (_amountToken.hasMatch(line) && line.length < 12) continue;
      // Skip pure numbers / codes.
      if (RegExp(r'^[\d\s./\-:+]+$').hasMatch(line)) continue;
      return _titleCaseMerchant(line);
    }
    return null;
  }

  String _titleCaseMerchant(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed == trimmed.toUpperCase() && trimmed.length > 3) {
      return trimmed
          .split(' ')
          .map((w) {
            if (w.isEmpty) return w;
            return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
          })
          .join(' ');
    }
    return trimmed;
  }
}
