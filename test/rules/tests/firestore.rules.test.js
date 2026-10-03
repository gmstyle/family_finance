/**
 * Minimal Firestore rules unit tests (Phase 1).
 *
 * Covers plan cases:
 * - create account without touching balanceMinor
 * - member cannot write budget periods
 * - family currency immutable
 * - category type immutable
 * - invite read baseline (invitee / admin / stranger)
 */
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { readFileSync } = require("fs");
const { resolve } = require("path");
const { doc, getDoc, setDoc, updateDoc } = require("firebase/firestore");

const PROJECT_ID = "demo-family-finance";
const FAMILY_ID = "fam1";
const ADMIN_UID = "admin1";
const MEMBER_UID = "member1";
const STRANGER_UID = "stranger1";

/** @type {import("@firebase/rules-unit-testing").RulesTestEnvironment} */
let testEnv;

const RULES_PATH = resolve(__dirname, "..", "..", "..", "firestore.rules");

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(RULES_PATH, "utf8"),
    },
  });
});

after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seedBaseline();
});

async function seedBaseline() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, "users", ADMIN_UID), {
      email: "admin@example.com",
      displayName: "Admin",
      familyId: FAMILY_ID,
    });
    await setDoc(doc(db, "users", MEMBER_UID), {
      email: "member@example.com",
      displayName: "Member",
      familyId: FAMILY_ID,
    });
    await setDoc(doc(db, "users", STRANGER_UID), {
      email: "stranger@example.com",
      displayName: "Stranger",
    });

    await setDoc(doc(db, "families", FAMILY_ID), {
      name: "Test Family",
      currency: "EUR",
      timezone: "Europe/Rome",
      ownerId: ADMIN_UID,
      status: "active",
      createdAt: new Date(),
    });
    await setDoc(doc(db, "families", FAMILY_ID, "members", ADMIN_UID), {
      role: "admin",
      displayName: "Admin",
      joinedAt: new Date(),
    });
    await setDoc(doc(db, "families", FAMILY_ID, "members", MEMBER_UID), {
      role: "member",
      displayName: "Member",
      joinedAt: new Date(),
    });

    await setDoc(doc(db, "families", FAMILY_ID, "categories", "catFood"), {
      nameKey: "categoryFood",
      type: "expense",
      icon: "restaurant",
      color: "#4CAF50",
      archived: false,
    });

    await setDoc(doc(db, "families", FAMILY_ID, "budgets", "budget1"), {
      categoryId: "catFood",
      limitAmountMinor: 10000,
    });

    await setDoc(doc(db, "invites", "inviteAdminFamily"), {
      familyId: FAMILY_ID,
      invitedEmail: "newuser@example.com",
      invitedByUserId: ADMIN_UID,
      token: "token-abc",
      status: "pending",
      expiresAt: new Date(Date.now() + 7 * 24 * 3600 * 1000),
      createdAt: new Date(),
    });

    await setDoc(doc(db, "invites", "inviteForMember"), {
      familyId: "other-family",
      invitedEmail: "member@example.com",
      invitedByUserId: "someone",
      token: "token-member",
      status: "pending",
      expiresAt: new Date(Date.now() + 7 * 24 * 3600 * 1000),
      createdAt: new Date(),
    });
  });
}

function authedDb(uid, token = {}) {
  return testEnv
    .authenticatedContext(uid, {
      email: token.email,
      email_verified: token.email_verified ?? true,
      ...token,
    })
    .firestore();
}

describe("accounts", () => {
  it("allows create without balanceMinor", async () => {
    const db = authedDb(MEMBER_UID, { email: "member@example.com" });
    await assertSucceeds(
      setDoc(doc(db, "families", FAMILY_ID, "accounts", "acc1"), {
        name: "Cash",
        type: "cash",
        openingBalanceMinor: 0,
        openingDate: "2026-01-01",
        archived: false,
        createdByUserId: MEMBER_UID,
        createdAt: new Date(),
      }),
    );
  });

  it("rejects create that includes balanceMinor", async () => {
    const db = authedDb(MEMBER_UID, { email: "member@example.com" });
    await assertFails(
      setDoc(doc(db, "families", FAMILY_ID, "accounts", "acc2"), {
        name: "Cash",
        type: "cash",
        openingBalanceMinor: 0,
        openingDate: "2026-01-01",
        balanceMinor: 0,
        archived: false,
        createdByUserId: MEMBER_UID,
        createdAt: new Date(),
      }),
    );
  });
});

describe("budget periods", () => {
  it("rejects member write to periods", async () => {
    const db = authedDb(MEMBER_UID, { email: "member@example.com" });
    await assertFails(
      setDoc(
        doc(db, "families", FAMILY_ID, "budgets", "budget1", "periods", "2026-09"),
        {
          spentAmountMinor: 500,
          threshold80Notified: false,
          threshold100Notified: false,
        },
      ),
    );
  });
});

describe("family currency", () => {
  it("rejects currency change on family update", async () => {
    const db = authedDb(ADMIN_UID, { email: "admin@example.com" });
    await assertFails(
      updateDoc(doc(db, "families", FAMILY_ID), {
        currency: "USD",
      }),
    );
  });

  it("allows admin to update name", async () => {
    const db = authedDb(ADMIN_UID, { email: "admin@example.com" });
    await assertSucceeds(
      updateDoc(doc(db, "families", FAMILY_ID), {
        name: "Renamed Family",
      }),
    );
  });
});

describe("categories", () => {
  it("rejects changing category type", async () => {
    const db = authedDb(MEMBER_UID, { email: "member@example.com" });
    await assertFails(
      updateDoc(doc(db, "families", FAMILY_ID, "categories", "catFood"), {
        type: "income",
      }),
    );
  });
});

describe("invites read", () => {
  it("allows invitee with matching verified email to read", async () => {
    const db = authedDb(MEMBER_UID, {
      email: "member@example.com",
      email_verified: true,
    });
    await assertSucceeds(getDoc(doc(db, "invites", "inviteForMember")));
  });

  it("allows family admin to read family invites", async () => {
    const db = authedDb(ADMIN_UID, {
      email: "admin@example.com",
      email_verified: true,
    });
    await assertSucceeds(getDoc(doc(db, "invites", "inviteAdminFamily")));
  });

  it("rejects stranger read", async () => {
    const db = authedDb(STRANGER_UID, {
      email: "stranger@example.com",
      email_verified: true,
    });
    await assertFails(getDoc(doc(db, "invites", "inviteAdminFamily")));
  });
});

describe("user devices", () => {
  it("allows user to write own device doc", async () => {
    const db = authedDb(MEMBER_UID, { email: "member@example.com" });
    await assertSucceeds(
      setDoc(doc(db, "users", MEMBER_UID, "devices", "phone1"), {
        token: "fcm-token-abc",
        platform: "android",
        updatedAt: new Date(),
      }),
    );
  });

  it("rejects writing another user device doc", async () => {
    const db = authedDb(MEMBER_UID, { email: "member@example.com" });
    await assertFails(
      setDoc(doc(db, "users", ADMIN_UID, "devices", "phone1"), {
        token: "fcm-token-abc",
        platform: "android",
        updatedAt: new Date(),
      }),
    );
  });
});
