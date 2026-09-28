/**
 * Pure projection math — unit-tested, no Firestore I/O.
 */
import {DocumentData} from "firebase-admin/firestore";

import {
  StatsDelta,
  TransactionImage,
  TransferRole,
  TxType,
} from "./types";

const TX_TYPES: ReadonlySet<string> = new Set([
  "expense",
  "income",
  "refund",
  "transfer",
]);

/** `YYYY-MM` from `YYYY-MM-DD` bookingDate. */
export function periodFromBookingDate(bookingDate: string): string {
  if (bookingDate.length < 7) {
    throw new Error(`Invalid bookingDate: ${bookingDate}`);
  }
  return bookingDate.slice(0, 7);
}

/** Signed effect on `accounts.balanceMinor`. */
export function balanceDelta(image: TransactionImage): number {
  const {type, amountMinor, transferRole} = image;
  if (type === "expense") return -amountMinor;
  if (type === "income" || type === "refund") return amountMinor;
  if (type === "transfer") {
    if (transferRole === "source") return -amountMinor;
    if (transferRole === "destination") return amountMinor;
  }
  return 0;
}

/**
 * Effect on budget period `spentAmountMinor` for expense categories.
 * Expense +, refund −; transfer/income 0. Caller skips when no categoryId.
 */
export function budgetSpentDelta(image: TransactionImage): number {
  if (!image.categoryId) return 0;
  if (image.type === "expense") return image.amountMinor;
  if (image.type === "refund") return -image.amountMinor;
  return 0;
}

/** Stats rollup delta; transfers excluded. Refunds reduce expense totals. */
export function statsDelta(image: TransactionImage): StatsDelta | null {
  if (image.type === "transfer") return null;

  const period = periodFromBookingDate(image.bookingDate);
  const delta: StatsDelta = {
    period,
    incomeByCategory: {},
    expenseByCategory: {},
    incomeByAccount: {},
    expenseByAccount: {},
    totalIncomeMinor: 0,
    totalExpenseMinor: 0,
  };

  if (image.type === "income") {
    if (image.categoryId) {
      delta.incomeByCategory[image.categoryId] = image.amountMinor;
    }
    delta.incomeByAccount[image.accountId] = image.amountMinor;
    delta.totalIncomeMinor = image.amountMinor;
  } else if (image.type === "expense") {
    if (image.categoryId) {
      delta.expenseByCategory[image.categoryId] = image.amountMinor;
    }
    delta.expenseByAccount[image.accountId] = image.amountMinor;
    delta.totalExpenseMinor = image.amountMinor;
  } else if (image.type === "refund") {
    if (image.categoryId) {
      delta.expenseByCategory[image.categoryId] = -image.amountMinor;
    }
    delta.expenseByAccount[image.accountId] = -image.amountMinor;
    delta.totalExpenseMinor = -image.amountMinor;
  }

  return delta;
}

/** Multiply all numeric fields by `sign` (−1 undoes an apply). */
export function scaleStatsDelta(delta: StatsDelta, sign: 1 | -1): StatsDelta {
  const scaleMap = (m: Record<string, number>): Record<string, number> => {
    const out: Record<string, number> = {};
    for (const [k, v] of Object.entries(m)) {
      out[k] = v * sign;
    }
    return out;
  };
  return {
    period: delta.period,
    incomeByCategory: scaleMap(delta.incomeByCategory),
    expenseByCategory: scaleMap(delta.expenseByCategory),
    incomeByAccount: scaleMap(delta.incomeByAccount),
    expenseByAccount: scaleMap(delta.expenseByAccount),
    totalIncomeMinor: delta.totalIncomeMinor * sign,
    totalExpenseMinor: delta.totalExpenseMinor * sign,
  };
}

export function imagesEqual(
  a: TransactionImage | null,
  b: TransactionImage | null,
): boolean {
  if (a === null && b === null) return true;
  if (a === null || b === null) return false;
  return (
    a.type === b.type &&
    a.accountId === b.accountId &&
    a.categoryId === b.categoryId &&
    a.amountMinor === b.amountMinor &&
    a.bookingDate === b.bookingDate &&
    a.transferId === b.transferId &&
    a.transferRole === b.transferRole
  );
}

/**
 * First-time threshold crossings (flags are never cleared).
 * Returns which notifications to send and which flags to set.
 */
export function thresholdUpdates(
  spentAmountMinor: number,
  limitAmountMinor: number,
  threshold80Notified: boolean,
  threshold100Notified: boolean,
): {
  set80: boolean;
  set100: boolean;
  crossed80: boolean;
  crossed100: boolean;
} {
  const hit80 =
    limitAmountMinor > 0 && spentAmountMinor >= limitAmountMinor * 0.8;
  const hit100 =
    limitAmountMinor > 0 && spentAmountMinor >= limitAmountMinor;
  const crossed80 = hit80 && !threshold80Notified;
  const crossed100 = hit100 && !threshold100Notified;
  return {
    set80: threshold80Notified || hit80,
    set100: threshold100Notified || hit100,
    crossed80,
    crossed100,
  };
}

/** Parse a Firestore transaction doc into a projection image, or null if unusable. */
export function extractImage(
  data: DocumentData | undefined | null,
): TransactionImage | null {
  if (!data) return null;

  const type = data.type as string | undefined;
  if (!type || !TX_TYPES.has(type)) return null;

  const accountId = data.accountId as string | undefined;
  if (!accountId || typeof accountId !== "string") return null;

  const amountMinor = data.amountMinor as number | undefined;
  if (typeof amountMinor !== "number" || !Number.isInteger(amountMinor) || amountMinor <= 0) {
    return null;
  }

  const bookingDate = data.bookingDate as string | undefined;
  if (!bookingDate || !/^\d{4}-\d{2}-\d{2}$/.test(bookingDate)) return null;

  const rawCategory = data.categoryId;
  const categoryId =
    rawCategory === undefined || rawCategory === null || rawCategory === ""
      ? null
      : String(rawCategory);

  const rawTransferId = data.transferId;
  const transferId =
    rawTransferId === undefined || rawTransferId === null || rawTransferId === ""
      ? null
      : String(rawTransferId);

  const rawRole = data.transferRole as string | undefined | null;
  let transferRole: TransferRole | null = null;
  if (rawRole === "source" || rawRole === "destination") {
    transferRole = rawRole;
  }

  if (type === "transfer") {
    if (!transferId || !transferRole) return null;
    if (categoryId !== null) return null;
  }

  return {
    type: type as TxType,
    accountId,
    categoryId,
    amountMinor,
    bookingDate,
    transferId,
    transferRole,
  };
}

/** Plain object suitable for writing to `_projections`. */
export function imageToProjectionDoc(image: TransactionImage): TransactionImage {
  return {...image};
}
