/**
 * Idempotent apply of a goal contribution onto `accumulatedAmountMinor`.
 * Does not touch account balances (virtual goals).
 */
import {
  DocumentData,
  FieldValue,
  Firestore,
} from "firebase-admin/firestore";

import {
  contributionAccumulatedDelta,
  contributionImagesEqual,
  contributionProjectionId,
  extractContributionImage,
} from "./goal_math";

export interface GoalApplyResult {
  applied: boolean;
  delta: number;
}

/**
 * Undo previous contribution image (if any), apply new.
 * No-op when images are identical (safe on Functions retries).
 */
export async function applyGoalContributionProjection(
  db: Firestore,
  familyId: string,
  goalId: string,
  contributionId: string,
  newData: DocumentData | undefined | null,
): Promise<GoalApplyResult> {
  const familyRef = db.collection("families").doc(familyId);
  const goalRef = familyRef.collection("goals").doc(goalId);
  const projectionRef = familyRef
    .collection("_projections")
    .doc(contributionProjectionId(goalId, contributionId));
  const desired = extractContributionImage(newData ?? undefined);

  return db.runTransaction(async (tx) => {
    const projSnap = await tx.get(projectionRef);
    const goalSnap = await tx.get(goalRef);

    const previous = projSnap.exists
      ? extractContributionImage(projSnap.data() as DocumentData)
      : null;

    if (contributionImagesEqual(previous, desired)) {
      return {applied: false, delta: 0};
    }

    const delta = contributionAccumulatedDelta(previous, desired);

    if (delta !== 0 && goalSnap.exists) {
      tx.update(goalRef, {
        accumulatedAmountMinor: FieldValue.increment(delta),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    if (desired) {
      tx.set(projectionRef, {
        kind: "goalContribution",
        goalId,
        amountMinor: desired.amountMinor,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else if (projSnap.exists) {
      tx.delete(projectionRef);
    }

    return {applied: true, delta};
  });
}
