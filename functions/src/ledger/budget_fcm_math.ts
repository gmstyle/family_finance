/**
 * Pure budget-threshold FCM payload helpers — unit-tested, no Admin I/O.
 */
import {ThresholdCrossing} from "./types";

/** FCM multicast limit. */
export const FCM_MULTICAST_LIMIT = 500;

export function chunkTokens(
  tokens: string[],
  size: number = FCM_MULTICAST_LIMIT,
): string[][] {
  if (size <= 0) throw new Error("chunk size must be positive");
  const chunks: string[][] = [];
  for (let i = 0; i < tokens.length; i += size) {
    chunks.push(tokens.slice(i, i + size));
  }
  return chunks;
}

export function budgetThresholdNotificationBody(
  crossing: ThresholdCrossing,
): string {
  const parts: string[] = [];
  if (crossing.crossed80) parts.push("80%");
  if (crossing.crossed100) parts.push("100%");
  return `Budget reached ${parts.join(" / ")} for ${crossing.periodId}.`;
}

export function budgetThresholdDataPayload(
  familyId: string,
  crossing: ThresholdCrossing,
): Record<string, string> {
  return {
    type: "budget_threshold",
    familyId,
    budgetId: crossing.budgetId,
    periodId: crossing.periodId,
    crossed80: crossing.crossed80 ? "true" : "false",
    crossed100: crossing.crossed100 ? "true" : "false",
  };
}
