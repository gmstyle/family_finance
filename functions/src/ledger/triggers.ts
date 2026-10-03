/**
 * Firestore triggers for ledger projections, goals, and budget FCM.
 */
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {FUNCTIONS_REGION} from "../options";
import {applyGoalContributionProjection} from "./apply_goal_contribution";
import {applyTransactionProjection} from "./apply_projection";
import {notifyBudgetThresholds} from "./budget_fcm";

const db = () => getFirestore();

/**
 * Create / update / delete on transactions → idempotent projection apply.
 * On first-time 80%/100% budget threshold flips, notify member devices once.
 */
export const onTransactionWritten = onDocumentWritten(
  {
    document: "families/{familyId}/transactions/{transactionId}",
    region: FUNCTIONS_REGION,
  },
  async (event) => {
    const familyId = event.params.familyId as string;
    const transactionId = event.params.transactionId as string;
    const after = event.data?.after;
    const newData = after?.exists ? after.data() : null;

    try {
      const result = await applyTransactionProjection(
        db(),
        familyId,
        transactionId,
        newData,
      );
      if (result.applied && result.crossings.length > 0) {
        await notifyBudgetThresholds(db(), familyId, result.crossings);
      }
    } catch (err) {
      logger.error("onTransactionWritten failed", {
        familyId,
        transactionId,
        err,
      });
      throw err;
    }
  },
);

/**
 * Account create: seed `balanceMinor` from opening.
 * Opening update: apply delta only to `balanceMinor`.
 */
export const onAccountWritten = onDocumentWritten(
  {
    document: "families/{familyId}/accounts/{accountId}",
    region: FUNCTIONS_REGION,
  },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    const before = event.data?.before;
    const afterData = after.data()!;
    const opening = afterData.openingBalanceMinor as number | undefined;
    if (typeof opening !== "number") return;

    if (!before?.exists) {
      if (afterData.balanceMinor === undefined) {
        await after.ref.update({balanceMinor: opening});
      }
      return;
    }

    const beforeData = before.data()!;
    const oldOpening = beforeData.openingBalanceMinor as number | undefined;
    if (typeof oldOpening !== "number" || oldOpening === opening) {
      return;
    }

    const delta = opening - oldOpening;
    if (delta === 0) return;

    await after.ref.update({
      balanceMinor: FieldValue.increment(delta),
    });
  },
);

/**
 * Goal contribution create/delete → idempotent `accumulatedAmountMinor`.
 * Virtual goals: never touches account balances.
 */
export const onGoalContributionWritten = onDocumentWritten(
  {
    document:
      "families/{familyId}/goals/{goalId}/contributions/{contributionId}",
    region: FUNCTIONS_REGION,
  },
  async (event) => {
    const familyId = event.params.familyId as string;
    const goalId = event.params.goalId as string;
    const contributionId = event.params.contributionId as string;
    const after = event.data?.after;
    const newData = after?.exists ? after.data() : null;

    try {
      await applyGoalContributionProjection(
        db(),
        familyId,
        goalId,
        contributionId,
        newData,
      );
    } catch (err) {
      logger.error("onGoalContributionWritten failed", {
        familyId,
        goalId,
        contributionId,
        err,
      });
      throw err;
    }
  },
);
