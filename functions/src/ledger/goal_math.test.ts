import assert from "node:assert/strict";
import {describe, it} from "node:test";

import {
  contributionAccumulatedDelta,
  contributionImagesEqual,
  contributionProjectionId,
  extractContributionImage,
} from "./goal_math";
import {
  budgetThresholdDataPayload,
  budgetThresholdNotificationBody,
  chunkTokens,
} from "./budget_fcm_math";
import {ThresholdCrossing} from "./types";

describe("contributionProjectionId", () => {
  it("namespaces under _projections", () => {
    assert.equal(
      contributionProjectionId("g1", "c1"),
      "goalContrib_g1_c1",
    );
  });
});

describe("extractContributionImage", () => {
  it("accepts signed non-zero integers", () => {
    assert.deepEqual(extractContributionImage({amountMinor: 1500}), {
      amountMinor: 1500,
    });
    assert.deepEqual(extractContributionImage({amountMinor: -500}), {
      amountMinor: -500,
    });
  });

  it("rejects zero / non-int / missing", () => {
    assert.equal(extractContributionImage({amountMinor: 0}), null);
    assert.equal(extractContributionImage({amountMinor: 1.5}), null);
    assert.equal(extractContributionImage({}), null);
    assert.equal(extractContributionImage(null), null);
  });
});

describe("contributionAccumulatedDelta", () => {
  it("deposit increases accumulated", () => {
    assert.equal(
      contributionAccumulatedDelta(null, {amountMinor: 2000}),
      2000,
    );
  });

  it("withdraw decreases accumulated", () => {
    assert.equal(
      contributionAccumulatedDelta(null, {amountMinor: -750}),
      -750,
    );
  });

  it("idempotent retry is zero when previous matches desired", () => {
    const img = {amountMinor: 1000};
    assert.equal(contributionAccumulatedDelta(img, img), 0);
    assert.equal(contributionImagesEqual(img, img), true);
  });

  it("delete undoes previous apply", () => {
    assert.equal(
      contributionAccumulatedDelta({amountMinor: 1000}, null),
      -1000,
    );
  });

  it("amount change applies net delta", () => {
    assert.equal(
      contributionAccumulatedDelta(
        {amountMinor: 1000},
        {amountMinor: 1500},
      ),
      500,
    );
    assert.equal(
      contributionAccumulatedDelta(
        {amountMinor: 1000},
        {amountMinor: -200},
      ),
      -1200,
    );
  });
});

describe("budget FCM helpers", () => {
  const crossing: ThresholdCrossing = {
    budgetId: "b1",
    periodId: "2026-09",
    crossed80: true,
    crossed100: false,
  };

  it("chunkTokens respects multicast limit", () => {
    const tokens = Array.from({length: 501}, (_, i) => `t${i}`);
    const chunks = chunkTokens(tokens, 500);
    assert.equal(chunks.length, 2);
    assert.equal(chunks[0].length, 500);
    assert.equal(chunks[1].length, 1);
  });

  it("builds notification body and string data payload", () => {
    assert.equal(
      budgetThresholdNotificationBody(crossing),
      "Budget reached 80% for 2026-09.",
    );
    assert.deepEqual(budgetThresholdDataPayload("fam1", crossing), {
      type: "budget_threshold",
      familyId: "fam1",
      budgetId: "b1",
      periodId: "2026-09",
      crossed80: "true",
      crossed100: "false",
    });

    const both: ThresholdCrossing = {
      ...crossing,
      crossed100: true,
    };
    assert.equal(
      budgetThresholdNotificationBody(both),
      "Budget reached 80% / 100% for 2026-09.",
    );
  });
});
