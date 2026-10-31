/**
 * Daily materialization of monthly recurring expense/income rules.
 * Writes confirmed ledger txs (Admin SDK) so balance/budget triggers apply.
 */
import {
  DocumentData,
  FieldValue,
  getFirestore,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onSchedule} from "firebase-functions/v2/scheduler";

import {FUNCTIONS_REGION} from "../options";
import {
  advanceMonthlyBookingDate,
  civilDateInTimeZone,
} from "./recurring_math";

const db = () => getFirestore();

const TIME_ZONE = "Europe/Rome";
/** Catch-up safety: ~3 years of monthly occurrences per rule per run. */
const MAX_OCCURRENCES_PER_RULE = 36;

type RecurringRuleData = {
  type: "expense" | "income";
  accountId: string;
  categoryId: string;
  amountMinor: number;
  currency: string;
  merchant?: string | null;
  note?: string | null;
  dayOfMonth: number;
  active: boolean;
  nextBookingDate: string;
  /** Inclusive last allowed occurrence; null = open-ended. */
  endBookingDate: string | null;
  createdByUserId: string;
};

function readRule(data: DocumentData): RecurringRuleData | null {
  const type = data.type;
  if (type !== "expense" && type !== "income") return null;
  const accountId = data.accountId;
  const categoryId = data.categoryId;
  const currency = data.currency;
  const createdByUserId = data.createdByUserId;
  const nextBookingDate = data.nextBookingDate;
  const dayOfMonth = data.dayOfMonth;
  const amountMinor = data.amountMinor;
  const endRaw = data.endBookingDate;
  const endBookingDate =
    endRaw === undefined || endRaw === null
      ? null
      : typeof endRaw === "string"
        ? endRaw
        : null;
  if (
    typeof accountId !== "string" ||
    typeof categoryId !== "string" ||
    typeof currency !== "string" ||
    typeof createdByUserId !== "string" ||
    typeof nextBookingDate !== "string" ||
    typeof dayOfMonth !== "number" ||
    !Number.isInteger(dayOfMonth) ||
    dayOfMonth < 1 ||
    dayOfMonth > 31 ||
    typeof amountMinor !== "number" ||
    !Number.isInteger(amountMinor) ||
    amountMinor <= 0 ||
    (endRaw !== undefined && endRaw !== null && typeof endRaw !== "string")
  ) {
    return null;
  }
  return {
    type,
    accountId,
    categoryId,
    amountMinor,
    currency,
    merchant: data.merchant ?? null,
    note: data.note ?? null,
    dayOfMonth,
    active: data.active === true,
    nextBookingDate,
    endBookingDate,
    createdByUserId,
  };
}

async function materializeRule(
  doc: QueryDocumentSnapshot,
  today: string,
): Promise<number> {
  const familyRef = doc.ref.parent.parent;
  if (!familyRef) {
    logger.warn("recurringRules doc missing family parent", {path: doc.ref.path});
    return 0;
  }

  const rule = readRule(doc.data());
  if (!rule || !rule.active) return 0;

  let next = rule.nextBookingDate;
  let written = 0;
  const end = rule.endBookingDate;

  if (end && next > end) {
    await doc.ref.update({
      active: false,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return 0;
  }

  while (next <= today && written < MAX_OCCURRENCES_PER_RULE) {
    if (end && next > end) {
      await doc.ref.update({
        active: false,
        nextBookingDate: next,
        updatedAt: FieldValue.serverTimestamp(),
      });
      break;
    }

    const bookingDate = next;
    const txId = `${doc.id}_${bookingDate}`;
    const txRef = familyRef.collection("transactions").doc(txId);
    const now = FieldValue.serverTimestamp();

    const payload: Record<string, unknown> = {
      type: rule.type,
      accountId: rule.accountId,
      categoryId: rule.categoryId,
      amountMinor: rule.amountMinor,
      currency: rule.currency,
      bookingDate,
      createdByUserId: rule.createdByUserId,
      recurringRuleId: doc.id,
      createdAt: now,
      updatedAt: now,
    };
    if (typeof rule.merchant === "string" && rule.merchant.trim()) {
      payload.merchant = rule.merchant.trim();
    }
    if (typeof rule.note === "string" && rule.note.trim()) {
      payload.note = rule.note.trim();
    }

    // Deterministic id → safe retry; identical rewrite is a projection no-op.
    await txRef.set(payload);

    next = advanceMonthlyBookingDate(bookingDate, rule.dayOfMonth);
    const patch: Record<string, unknown> = {
      nextBookingDate: next,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (end && next > end) {
      patch.active = false;
    }
    await doc.ref.update(patch);
    written += 1;
    if (end && next > end) break;
  }

  if (next <= today && !(end && next > end)) {
    logger.warn("recurring rule hit catch-up cap", {
      path: doc.ref.path,
      nextBookingDate: next,
      today,
      written,
    });
  }

  return written;
}

/**
 * Daily cron (03:00 Europe/Rome): materialize due monthly recurring rules
 * into confirmed ledger transactions.
 */
export const materializeRecurringTransactions = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: TIME_ZONE,
    region: FUNCTIONS_REGION,
  },
  async () => {
    const today = civilDateInTimeZone(TIME_ZONE);
    const snap = await db()
      .collectionGroup("recurringRules")
      .where("active", "==", true)
      .where("nextBookingDate", "<=", today)
      .get();

    let totalWritten = 0;
    for (const doc of snap.docs) {
      try {
        totalWritten += await materializeRule(doc, today);
      } catch (err) {
        logger.error("failed to materialize recurring rule", {
          path: doc.ref.path,
          err,
        });
      }
    }

    logger.info("materializeRecurringTransactions done", {
      today,
      rulesDue: snap.size,
      transactionsWritten: totalWritten,
    });
  },
);
