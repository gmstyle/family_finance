/**
 * Apply / undo transaction projections inside a Firestore transaction
 * via `_projections/{transactionId}` for idempotency.
 *
 * Firestore requires all reads before any writes in a transaction.
 */
import {
  DocumentData,
  DocumentReference,
  FieldValue,
  Firestore,
  Transaction,
} from "firebase-admin/firestore";

import {
  balanceDelta,
  budgetSpentDelta,
  extractImage,
  imageToProjectionDoc,
  imagesEqual,
  periodFromBookingDate,
  scaleStatsDelta,
  statsDelta,
  thresholdUpdates,
} from "./projection_math";
import {StatsDelta, ThresholdCrossing, TransactionImage} from "./types";

export interface ApplyResult {
  applied: boolean;
  crossings: ThresholdCrossing[];
}

interface BudgetPeriodPlan {
  budgetId: string;
  periodRef: DocumentReference;
  periodId: string;
  limitAmountMinor: number;
  prev80: boolean;
  prev100: boolean;
  nextSpent: number;
}

interface MutationPlan {
  accountIncrements: Map<string, number>;
  budgetPeriods: Map<string, BudgetPeriodPlan>;
  /** periodId → numeric field increments (converted to FieldValue at write). */
  statsNumeric: Map<string, Record<string, number>>;
}

function emptyPlan(): MutationPlan {
  return {
    accountIncrements: new Map(),
    budgetPeriods: new Map(),
    statsNumeric: new Map(),
  };
}

function addAccountDelta(
  plan: MutationPlan,
  accountId: string,
  delta: number,
): void {
  plan.accountIncrements.set(
    accountId,
    (plan.accountIncrements.get(accountId) ?? 0) + delta,
  );
}

function mergeStatsNumeric(plan: MutationPlan, delta: StatsDelta): void {
  let patch = plan.statsNumeric.get(delta.period);
  if (!patch) {
    patch = {};
    plan.statsNumeric.set(delta.period, patch);
  }
  const add = (key: string, value: number) => {
    if (value === 0) return;
    patch![key] = (patch![key] ?? 0) + value;
  };
  add("totalIncomeMinor", delta.totalIncomeMinor);
  add("totalExpenseMinor", delta.totalExpenseMinor);
  for (const [id, v] of Object.entries(delta.incomeByCategory)) {
    add(`incomeByCategory.${id}`, v);
  }
  for (const [id, v] of Object.entries(delta.expenseByCategory)) {
    add(`expenseByCategory.${id}`, v);
  }
  for (const [id, v] of Object.entries(delta.incomeByAccount)) {
    add(`incomeByAccount.${id}`, v);
  }
  for (const [id, v] of Object.entries(delta.expenseByAccount)) {
    add(`expenseByAccount.${id}`, v);
  }
}

/**
 * Idempotent projection: undo previous image, apply new.
 * No-op when images are identical.
 */
