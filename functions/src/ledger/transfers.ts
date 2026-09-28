/**
 * Atomic transfer callables — two transaction docs, same transferId.
 */
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {CallableRequest, HttpsError, onCall} from "firebase-functions/v2/https";

import {callableOpts} from "../options";

const db = () => getFirestore();

function requireAuth(request: CallableRequest): {
  uid: string;
  displayName: string;
} {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const email = (auth.token.email as string | undefined) ?? "";
  return {
    uid: auth.uid,
    displayName:
      (auth.token.name as string | undefined) ||
      email.split("@")[0] ||
      "User",
  };
}

async function requireFamilyMember(uid: string): Promise<{
  familyId: string;
  currency: string;
}> {
  const userSnap = await db().collection("users").doc(uid).get();
  const familyId = userSnap.data()?.familyId as string | undefined;
  if (!familyId) {
    throw new HttpsError("failed-precondition", "Create or join a family first.");
  }
  const member = await db()
    .collection("families")
    .doc(familyId)
    .collection("members")
    .doc(uid)
    .get();
  if (!member.exists) {
    throw new HttpsError("permission-denied", "Not a family member.");
  }
  const family = await db().collection("families").doc(familyId).get();
  if (!family.exists) {
    throw new HttpsError("not-found", "Family not found.");
  }
  const currency = family.data()?.currency as string;
  if (!currency) {
    throw new HttpsError("failed-precondition", "Family currency missing.");
  }
  return {familyId, currency};
}

const BOOKING_DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

/**
 * createTransfer — two docs (source + destination), same transferId, no categoryId.
 */
export const createTransfer = onCall(callableOpts, async (request) => {
  const user = requireAuth(request);
  const {familyId, currency} = await requireFamilyMember(user.uid);

  const sourceAccountId = String(request.data?.sourceAccountId ?? "").trim();
  const destinationAccountId = String(
    request.data?.destinationAccountId ?? "",
  ).trim();
  const amountMinor = Number(request.data?.amountMinor);
  const bookingDate = String(request.data?.bookingDate ?? "").trim();
  const note = request.data?.note != null
    ? String(request.data.note).trim()
    : "";
  const merchant = request.data?.merchant != null
    ? String(request.data.merchant).trim()
    : "";

  if (!sourceAccountId || !destinationAccountId) {
    throw new HttpsError(
      "invalid-argument",
      "sourceAccountId and destinationAccountId are required.",
    );
  }
  if (sourceAccountId === destinationAccountId) {
    throw new HttpsError(
      "invalid-argument",
      "Source and destination accounts must differ.",
    );
  }
  if (!Number.isInteger(amountMinor) || amountMinor <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "amountMinor must be a positive integer.",
    );
  }
  if (!BOOKING_DATE_RE.test(bookingDate)) {
    throw new HttpsError(
      "invalid-argument",
      "bookingDate must be YYYY-MM-DD.",
    );
  }

  const familyRef = db().collection("families").doc(familyId);
  const sourceRef = familyRef.collection("accounts").doc(sourceAccountId);
  const destRef = familyRef.collection("accounts").doc(destinationAccountId);

  const [sourceSnap, destSnap] = await Promise.all([
    sourceRef.get(),
    destRef.get(),
  ]);
  if (!sourceSnap.exists || !destSnap.exists) {
    throw new HttpsError("not-found", "Account not found.");
  }
  if (sourceSnap.data()?.archived === true || destSnap.data()?.archived === true) {
    throw new HttpsError("failed-precondition", "Cannot transfer to/from archived account.");
  }

  const transferId = db().collection("_ids").doc().id;
  const sourceTxRef = familyRef.collection("transactions").doc();
  const destTxRef = familyRef.collection("transactions").doc();
  const now = FieldValue.serverTimestamp();

  const base = {
    type: "transfer" as const,
    categoryId: null,
    amountMinor,
    currency,
    bookingDate,
    transferId,
    note: note || null,
    merchant: merchant || null,
    createdByUserId: user.uid,
    createdAt: now,
    updatedAt: now,
  };

  const batch = db().batch();
  batch.set(sourceTxRef, {
    ...base,
    accountId: sourceAccountId,
    transferRole: "source",
  });
  batch.set(destTxRef, {
    ...base,
    accountId: destinationAccountId,
    transferRole: "destination",
  });
  await batch.commit();

  return {
    transferId,
    sourceTransactionId: sourceTxRef.id,
    destinationTransactionId: destTxRef.id,
  };
});

/**
 * deleteTransfer — delete both legs atomically by transferId.
 */
export const deleteTransfer = onCall(callableOpts, async (request) => {
  const user = requireAuth(request);
  const {familyId} = await requireFamilyMember(user.uid);

  const transferId = String(request.data?.transferId ?? "").trim();
  if (!transferId) {
    throw new HttpsError("invalid-argument", "transferId is required.");
  }

  const txSnap = await db()
    .collection("families")
    .doc(familyId)
    .collection("transactions")
    .where("transferId", "==", transferId)
    .get();

  if (txSnap.empty) {
    throw new HttpsError("not-found", "Transfer not found.");
  }
  if (txSnap.size !== 2) {
    throw new HttpsError(
      "failed-precondition",
      `Expected 2 transfer legs, found ${txSnap.size}.`,
    );
  }

  const roles = new Set(
    txSnap.docs.map((d) => d.data().transferRole as string),
  );
  if (!roles.has("source") || !roles.has("destination")) {
    throw new HttpsError(
      "failed-precondition",
      "Transfer legs must include source and destination.",
    );
  }

  const batch = db().batch();
  for (const doc of txSnap.docs) {
    batch.delete(doc.ref);
  }
  await batch.commit();

  return {ok: true, transferId, deleted: txSnap.size};
});
