/**
 * Pure goal-contribution math — unit-tested, no Firestore I/O.
 *
 * Contributions are virtual: they never touch account balances.
 * amountMinor > 0 = deposit, < 0 = withdraw.
 */
import {DocumentData} from "firebase-admin/firestore";

export interface GoalContributionImage {
  amountMinor: number;
}

/** Projection doc id under `families/{familyId}/_projections`. */
export function contributionProjectionId(
  goalId: string,
  contributionId: string,
): string {
  return `goalContrib_${goalId}_${contributionId}`;
}

/**
 * Net change to `goals.accumulatedAmountMinor` when moving from
 * previous applied image to desired (null = deleted / missing).
 */
export function contributionAccumulatedDelta(
  previous: GoalContributionImage | null,
  desired: GoalContributionImage | null,
): number {
  return (desired?.amountMinor ?? 0) - (previous?.amountMinor ?? 0);
}

export function contributionImagesEqual(
  a: GoalContributionImage | null,
  b: GoalContributionImage | null,
): boolean {
  if (a === null && b === null) return true;
  if (a === null || b === null) return false;
  return a.amountMinor === b.amountMinor;
}

/** Parse a contribution doc; null if unusable. */
export function extractContributionImage(
  data: DocumentData | undefined | null,
): GoalContributionImage | null {
  if (!data) return null;
  const amountMinor = data.amountMinor as number | undefined;
  if (
    typeof amountMinor !== "number" ||
    !Number.isInteger(amountMinor) ||
    amountMinor === 0
  ) {
    return null;
  }
  return {amountMinor};
}
