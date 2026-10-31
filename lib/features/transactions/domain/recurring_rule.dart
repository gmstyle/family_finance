import 'package:cloud_firestore/cloud_firestore.dart';

import '../../ledger/ledger_labels.dart';
import 'transaction.dart';

/// Monthly recurring expense/income rule (v1: monthly only).
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.type,
    required this.accountId,
    required this.categoryId,
    required this.amountMinor,
    required this.currency,
    required this.dayOfMonth,
    required this.active,
    required this.nextBookingDate,
    required this.createdByUserId,
    this.merchant,
    this.note,
    this.endBookingDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final TransactionType type;
  final String accountId;
  final String categoryId;
  final int amountMinor;
  final String currency;
  final String? merchant;
  final String? note;
  final int dayOfMonth;
  final bool active;
  final String nextBookingDate;

  /// Inclusive last occurrence (`YYYY-MM-DD`); null = open-ended.
  final String? endBookingDate;
  final String createdByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory RecurringRule.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final created = d['createdAt'];
    final updated = d['updatedAt'];
    final type = TransactionType.fromString(d['type'] as String? ?? 'expense');
    return RecurringRule(
      id: doc.id,
      type: type == TransactionType.income
          ? TransactionType.income
          : TransactionType.expense,
      accountId: d['accountId'] as String? ?? '',
      categoryId: d['categoryId'] as String? ?? '',
      amountMinor: (d['amountMinor'] as num?)?.toInt() ?? 0,
      currency: d['currency'] as String? ?? 'EUR',
      merchant: d['merchant'] as String?,
      note: d['note'] as String?,
      dayOfMonth: (d['dayOfMonth'] as num?)?.toInt() ?? 1,
      active: d['active'] as bool? ?? true,
      nextBookingDate: d['nextBookingDate'] as String? ?? '',
      endBookingDate: d['endBookingDate'] as String?,
      createdByUserId: d['createdByUserId'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }
}

/// Day-of-month (1–31) from a civil `YYYY-MM-DD` booking date.
int dayOfMonthFromBookingDate(String bookingDate) {
  final parsed = parseBookingDate(bookingDate);
  if (parsed == null) {
    throw ArgumentError.value(bookingDate, 'bookingDate', 'must be YYYY-MM-DD');
  }
  return parsed.day;
}

/// Days in calendar month (month is 1–12). Mirrors `daysInCalendarMonth` in TS.
int daysInCalendarMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

/// Clamp [dayOfMonth] (1–31) into a real calendar day for [year]/[month].
int clampDayOfMonth(int year, int month, int dayOfMonth) {
  final dim = daysInCalendarMonth(year, month);
  return dayOfMonth > dim ? dim : dayOfMonth;
}

/// YYYY-MM-DD for year/month with [dayOfMonth] clamped to the month length.
String monthlyBookingDate(int year, int month, int dayOfMonth) {
  final day = clampDayOfMonth(year, month, dayOfMonth);
  return formatBookingDate(DateTime(year, month, day));
}

({int year, int month}) _addOneMonth(int year, int month) {
  if (month == 12) return (year: year + 1, month: 1);
  return (year: year, month: month + 1);
}

/// Advance from an occurrence [bookingDate] to the next month's occurrence,
/// clamping [dayOfMonth] (e.g. 31 → 28/29 Feb). Mirrors TS
/// `advanceMonthlyBookingDate`.
String advanceMonthlyBookingDate(String bookingDate, int dayOfMonth) {
  final parsed = parseBookingDate(bookingDate);
  if (parsed == null) {
    throw ArgumentError.value(bookingDate, 'bookingDate', 'must be YYYY-MM-DD');
  }
  final next = _addOneMonth(parsed.year, parsed.month);
  return monthlyBookingDate(next.year, next.month, dayOfMonth);
}

/// First monthly occurrence of [dayOfMonth] strictly after [afterDate]
/// (`YYYY-MM-DD`). End-of-month days clamp to the last day of the month.
///
/// Mirrors `nextMonthlyBookingDateAfter` in
/// `functions/src/ledger/recurring_math.ts` — keep algorithms in sync.
String nextMonthlyBookingDate({
  required String afterDate,
  required int dayOfMonth,
}) {
  if (dayOfMonth < 1 || dayOfMonth > 31) {
    throw ArgumentError.value(dayOfMonth, 'dayOfMonth', 'must be 1–31');
  }
  final after = parseBookingDate(afterDate);
  if (after == null) {
    throw ArgumentError.value(afterDate, 'afterDate', 'must be YYYY-MM-DD');
  }

  final candidate = monthlyBookingDate(after.year, after.month, dayOfMonth);
  if (candidate.compareTo(afterDate) > 0) return candidate;
  return advanceMonthlyBookingDate(candidate, dayOfMonth);
}

/// Anchor for a new rule: after the first manual booking date and not before today.
String nextBookingDateAfterFirstOccurrence({
  required String bookingDate,
  required int dayOfMonth,
  DateTime? now,
}) {
  final today = formatBookingDate(now ?? DateTime.now());
  final afterDate = bookingDate.compareTo(today) >= 0 ? bookingDate : today;
  return nextMonthlyBookingDate(afterDate: afterDate, dayOfMonth: dayOfMonth);
}

/// Inclusive last occurrence for a fixed installment count.
///
/// [firstBookingDate] is the manually saved first payment; [totalOccurrences]
/// includes that first payment (e.g. 12 → 11 automatic posts after it).
/// Mirrors `endBookingDateForTotalOccurrences` in TS.
String endBookingDateForTotalOccurrences({
  required String firstBookingDate,
  required int dayOfMonth,
  required int totalOccurrences,
}) {
  if (totalOccurrences < 1) {
    throw ArgumentError.value(
      totalOccurrences,
      'totalOccurrences',
      'must be >= 1',
    );
  }
  var date = firstBookingDate;
  for (var i = 1; i < totalOccurrences; i++) {
    date = advanceMonthlyBookingDate(date, dayOfMonth);
  }
  return date;
}

/// Booking dates a scheduler would materialize for a due rule (pure catch-up).
///
/// Deterministic tx id shape matches Functions: `{ruleId}_{YYYY-MM-DD}`.
List<String> dueBookingDatesUntil({
  required String nextBookingDate,
  required String today,
  required int dayOfMonth,
  String? endBookingDate,
  int maxOccurrences = 36,
}) {
  var next = nextBookingDate;
  final out = <String>[];
  while (next.compareTo(today) <= 0 && out.length < maxOccurrences) {
    if (endBookingDate != null && next.compareTo(endBookingDate) > 0) break;
    out.add(next);
    next = advanceMonthlyBookingDate(next, dayOfMonth);
  }
  return out;
}
