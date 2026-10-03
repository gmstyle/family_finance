/// Remote Config / built-in regex patterns for bank notification parsing.
class NotificationParsePatterns {
  const NotificationParsePatterns({
    required this.amountPatterns,
    required this.merchantPatterns,
    required this.datePatterns,
  });

  final List<RegExp> amountPatterns;
  final List<RegExp> merchantPatterns;
  final List<RegExp> datePatterns;

  /// Sensible Italian / Wallet defaults when Remote Config is empty.
  factory NotificationParsePatterns.defaults() {
    return NotificationParsePatterns(
      amountPatterns: [
        // "Hai speso 12,50 €" / "Pagamento di € 25,00" / "12.50 EUR"
        RegExp(
          r'(?:speso|pagamento(?:\s+di)?|acquist[oa](?:\s+di)?|addebit[oa]|'
          r'importo|amount|paid|spent|purchase)\s*(?:di\s+|of\s+)?'
          r'(?:€\s*)?(\d{1,3}(?:[.\s]\d{3})*,\d{2}|\d+,\d{2}|'
          r'\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2})\s*(?:€|eur|euro)?',
          caseSensitive: false,
        ),
        RegExp(
          r'(?:€|eur|euro)\s*(\d{1,3}(?:[.\s]\d{3})*,\d{2}|\d+,\d{2}|'
          r'\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2})',
          caseSensitive: false,
        ),
        RegExp(
          r'(\d{1,3}(?:[.\s]\d{3})*,\d{2}|\d+,\d{2}|'
          r'\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2})\s*(?:€|eur|euro)',
          caseSensitive: false,
        ),
      ],
      merchantPatterns: [
        // Longer Italian / English cues first.
        RegExp(
          r'(?:presso|verso|at|from)\s+([A-Za-z][\w &.\-]{1,48})',
          caseSensitive: false,
        ),
        // Short prepositions need word boundaries so "carta" ≠ "a …".
        RegExp(
          r'(?:\ba\b|\bda\b|\bto\b|\bper\b)\s+([A-Za-z][A-Za-z0-9 &.\-]{1,40})',
          caseSensitive: false,
        ),
        RegExp(
          r'(?:merchant|esercente|negozio)\s*[:\-]?\s*'
          r'([A-Za-z][\w &.\-]{1,48})',
          caseSensitive: false,
        ),
      ],
      datePatterns: [
        // 03/10/2026 or 03-10-2026 or 03.10.2026
        RegExp(r'\b(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})\b'),
        // 2026-10-03
        RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b'),
      ],
    );
  }

  /// Builds patterns from Remote Config JSON maps (string lists of regexes).
  ///
  /// Invalid regex strings are skipped; empty lists fall back to defaults
  /// for that field.
  factory NotificationParsePatterns.fromRemoteConfig({
    List<String>? amountRegexes,
    List<String>? merchantRegexes,
    List<String>? dateRegexes,
  }) {
    final defaults = NotificationParsePatterns.defaults();
    return NotificationParsePatterns(
      amountPatterns: _compile(amountRegexes, defaults.amountPatterns),
      merchantPatterns: _compile(merchantRegexes, defaults.merchantPatterns),
      datePatterns: _compile(dateRegexes, defaults.datePatterns),
    );
  }

  static List<RegExp> _compile(List<String>? raw, List<RegExp> fallback) {
    if (raw == null || raw.isEmpty) return fallback;
    final out = <RegExp>[];
    for (final s in raw) {
      final trimmed = s.trim();
      if (trimmed.isEmpty) continue;
      try {
        out.add(RegExp(trimmed, caseSensitive: false));
      } on FormatException {
        // Skip invalid Remote Config entries.
      }
    }
    return out.isEmpty ? fallback : out;
  }
}
