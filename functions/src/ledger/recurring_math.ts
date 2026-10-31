/**
 * Pure date math for monthly recurring ledger rules.
 * bookingDate / nextBookingDate are civil YYYY-MM-DD strings (no TZ).
 */

const BOOKING_DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

export function parseBookingDate(
  bookingDate: string,
): {year: number; month: number; day: number} {
  const m = BOOKING_DATE_RE.exec(bookingDate);
  if (!m) {
    throw new Error(`Invalid bookingDate: ${bookingDate}`);
  }
  return {
    year: Number(m[1]),
    month: Number(m[2]),
    day: Number(m[3]),
  };
}

/** Month is 1–12. */
export function daysInCalendarMonth(year: number, month: number): number {
  // Day 0 of next month = last day of this month.
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

/** Clamp dayOfMonth (1–31) into a real calendar day for year/month. */
export function clampDayOfMonth(
  year: number,
  month: number,
  dayOfMonth: number,
): number {
  const dim = daysInCalendarMonth(year, month);
  return Math.min(dayOfMonth, dim);
}

function pad2(n: number): string {
  return n < 10 ? `0${n}` : String(n);
}

/** YYYY-MM-DD for year/month with dayOfMonth clamped to the month length. */
export function monthlyBookingDate(
  year: number,
  month: number,
  dayOfMonth: number,
): string {
  const day = clampDayOfMonth(year, month, dayOfMonth);
  return `${year}-${pad2(month)}-${pad2(day)}`;
}

function addOneMonth(
  year: number,
  month: number,
): {year: number; month: number} {
  if (month === 12) return {year: year + 1, month: 1};
  return {year, month: month + 1};
}

/**
 * Advance from an occurrence bookingDate to the next month's occurrence,
 * clamping dayOfMonth (e.g. 31 → 28/29 Feb).
 */
export function advanceMonthlyBookingDate(
  bookingDate: string,
  dayOfMonth: number,
): string {
  const {year, month} = parseBookingDate(bookingDate);
  const next = addOneMonth(year, month);
  return monthlyBookingDate(next.year, next.month, dayOfMonth);
}

/**
 * First monthly occurrence strictly after `afterDate` (YYYY-MM-DD).
 * Used when creating a rule so the manually saved tx is not duplicated.
 */
export function nextMonthlyBookingDateAfter(
  afterDate: string,
  dayOfMonth: number,
): string {
  const {year, month} = parseBookingDate(afterDate);
  const candidate = monthlyBookingDate(year, month, dayOfMonth);
  if (candidate > afterDate) return candidate;
  return advanceMonthlyBookingDate(candidate, dayOfMonth);
}

/**
 * Inclusive last occurrence for a fixed installment count.
 * `firstBookingDate` is the manually saved first payment; totalOccurrences
 * includes that first payment (e.g. 12 → 11 automatic posts after it).
 */
export function endBookingDateForTotalOccurrences(
  firstBookingDate: string,
  dayOfMonth: number,
  totalOccurrences: number,
): string {
  if (!Number.isInteger(totalOccurrences) || totalOccurrences < 1) {
    throw new Error(`totalOccurrences must be >= 1, got ${totalOccurrences}`);
  }
  let date = firstBookingDate;
  for (let i = 1; i < totalOccurrences; i++) {
    date = advanceMonthlyBookingDate(date, dayOfMonth);
  }
  return date;
}

/** Civil YYYY-MM-DD for "now" in a named IANA timezone (e.g. Europe/Rome). */
export function civilDateInTimeZone(
  timeZone: string,
  now: Date = new Date(),
): string {
  const fmt = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  return fmt.format(now);
}