export async function applyTransactionProjection(
  db: Firestore,
  familyId: string,
  transactionId: string,
  newData: DocumentData | undefined | null,
): Promise<ApplyResult> {
  const familyRef = db.collection("families").doc(familyId);
  const projectionRef = familyRef.collection("_projections").doc(transactionId);
  const desired = extractImage(newData ?? undefined);

  return db.runTransaction(async (tx) => {
    const projSnap = await tx.get(projectionRef);
    const previous = projSnap.exists
      ? extractImage(projSnap.data() as DocumentData)
      : null;

    if (imagesEqual(previous, desired)) {
      return {applied: false, crossings: []};
    }

    const plan = emptyPlan();

    // --- ALL READS ---
    const accountIds = new Set<string>();
    if (previous) accountIds.add(previous.accountId);
    if (desired) accountIds.add(desired.accountId);
    const existingAccounts = new Set<string>();
    for (const accountId of accountIds) {
      const snap = await tx.get(
        familyRef.collection("accounts").doc(accountId),
      );
      if (snap.exists) existingAccounts.add(accountId);
    }

    if (previous) {
      await collectImageEffects(tx, familyRef, previous, -1, plan);
    }
    if (desired) {
      await collectImageEffects(tx, familyRef, desired, 1, plan);
    }

    // --- ALL WRITES ---
    for (const [accountId, delta] of plan.accountIncrements) {
      if (delta === 0 || !existingAccounts.has(accountId)) continue;
      const accountRef = familyRef.collection("accounts").doc(accountId);
      tx.update(accountRef, {
        balanceMinor: FieldValue.increment(delta),
      });
    }

    const crossings: ThresholdCrossing[] = [];
    for (const bp of plan.budgetPeriods.values()) {
      const flags = thresholdUpdates(
        bp.nextSpent,
        bp.limitAmountMinor,
        bp.prev80,
        bp.prev100,
      );
      tx.set(
        bp.periodRef,
        {
          spentAmountMinor: bp.nextSpent,
          threshold80Notified: flags.set80,
          threshold100Notified: flags.set100,
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      if (flags.crossed80 || flags.crossed100) {
        crossings.push({
          budgetId: bp.budgetId,
          periodId: bp.periodId,
          crossed80: flags.crossed80,
          crossed100: flags.crossed100,
        });
      }
    }

    for (const [periodId, numeric] of plan.statsNumeric) {
      const patch: Record<string, unknown> = {
        updatedAt: FieldValue.serverTimestamp(),
      };
      let hasInc = false;
      for (const [k, v] of Object.entries(numeric)) {
        if (v !== 0) {
          patch[k] = FieldValue.increment(v);
          hasInc = true;
        }
      }
      if (hasInc) {
        tx.set(familyRef.collection("stats").doc(periodId), patch, {
          merge: true,
        });
      }
    }

    if (desired) {
      tx.set(projectionRef, {
        ...imageToProjectionDoc(desired),
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else if (projSnap.exists) {
      tx.delete(projectionRef);
    }

    return {applied: true, crossings};
  });
}

async function collectImageEffects(
  tx: Transaction,
  familyRef: DocumentReference,
  image: TransactionImage,
  sign: 1 | -1,
  plan: MutationPlan,
): Promise<void> {
  addAccountDelta(plan, image.accountId, balanceDelta(image) * sign);

  const spentDelta = budgetSpentDelta(image) * sign;
  if (spentDelta !== 0 && image.categoryId) {
    await collectBudgetSpent(
      tx,
      familyRef,
      image.categoryId,
      periodFromBookingDate(image.bookingDate),
      spentDelta,
      plan,
    );
  }

  const baseStats = statsDelta(image);
  if (baseStats) {
    mergeStatsNumeric(plan, scaleStatsDelta(baseStats, sign));
  }
}

async function collectBudgetSpent(
  tx: Transaction,
  familyRef: DocumentReference,
  categoryId: string,
  periodId: string,
  spentDelta: number,
  plan: MutationPlan,
): Promise<void> {
  const budgetsSnap = await tx.get(
    familyRef.collection("budgets").where("categoryId", "==", categoryId),
  );

  for (const budgetDoc of budgetsSnap.docs) {
    const key = `${budgetDoc.id}/${periodId}`;
    const existing = plan.budgetPeriods.get(key);
    if (existing) {
      existing.nextSpent += spentDelta;
      continue;
    }

    const periodRef = budgetDoc.ref.collection("periods").doc(periodId);
    const periodSnap = await tx.get(periodRef);
    const limitAmountMinor =
      (budgetDoc.data().limitAmountMinor as number) ?? 0;
    const prevSpent = periodSnap.exists
      ? ((periodSnap.data()?.spentAmountMinor as number) ?? 0)
      : 0;
    const prev80 = periodSnap.exists
      ? Boolean(periodSnap.data()?.threshold80Notified)
      : false;
    const prev100 = periodSnap.exists
      ? Boolean(periodSnap.data()?.threshold100Notified)
      : false;

    plan.budgetPeriods.set(key, {
      budgetId: budgetDoc.id,
      periodRef,
      periodId,
      limitAmountMinor,
      prev80,
      prev100,
      nextSpent: prevSpent + spentDelta,
    });
  }
}
