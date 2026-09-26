import 'package:family_finance/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('it');
    Intl.defaultLocale = 'en';
  });

  group('Money.parseToMinor', () {
    test('parses Italian grouped decimal', () {
      expect(Money.parseToMinor('1.234,56', 'it'), 123456);
      expect(Money.parseToMinor('0,99', 'it'), 99);
      expect(Money.parseToMinor('10', 'it'), 1000);
    });

    test('parses English grouped decimal', () {
      expect(Money.parseToMinor('1,234.56', 'en'), 123456);
      expect(Money.parseToMinor('0.99', 'en'), 99);
      expect(Money.parseToMinor('10', 'en'), 1000);
    });

    test('rejects empty and invalid input', () {
      expect(() => Money.parseToMinor('', 'en'), throwsFormatException);
      expect(() => Money.parseToMinor('abc', 'en'), throwsFormatException);
      expect(() => Money.parseToMinor('-1.00', 'en'), throwsFormatException);
    });
  });

  group('Money.formatFromMinor', () {
    test('formats Italian locale', () {
      expect(Money.formatFromMinor(123456, 'it'), '1.234,56');
      expect(Money.formatFromMinor(99, 'it'), '0,99');
    });

    test('formats English locale', () {
      expect(Money.formatFromMinor(123456, 'en'), '1,234.56');
      expect(Money.formatFromMinor(99, 'en'), '0.99');
    });

    test('round-trips both locales', () {
      for (final locale in ['en', 'it']) {
        const minor = 123456;
        final formatted = Money.formatFromMinor(minor, locale);
        expect(Money.parseToMinor(formatted, locale), minor);
      }
    });
  });
}
