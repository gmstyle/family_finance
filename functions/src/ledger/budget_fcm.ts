/**
 * Budget threshold FCM send path.
 * Flags are already sticky on the period; this only notifies member devices
 * when crossings are reported by the projection apply.
 */
import {Firestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {logger} from "firebase-functions";

import {
  budgetThresholdDataPayload,
  budgetThresholdNotificationBody,
  chunkTokens,
} from "./budget_fcm_math";
import {ThresholdCrossing} from "./types";

/** Collect FCM tokens from `users/{uid}/devices` for all family members. */
export async function collectMemberDeviceTokens(
  db: Firestore,
  familyId: string,
): Promise<string[]> {
  const members = await db
    .collection("families")
    .doc(familyId)
    .collection("members")
    .get();

  const tokens: string[] = [];
  const seen = new Set<string>();

  for (const member of members.docs) {
    const devices = await db
      .collection("users")
      .doc(member.id)
      .collection("devices")
      .get();
    for (const device of devices.docs) {
      const token = device.data().token as string | undefined;
      if (token && !seen.has(token)) {
        seen.add(token);
        tokens.push(token);
      }
    }
  }
  return tokens;
}

/**
 * Best-effort notify: never throws. Flags already persisted by projection.
 */
export async function notifyBudgetThresholds(
  db: Firestore,
  familyId: string,
  crossings: ThresholdCrossing[],
): Promise<void> {
  try {
    const actionable = crossings.filter((c) => c.crossed80 || c.crossed100);
    if (actionable.length === 0) return;

    const tokens = await collectMemberDeviceTokens(db, familyId);
    if (tokens.length === 0) {
      logger.info("Budget threshold FCM: no device tokens", {familyId});
      return;
    }

    const messaging = getMessaging();
    for (const crossing of actionable) {
      const notification = {
        title: "Budget alert",
        body: budgetThresholdNotificationBody(crossing),
      };
      const data = budgetThresholdDataPayload(familyId, crossing);

      for (const chunk of chunkTokens(tokens)) {
        const result = await messaging.sendEachForMulticast({
          tokens: chunk,
          notification,
          data,
        });
        if (result.failureCount > 0) {
          logger.warn("Budget threshold FCM partial failure", {
            familyId,
            budgetId: crossing.budgetId,
            periodId: crossing.periodId,
            successCount: result.successCount,
            failureCount: result.failureCount,
          });
        }
      }
    }
  } catch (err) {
    logger.warn("Budget threshold FCM skipped", {familyId, err});
  }
}
