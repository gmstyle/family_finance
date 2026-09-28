/**
 * Unit tests for projection math / idempotency (Node built-in test runner).
 * Run: npm test  (builds then node --test)
 */
import assert from "node:assert/strict";
import {describe, it} from "node:test";

import {
  balanceDelta,
  budgetSpentDelta,
  extractImage,
  imagesEqual,
  periodFromBookingDate,
  scaleStatsDelta,
  statsDelta,
  thresholdUpdates,
} from "./projection_math";
import {TransactionImage} from "./types";

function expense(partial: Partial<TransactionImage> = {}): TransactionImage {
  return {
    type: "expense",
    accountId: "acc1",
    categoryId: "cat1",
    amountMinor: 1000,
    bookingDate: "2026-03-15",
    transferId: null,
    transferRole: null,
    ...partial,
  };
}

describe("periodFromBookingDate", () => {
  it("extracts yyyy-MM", () => {
    assert.equal(periodFromBookingDate("2026-03-15"), "2026-03");
  });
});

describe("balanceDelta", () => {
  it("expense subtracts", () => {
    assert.equal(balanceDelta(expense()), -1000);
  });
  it("income and refund add", () => {
    assert.equal(balanceDelta(expense({type: "income", categoryId: "inc"})), 1000);
    assert.equal(balanceDelta(expense({type: "refund"})), 1000);
  });
  it("transfer source/destination", () => {
    assert.equal(
      balanceDelta(
        expense({
          type: "transfer",
          categoryId: null,
          transferId: "t1",
          transferRole: "source",
        }),
      ),
      -1000,
    );
    assert.equal(
      balanceDelta(
        expense({
          type: "transfer",
          categoryId: null,
          transferId: "t1",
          transferRole: "destination",
        }),
      ),
      1000,
    );
  });
});

describe("budgetSpentDelta", () => {
  it("expense +, refund −, transfer/income 0", () => {
    assert.equal(budgetSpentDelta(expense()), 1000);
    assert.equal(budgetSpentDelta(expense({type: "refund"})), -1000);
    assert.equal(budgetSpentDelta(expense({type: "income"})), 0);
    assert.equal(
      budgetSpentDelta(
        expense({
          type: "transfer",
          categoryId: null,
          transferId: "t1",
          transferRole: "source",
        }),
      ),
      0,
    );
  });
  it("no category → 0", () => {
    assert.equal(budgetSpentDelta(expense({categoryId: null})), 0);
  });
});

describe("statsDelta", () => {
  it("excludes transfers", () => {
    assert.equal(
      statsDelta(
        expense({
          type: "transfer",
          categoryId: null,
          transferId: "t1",
          transferRole: "source",
        }),
      ),
      null,
    );
  });
  it("expense and income buckets", () => {
    const e = statsDelta(expense())!;
    assert.equal(e.period, "2026-03");
    assert.equal(e.totalExpenseMinor, 1000);
    assert.equal(e.expenseByCategory.cat1, 1000);
    assert.equal(e.expenseByAccount.acc1, 1000);
    assert.equal(e.totalIncomeMinor, 0);

    const i = statsDelta(expense({type: "income", categoryId: "salary"}))!;
    assert.equal(i.totalIncomeMinor, 1000);
    assert.equal(i.incomeByCategory.salary, 1000);
  });
  it("refund reduces expense totals", () => {
    const r = statsDelta(expense({type: "refund"}))!;
    assert.equal(r.totalExpenseMinor, -1000);
    assert.equal(r.expenseByCategory.cat1, -1000);
  });
});

describe("scaleStatsDelta", () => {
  it("negates for undo", () => {
    const base = statsDelta(expense())!;
    const undone = scaleStatsDelta(base, -1);
    assert.equal(undone.totalExpenseMinor, -1000);
    assert.equal(undone.expenseByCategory.cat1, -1000);
  });
});

describe("imagesEqual / idempotency", () => {
  it("identical images are equal", () => {
    const a = expense();
    const b = expense();
    assert.equal(imagesEqual(a, b), true);
  });
  it("note-irrelevant: only projection fields matter", () => {
    const a = expense({amountMinor: 500});
    const b = expense({amountMinor: 500});
    assert.equal(imagesEqual(a, b), true);
    assert.equal(imagesEqual(a, expense({amountMinor: 501})), false);
  });
  it("null equals null; null ≠ image", () => {
    assert.equal(imagesEqual(null, null), true);
    assert.equal(imagesEqual(null, expense()), false);
  });
  it("undo+apply net for amount change", () => {
    const oldImg = expense({amountMinor: 1000});
    const newImg = expense({amountMinor: 1500});
    const netBalance =
      balanceDelta(oldImg) * -1 + balanceDelta(newImg);
    assert.equal(netBalance, -500);
    const netSpent =
      budgetSpentDelta(oldImg) * -1 + budgetSpentDelta(newImg);
    assert.equal(netSpent, 500);
  });
  it("delete undoes full effect", () => {
    const img = expense();
    assert.equal(balanceDelta(img) * -1, 1000);
    assert.equal(budgetSpentDelta(img) * -1, -1000);
  });
});

describe("thresholdUpdates", () => {
  it("crosses 80 and 100 once", () => {
    const first = thresholdUpdates(800, 1000, false, false);
    assert.equal(first.crossed80, true);
    assert.equal(first.crossed100, false);
    assert.equal(first.set80, true);

    const again = thresholdUpdates(850, 1000, true, false);
    assert.equal(again.crossed80, false);
    assert.equal(again.set80, true);

    const full = thresholdUpdates(1000, 1000, true, false);
    assert.equal(full.crossed100, true);
    assert.equal(full.set100, true);

    const sticky = thresholdUpdates(500, 1000, true, true);
    assert.equal(sticky.crossed80, false);
    assert.equal(sticky.crossed100, false);
    assert.equal(sticky.set80, true);
    assert.equal(sticky.set100, true);
  });
});

describe("extractImage", () => {
  it("parses valid expense", () => {
    const img = extractImage({
      type: "expense",
      accountId: "a",
      categoryId: "c",
      amountMinor: 42,
      bookingDate: "2026-01-02",
    });
    assert.deepEqual(img, {
      type: "expense",
      accountId: "a",
      categoryId: "c",
      amountMinor: 42,
      bookingDate: "2026-01-02",
      transferId: null,
      transferRole: null,
    });
  });
  it("rejects transfer without roles / with category", () => {
    assert.equal(
      extractImage({
        type: "transfer",
        accountId: "a",
        amountMinor: 10,
        bookingDate: "2026-01-02",
        transferId: "t",
        categoryId: "c",
        transferRole: "source",
      }),
      null,
    );
    assert.equal(
      extractImage({
        type: "transfer",
        accountId: "a",
        amountMinor: 10,
        bookingDate: "2026-01-02",
      }),
      null,
    );
  });
  it("ignores note/merchant for equality via extract", () => {
    const a = extractImage({
      type: "income",
      accountId: "a",
      categoryId: "c",
      amountMinor: 1,
      bookingDate: "2026-01-02",
      note: "hello",
    });
    const b = extractImage({
      type: "income",
      accountId: "a",
      categoryId: "c",
      amountMinor: 1,
      bookingDate: "2026-01-02",
      note: "world",
      merchant: "x",
    });
    assert.equal(imagesEqual(a, b), true);
  });
});
