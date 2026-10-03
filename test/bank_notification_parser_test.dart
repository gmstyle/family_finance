import 'package:family_finance/features/notification_ingest/domain/bank_notification_parser.dart';
import 'package:family_finance/features/notification_ingest/domain/notification_parse_patterns.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = BankNotificationParser();

  group('BankNotificationParser', () {
    test('parses Italian Wallet-style spent notification', () {
      final parsed = parser.parseText(
        packageName: 'com.google.android.apps.walletnfcrel',
        text: 'Hai speso 12,50 € presso ESSO Milano',
        postTimeMs: DateTime(2026, 10, 3, 14, 30).millisecondsSinceEpoch,
      );

      expect(parsed.amountMinor, 1250);
      expect(parsed.merchant, 'Esso Milano');
      expect(parsed.bookingDate, '2026-10-03');
      expect(parsed.packageName, 'com.google.android.apps.walletnfcrel');
    });

    test('parses pagamento di with euro prefix', () {
      final parsed = parser.parseText(
        packageName: 'com.google.android.apps.walletnfcrel',
        text: 'Pagamento di € 25,00 a Amazon',
        postTimeMs: DateTime(2026, 1, 15).millisecondsSinceEpoch,
      );

      expect(parsed.amountMinor, 2500);
      expect(parsed.merchant, 'Amazon');
      expect(parsed.bookingDate, '2026-01-15');
    });

    test('parses English-style amount and merchant', () {
      final parsed = parser.parseText(
        packageName: 'com.google.android.apps.walletnfcrel',
        text: 'You spent \$notused Paid 10.99 EUR at Starbucks',
        postTimeMs: DateTime(2026, 5, 1).millisecondsSinceEpoch,
      );

      expect(parsed.amountMinor, 1099);
      expect(parsed.merchant, 'Starbucks');
    });

    test('parses date from notification text over postTime', () {
      final parsed = parser.parseText(
        packageName: 'com.example.bank',
        text: 'Acquisto di 8,00 EUR da CONAD il 07/11/2026',
        postTimeMs: DateTime(2020, 1, 1).millisecondsSinceEpoch,
      );

      expect(parsed.amountMinor, 800);
      expect(parsed.merchant, 'Conad');
      expect(parsed.bookingDate, '2026-11-07');
    });

    test('parses amount with thousand separator', () {
      final parsed = parser.parseText(
        packageName: 'com.google.android.apps.walletnfcrel',
        text: 'Hai speso 1.234,56 € presso IKEA',
        postTimeMs: DateTime(2026, 3, 3).millisecondsSinceEpoch,
      );

      expect(parsed.amountMinor, 123456);
      expect(parsed.merchant, 'Ikea');
    });

    test('handles missing fields gracefully', () {
      final parsed = parser.parseText(
        packageName: 'com.google.android.apps.walletnfcrel',
        text: 'Promemoria carta in scadenza',
        postTimeMs: 0,
      );

      expect(parsed.amountMinor, isNull);
      expect(parsed.merchant, isNull);
      expect(parsed.bookingDate, isNull);
      expect(parsed.hasAnyField, isFalse);
    });

    test('uses Remote Config amount pattern override', () {
      final custom = BankNotificationParser(
        patterns: NotificationParsePatterns.fromRemoteConfig(
          amountRegexes: [r'IMPORTO\s+(\d+,\d{2})'],
        ),
      );

      final parsed = custom.parseText(
        packageName: 'com.example.bank',
        text: 'IMPORTO 42,00 presso Test',
        postTimeMs: DateTime(2026, 6, 6).millisecondsSinceEpoch,
      );

      expect(parsed.amountMinor, 4200);
    });
  });
}
