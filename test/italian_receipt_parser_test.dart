import 'package:family_finance/features/receipt_ocr/domain/italian_receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ItalianReceiptParser();

  group('ItalianReceiptParser', () {
    test('extracts totale, date, and merchant from a typical scontrino', () {
      final parsed = parser.parse(const [
        'ESSELUNGA S.P.A.',
        'Via Roma 12',
        '20100 Milano',
        'P.IVA 01234567890',
        'Pane 1,20',
        'Latte 1,50',
        'TOTALE EUR',
        '12,70',
        '03/10/2026 18:42',
        'Carta *1234',
        'Grazie',
      ]);

      expect(parsed.merchant, 'Esselunga S.p.a.');
      expect(parsed.amountMinor, 1270);
      expect(parsed.bookingDate, '2026-10-03');
    });

    test('prefers TOTALE over smaller line amounts', () {
      final parsed = parser.parse(const [
        'CONAD',
        'Acqua 0,80',
        'Pasta 2,30',
        'TOTALE 45,90',
        '15-09-2025',
      ]);

      expect(parsed.amountMinor, 4590);
      expect(parsed.bookingDate, '2025-09-15');
      expect(parsed.merchant, 'Conad');
    });

    test('parses amount with thousand separator', () {
      final parsed = parser.parse(const [
        'IKEA ITALIA',
        'TOTALE EURO 1.234,56',
        '01.12.2024',
      ]);

      expect(parsed.amountMinor, 123456);
      expect(parsed.bookingDate, '2024-12-01');
    });

    test('parses ISO date', () {
      final parsed = parser.parse(const ['COOP', 'TOTALE 9,99', '2026-03-28']);

      expect(parsed.bookingDate, '2026-03-28');
      expect(parsed.amountMinor, 999);
    });

    test('parses two-digit year', () {
      final parsed = parser.parse(const ['PAM LOCAL', 'TOT. 3,50', '07/11/26']);

      expect(parsed.bookingDate, '2026-11-07');
      expect(parsed.amountMinor, 350);
    });

    test('handles missing fields gracefully', () {
      final parsed = parser.parse(const ['???', 'abc']);
      expect(parsed.amountMinor, isNull);
      expect(parsed.bookingDate, isNull);
      expect(parsed.hasAnyField, isTrue); // merchant from first line
    });

    test('skips address noise for merchant', () {
      final parsed = parser.parse(const [
        'Via Garibaldi 8',
        'SUPERMERCATO LIDL',
        'TOTALE 8,00',
        '10/10/2026',
      ]);

      expect(parsed.merchant, 'Supermercato Lidl');
      expect(parsed.amountMinor, 800);
    });
  });
}
