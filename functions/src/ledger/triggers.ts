/**
 * Firestore triggers for ledger projections.
 */
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {logger} from "firebase-functions";
import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {FUNCTIONS_REGION} from "../options";
import {applyTransactionProjection} from "./apply_projection";
import {ThresholdCrossing} from "./types";

const db = () => getFirestore();

/**
 * Create / update / delete on transactions → idempotent projection apply.
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
        await maybeNotifyBudgetThresholds(familyId, result.crossings);
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

/** Best-effort FCM when devices exist; flags already persisted by projection. */
async function maybeNotifyBudgetThresholds(
  familyId: string,
  crossings: ThresholdCrossing[],
): Promise<void> {
  try {
    const members = await db()
      .collection("families")
      .doc(familyId)
      .collection("members")
      .get();
    const tokens: string[] = [];
    for (const member of members.docs) {
      const devices = await db()
        .collection("users")
        .doc(member.id)
        .collection("devices")
        .get();
      for (const device of devices.docs) {
        const token = device.data().token as string | undefined;
        if (token) tokens.push(token);
      }
    }
    if (tokens.length === 0) return;

    for (const crossing of crossings) {
      const parts: string[] = [];
      if (crossing.crossed80) parts.push("80%");
      if (crossing.crossed100) parts.push("100%");
      if (parts.length === 0) continue;

      await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "Budget alert",
          body: `Budget reached ${parts.join(" / ")} for ${crossing.periodId}.`,
        },
        data: {
          type: "budget_threshold",
          familyId,
          budgetId: crossing.budgetId,
          periodId: crossing.periodId,
        },
      });
    }
  } catch (err) {
    // Phase 4 owns full FCM; never fail the projection over notify.
    logger.warn("Budget threshold FCM skipped", {familyId, err});
  }
}
