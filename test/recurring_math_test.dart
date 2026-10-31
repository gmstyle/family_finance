import 'package:family_finance/features/transactions/domain/recurring_rule.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors `functions/src/ledger/recurring_math.test.ts` — keep cases aligned.
void main() {
  group('daysInCalendarMonth / clampDayOfMonth', () {
    test('knows 30/31-day months', () {
      expect(daysInCalendarMonth(2026, 1), 31);
      expect(daysInCalendarMonth(2026, 4), 30);
      expect(daysInCalendarMonth(2026, 2), 28);
      expect(daysInCalendarMonth(2024, 2), 29);
    });

    test('clamps dayOfMonth to month length', () {
      expect(clampDayOfMonth(2026, 1, 31), 31);
      expect(clampDayOfMonth(2026, 2, 31), 28);
      expect(clampDayOfMonth(2024, 2, 31), 29);
      expect(clampDayOfMonth(2026, 4, 31), 30);
      expect(clampDayOfMonth(2026, 3, 15), 15);
    });
  });

  group('monthlyBookingDate', () {
    test('formats and clamps', () {
      expect(monthlyBookingDate(2026, 1, 31), '2026-01-31');
      expect(monthlyBookingDate(2026, 2, 31), '2026-02-28');
      expect(monthlyBookingDate(2024, 2, 31), '2024-02-29');
      expect(monthlyBookingDate(2026, 3, 5), '2026-03-05');
    });
  });

  group('advanceMonthlyBookingDate', () {
    test('advances mid-month', () {
      expect(advanceMonthlyBookingDate('2026-03-15', 15), '2026-04-15');
    });

    test('clamps end-of-month across Feb', () {
      expect(advanceMonthlyBookingDate('2026-01-31', 31), '2026-02-28');
      expect(advanceMonthlyBookingDate('2024-01-31', 31), '2024-02-29');
      expect(advanceMonthlyBookingDate('2026-02-28', 31), '2026-03-31');
      expect(advanceMonthlyBookingDate('2024-02-29', 31), '2024-03-31');
    });

    test('rolls year', () {
      expect(advanceMonthlyBookingDate('2026-12-10', 10), '2027-01-10');
      expect(advanceMonthlyBookingDate('2026-12-31', 31), '2027-01-31');
    });

    test('keeps preferred day when month allows', () {
      expect(advanceMonthlyBookingDate('2026-02-28', 28), '2026-03-28');
    });
  });

  group('nextMonthlyBookingDate', () {
    test('same day-of-month → next month (avoid duplicate manual post)', () {
      expect(
        nextMonthlyBookingDate(afterDate: '2026-03-15', dayOfMonth: 15),
        '2026-04-15',
      );
    });

    test('later day this month', () {
      expect(
        nextMonthlyBookingDate(afterDate: '2026-03-15', dayOfMonth: 20),
        '2026-03-20',
      );
    });

    test('earlier day → next month', () {
      expect(
        nextMonthlyBookingDate(afterDate: '2026-03-15', dayOfMonth: 10),
        '2026-04-10',
      );
    });

    test('clamps when next candidate is end-of-month', () {
      expect(
        nextMonthlyBookingDate(afterDate: '2026-01-31', dayOfMonth: 31),
        '2026-02-28',
      );
      expect(
        nextMonthlyBookingDate(afterDate: '2026-01-30', dayOfMonth: 31),
        '2026-01-31',
      );
      expect(
        nextMonthlyBookingDate(afterDate: '2026-02-28', dayOfMonth: 31),
        '2026-03-31',
      );
    });
  });

  group('nextBookingDateAfterFirstOccurrence', () {
    test('uses bookingDate when it is on/after today', () {
      expect(
        nextBookingDateAfterFirstOccurrence(
          bookingDate: '2026-03-15',
          dayOfMonth: 15,
          now: DateTime(2026, 3, 10),
        ),
        '2026-04-15',
      );
    });

    test('anchors after today when bookingDate is in the past', () {
      expect(
        nextBookingDateAfterFirstOccurrence(
          bookingDate: '2026-01-15',
          dayOfMonth: 15,
          now: DateTime(2026, 3, 20),
        ),
        '2026-04-15',
      );
    });
  });

  group('endBookingDateForTotalOccurrences', () {
    test('counts the first payment as occurrence 1', () {
      expect(
        endBookingDateForTotalOccurrences(
          firstBookingDate: '2026-03-20',
          dayOfMonth: 20,
          totalOccurrences: 1,
        ),
        '2026-03-20',
      );
      expect(
        endBookingDateForTotalOccurrences(
          firstBookingDate: '2026-03-20',
          dayOfMonth: 20,
          totalOccurrences: 12,
        ),
        '2027-02-20',
      );
    });

    test('clamps end-of-month across the series', () {
      expect(
        endBookingDateForTotalOccurrences(
          firstBookingDate: '2026-01-31',
          dayOfMonth: 31,
          totalOccurrences: 3,
        ),
        '2026-03-31',
      );
    });
  });

  group('dueBookingDatesUntil (materialize catch-up)', () {
    test('writes due months and advances past today', () {
      final dates = dueBookingDatesUntil(
        nextBookingDate: '2026-01-31',
        today: '2026-03-15',
        dayOfMonth: 31,
      );
      expect(dates, ['2026-01-31', '2026-02-28']);
      // Next after last written would be 2026-03-31 (still future vs today).
      expect(advanceMonthlyBookingDate(dates.last, 31), '2026-03-31');
    });

    test('stops at inclusive endBookingDate', () {
      final dates = dueBookingDatesUntil(
        nextBookingDate: '2026-01-20',
        today: '2026-06-01',
        dayOfMonth: 20,
        endBookingDate: '2026-03-20',
      );
      expect(dates, ['2026-01-20', '2026-02-20', '2026-03-20']);
    });

    test('deterministic tx id shape', () {
      const ruleId = 'abc123';
      final dates = dueBookingDatesUntil(
        nextBookingDate: '2026-04-01',
        today: '2026-04-01',
        dayOfMonth: 1,
      );
      expect(dates, ['2026-04-01']);
      expect('${ruleId}_${dates.first}', 'abc123_2026-04-01');
    });
  });
}
