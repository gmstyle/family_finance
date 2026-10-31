/**
 * Unit tests for monthly recurring date math (Node built-in test runner).
 * Run: npm test  (builds then node --test)
 */
import assert from "node:assert/strict";
import {describe, it} from "node:test";

import {
  advanceMonthlyBookingDate,
  clampDayOfMonth,
  daysInCalendarMonth,
  endBookingDateForTotalOccurrences,
  monthlyBookingDate,
  nextMonthlyBookingDateAfter,
  parseBookingDate,
} from "./recurring_math";

describe("daysInCalendarMonth / clampDayOfMonth", () => {
  it("knows 30/31-day months", () => {
    assert.equal(daysInCalendarMonth(2026, 1), 31);
    assert.equal(daysInCalendarMonth(2026, 4), 30);
    assert.equal(daysInCalendarMonth(2026, 2), 28);
    assert.equal(daysInCalendarMonth(2024, 2), 29);
  });

  it("clamps dayOfMonth to month length", () => {
    assert.equal(clampDayOfMonth(2026, 1, 31), 31);
    assert.equal(clampDayOfMonth(2026, 2, 31), 28);
    assert.equal(clampDayOfMonth(2024, 2, 31), 29);
    assert.equal(clampDayOfMonth(2026, 4, 31), 30);
    assert.equal(clampDayOfMonth(2026, 3, 15), 15);
  });
});

describe("monthlyBookingDate", () => {
  it("formats and clamps", () => {
    assert.equal(monthlyBookingDate(2026, 1, 31), "2026-01-31");
    assert.equal(monthlyBookingDate(2026, 2, 31), "2026-02-28");
    assert.equal(monthlyBookingDate(2024, 2, 31), "2024-02-29");
    assert.equal(monthlyBookingDate(2026, 3, 5), "2026-03-05");
  });
});

describe("advanceMonthlyBookingDate", () => {
  it("advances mid-month", () => {
    assert.equal(advanceMonthlyBookingDate("2026-03-15", 15), "2026-04-15");
  });

  it("clamps end-of-month across Feb", () => {
    assert.equal(advanceMonthlyBookingDate("2026-01-31", 31), "2026-02-28");
    assert.equal(advanceMonthlyBookingDate("2024-01-31", 31), "2024-02-29");
    assert.equal(advanceMonthlyBookingDate("2026-02-28", 31), "2026-03-31");
    assert.equal(advanceMonthlyBookingDate("2024-02-29", 31), "2024-03-31");
  });

  it("rolls year", () => {
    assert.equal(advanceMonthlyBookingDate("2026-12-10", 10), "2027-01-10");
    assert.equal(advanceMonthlyBookingDate("2026-12-31", 31), "2027-01-31");
  });

  it("keeps preferred day when month allows", () => {
    assert.equal(advanceMonthlyBookingDate("2026-02-28", 28), "2026-03-28");
  });
});

describe("nextMonthlyBookingDateAfter", () => {
  it("same day-of-month → next month (avoid duplicate manual post)", () => {
    assert.equal(nextMonthlyBookingDateAfter("2026-03-15", 15), "2026-04-15");
  });

  it("later day this month", () => {
    assert.equal(nextMonthlyBookingDateAfter("2026-03-15", 20), "2026-03-20");
  });

  it("earlier day → next month", () => {
    assert.equal(nextMonthlyBookingDateAfter("2026-03-15", 10), "2026-04-10");
  });

  it("clamps when next candidate is end-of-month", () => {
    assert.equal(nextMonthlyBookingDateAfter("2026-01-31", 31), "2026-02-28");
    assert.equal(nextMonthlyBookingDateAfter("2026-01-30", 31), "2026-01-31");
    assert.equal(nextMonthlyBookingDateAfter("2026-02-28", 31), "2026-03-31");
  });
});

describe("parseBookingDate", () => {
  it("parses YYYY-MM-DD", () => {
    assert.deepEqual(parseBookingDate("2026-02-28"), {
      year: 2026,
      month: 2,
      day: 28,
    });
  });

  it("rejects invalid", () => {
    assert.throws(() => parseBookingDate("2026-2-28"));
    assert.throws(() => parseBookingDate("not-a-date"));
  });
});

/** Pure catch-up loop matching materializeRule in recurring.ts. */
function dueBookingDatesUntil(
  nextBookingDate: string,
  today: string,
  dayOfMonth: number,
  endBookingDate?: string | null,
  maxOccurrences = 36,
): string[] {
  let next = nextBookingDate;
  const out: string[] = [];
  while (next <= today && out.length < maxOccurrences) {
    if (endBookingDate && next > endBookingDate) break;
    out.push(next);
    next = advanceMonthlyBookingDate(next, dayOfMonth);
  }
  return out;
}

describe("endBookingDateForTotalOccurrences", () => {
  it("counts the first payment as occurrence 1", () => {
    assert.equal(
      endBookingDateForTotalOccurrences("2026-03-20", 20, 1),
      "2026-03-20",
    );
    assert.equal(
      endBookingDateForTotalOccurrences("2026-03-20", 20, 12),
      "2027-02-20",
    );
  });

  it("clamps end-of-month across the series", () => {
    assert.equal(
      endBookingDateForTotalOccurrences("2026-01-31", 31, 3),
      "2026-03-31",
    );
  });
});

describe("dueBookingDatesUntil (materialize catch-up)", () => {
  it("writes due months with end-of-month clamp", () => {
    const dates = dueBookingDatesUntil("2026-01-31", "2026-03-15", 31);
    assert.deepEqual(dates, ["2026-01-31", "2026-02-28"]);
    assert.equal(advanceMonthlyBookingDate(dates[dates.length - 1], 31), "2026-03-31");
  });

  it("stops at inclusive endBookingDate", () => {
    const dates = dueBookingDatesUntil(
      "2026-01-20",
      "2026-06-01",
      20,
      "2026-03-20",
    );
    assert.deepEqual(dates, ["2026-01-20", "2026-02-20", "2026-03-20"]);
  });

  it("deterministic tx id shape", () => {
    const ruleId = "abc123";
    const dates = dueBookingDatesUntil("2026-04-01", "2026-04-01", 1);
    assert.deepEqual(dates, ["2026-04-01"]);
    assert.equal(`${ruleId}_${dates[0]}`, "abc123_2026-04-01");
  });
});
