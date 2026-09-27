/**
 * Membership callables — Admin SDK is the only writer for members / familyId / invites.
 */
import {randomBytes} from "crypto";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall, CallableRequest} from "firebase-functions/v2/https";
import {SYSTEM_CATEGORIES} from "./categories";
import {callableOpts} from "./options";

const db = () => getFirestore();

type Role = "admin" | "member";

function requireAuth(request: CallableRequest): {
  uid: string;
  email: string;
  emailVerified: boolean;
  displayName: string;
} {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const email = (auth.token.email as string | undefined)?.toLowerCase() ?? "";
  return {
    uid: auth.uid,
    email,
    emailVerified: auth.token.email_verified === true,
    displayName:
      (auth.token.name as string | undefined) ||
      email.split("@")[0] ||
      "User",
  };
}

function inviteExpiresAt(days = 7): Timestamp {
  const ms = Date.now() + days * 24 * 60 * 60 * 1000;
  return Timestamp.fromMillis(ms);
}

async function countAdmins(familyId: string): Promise<number> {
  const snap = await db()
    .collection("families")
    .doc(familyId)
    .collection("members")
    .where("role", "==", "admin")
    .get();
  return snap.size;
}

async function countMembers(familyId: string): Promise<number> {
  const snap = await db()
    .collection("families")
    .doc(familyId)
    .collection("members")
    .get();
  return snap.size;
}

async function assertAdmin(familyId: string, uid: string): Promise<void> {
  const member = await db()
    .collection("families")
    .doc(familyId)
    .collection("members")
    .doc(uid)
    .get();
  if (!member.exists || member.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin role required.");
  }
}

/** createFamily — family, owner member, users.familyId, system categories. */
export const createFamily = onCall(callableOpts, async (request) => {
  const user = requireAuth(request);
  const name = String(request.data?.name ?? "").trim();
  const currency = String(request.data?.currency ?? "EUR").trim().toUpperCase();
  const timezone = String(request.data?.timezone ?? "Europe/Rome").trim();

  if (name.length < 2) {
    throw new HttpsError("invalid-argument", "Family name is required.");
  }
  if (!/^[A-Z]{3}$/.test(currency)) {
    throw new HttpsError("invalid-argument", "currency must be a 3-letter ISO code.");
  }

  const userRef = db().collection("users").doc(user.uid);
  const userSnap = await userRef.get();
  if (userSnap.exists && userSnap.data()?.familyId) {
    throw new HttpsError("failed-precondition", "You already belong to a family.");
  }

  const familyRef = db().collection("families").doc();
  const now = FieldValue.serverTimestamp();

  await db().runTransaction(async (tx) => {
    const fresh = await tx.get(userRef);
    if (fresh.exists && fresh.data()?.familyId) {
      throw new HttpsError("failed-precondition", "You already belong to a family.");
    }

    tx.set(familyRef, {
      name,
      currency,
      timezone,
      ownerId: user.uid,
      status: "active",
      createdAt: now,
      updatedAt: now,
    });

    tx.set(familyRef.collection("members").doc(user.uid), {
      role: "admin",
      displayName: user.displayName,
      joinedAt: now,
    });

    for (const cat of SYSTEM_CATEGORIES) {
      const catRef = familyRef.collection("categories").doc();
      tx.set(catRef, {
        nameKey: cat.nameKey,
        type: cat.type,
        icon: cat.icon,
        color: cat.color,
        archived: false,
        createdAt: now,
      });
    }

    if (fresh.exists) {
      tx.update(userRef, {
        familyId: familyRef.id,
        email: user.email || fresh.data()?.email || "",
        displayName: user.displayName,
        updatedAt: now,
      });
    } else {
      tx.set(userRef, {
        email: user.email,
        displayName: user.displayName,
        familyId: familyRef.id,
        createdAt: now,
        updatedAt: now,
      });
    }
  });

  return {familyId: familyRef.id};
});

/** createInvite — admin only; returns token for in-app / emulator copy link. */
export const createInvite = onCall(callableOpts, async (request) => {
  const user = requireAuth(request);
  const invitedEmail = String(request.data?.invitedEmail ?? "")
    .trim()
    .toLowerCase();
  if (!invitedEmail || !invitedEmail.includes("@")) {
    throw new HttpsError("invalid-argument", "invitedEmail is required.");
  }

  const userSnap = await db().collection("users").doc(user.uid).get();
  const familyId = userSnap.data()?.familyId as string | undefined;
  if (!familyId) {
    throw new HttpsError("failed-precondition", "Create or join a family first.");
  }
  await assertAdmin(familyId, user.uid);

  const token = randomBytes(24).toString("hex");
  const inviteRef = db().collection("invites").doc();
  const now = FieldValue.serverTimestamp();
  const expiresAt = inviteExpiresAt(7);

  await inviteRef.set({
    familyId,
    invitedEmail,
    invitedByUserId: user.uid,
    token,
    status: "pending",
    expiresAt,
    createdAt: now,
  });

  return {
    inviteId: inviteRef.id,
    token,
    invitedEmail,
    expiresAt: expiresAt.toDate().toISOString(),
  };
});

/** revokeInvite — admin; marks invite revoked. */
export const revokeInvite = onCall(callableOpts, async (request) => {
  const user = requireAuth(request);
  const inviteId = String(request.data?.inviteId ?? "").trim();
  if (!inviteId) {
    throw new HttpsError("invalid-argument", "inviteId is required.");
  }

  const inviteRef = db().collection("invites").doc(inviteId);
  const invite = await inviteRef.get();
  if (!invite.exists) {
    throw new HttpsError("not-found", "Invite not found.");
  }
  const data = invite.data()!;
  await assertAdmin(data.familyId as string, user.uid);

  if (data.status !== "pending") {
    throw new HttpsError("failed-precondition", "Invite is not pending.");
  }

  await inviteRef.update({
    status: "revoked",
    updatedAt: FieldValue.serverTimestamp(),
  });
  return {ok: true};
});

/**
 * acceptInvite — verified email must match; leave previous family with
 * last-admin / orphaned rules from the plan.
 */
export const acceptInvite = onCall(callableOpts, async (request) => {
  const user = requireAuth(request);
  if (!user.emailVerified) {
    throw new HttpsError("failed-precondition", "Email must be verified.");
  }
  if (!user.email) {
    throw new HttpsError("failed-precondition", "Authenticated email is required.");
  }

  const token = String(request.data?.token ?? "").trim();
  if (!token) {
    throw new HttpsError("invalid-argument", "token is required.");
  }

  const invites = await db()
    .collection("invites")
    .where("token", "==", token)
    .limit(1)
    .get();
  if (invites.empty) {
    throw new HttpsError("not-found", "Invite not found.");
  }
  const inviteDoc = invites.docs[0];
  const invite = inviteDoc.data();

  if (invite.status !== "pending") {
    throw new HttpsError("failed-precondition", "Invite is not pending.");
  }
  const expiresAt = invite.expiresAt as Timestamp;
  if (expiresAt.toMillis() < Date.now()) {
    throw new HttpsError("failed-precondition", "Invite has expired.");
  }
  if ((invite.invitedEmail as string).toLowerCase() !== user.email) {
    throw new HttpsError(
      "permission-denied",
      "Invite email does not match the signed-in account.",
    );
  }

  const targetFamilyId = invite.familyId as string;
  const userRef = db().collection("users").doc(user.uid);
  const userSnap = await userRef.get();
  const previousFamilyId = userSnap.exists
    ? (userSnap.data()?.familyId as string | undefined)
    : undefined;

  if (previousFamilyId === targetFamilyId) {
    throw new HttpsError("already-exists", "Already a member of this family.");
  }

  let orphanPrevious = false;
  if (previousFamilyId) {
    const prevMemberRef = db()
      .collection("families")
      .doc(previousFamilyId)
      .collection("members")
      .doc(user.uid);
    const prevMember = await prevMemberRef.get();
    if (prevMember.exists) {
      const role = prevMember.data()?.role as Role;
      if (role === "admin") {
        const admins = await countAdmins(previousFamilyId);
        if (admins <= 1) {
          throw new HttpsError(
            "failed-precondition",
            "Promote another admin before leaving your current family.",
          );
        }
      }
      const members = await countMembers(previousFamilyId);
      orphanPrevious = members <= 1;
    }
  }

  const now = FieldValue.serverTimestamp();

  await db().runTransaction(async (tx) => {
    const freshInvite = await tx.get(inviteDoc.ref);
    if (!freshInvite.exists || freshInvite.data()?.status !== "pending") {
      throw new HttpsError("failed-precondition", "Invite is not pending.");
    }

    if (previousFamilyId) {
      const prevMemberRef = db()
        .collection("families")
        .doc(previousFamilyId)
        .collection("members")
        .doc(user.uid);
      const prevMember = await tx.get(prevMemberRef);
      if (prevMember.exists) {
        tx.delete(prevMemberRef);
        if (orphanPrevious) {
          tx.update(db().collection("families").doc(previousFamilyId), {
            status: "orphaned",
            updatedAt: now,
          });
        }
      }
    }

    const targetMemberRef = db()
      .collection("families")
      .doc(targetFamilyId)
      .collection("members")
      .doc(user.uid);
    tx.set(targetMemberRef, {
      role: "member",
      displayName: user.displayName,
      joinedAt: now,
    });

    tx.update(inviteDoc.ref, {
      status: "accepted",
      acceptedByUserId: user.uid,
      updatedAt: now,
    });

    if (userSnap.exists) {
      tx.update(userRef, {
        familyId: targetFamilyId,
        email: user.email,
        displayName: user.displayName,
        updatedAt: now,
      });
    } else {
      tx.set(userRef, {
        email: user.email,
        displayName: user.displayName,
        familyId: targetFamilyId,
        createdAt: now,
        updatedAt: now,
      });
    }
  });

  return {familyId: targetFamilyId};
});

/** removeMember — admin removes another member (not self via this callable). */
export const removeMember = onCall(callableOpts, async (request) => {
  const user = requireAuth(request);
  const targetUserId = String(request.data?.userId ?? "").trim();
  if (!targetUserId) {
    throw new HttpsError("invalid-argument", "userId is required.");
  }
  if (targetUserId === user.uid) {
    throw new HttpsError("invalid-argument", "Use leaveFamily to leave yourself.");
  }

  const userSnap = await db().collection("users").doc(user.uid).get();
  const familyId = userSnap.data()?.familyId as string | undefined;
  if (!familyId) {
    throw new HttpsError("failed-precondition", "No family.");
  }
  await assertAdmin(familyId, user.uid);

  const family = await db().collection("families").doc(familyId).get();
  if (family.data()?.ownerId === targetUserId) {
    throw new HttpsError(
      "failed-precondition",
      "Transfer ownership before removing the owner.",
    );
  }

  const memberRef = db()
    .collection("families")
    .doc(familyId)
    .collection("members")
    .doc(targetUserId);
  const member = await memberRef.get();
  if (!member.exists) {
    throw new HttpsError("not-found", "Member not found.");
  }

  const batch = db().batch();
  batch.delete(memberRef);
  batch.update(db().collection("users").doc(targetUserId), {
    familyId: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  return {ok: true};
});

/** updateMemberRole — admin; cannot demote last admin. */
export const updateMemberRole = onCall(callableOpts, async (request) => {
  const user = requireAuth(request);
  const targetUserId = String(request.data?.userId ?? "").trim();
  const role = String(request.data?.role ?? "").trim() as Role;
  if (!targetUserId || (role !== "admin" && role !== "member")) {
    throw new HttpsError("invalid-argument", "userId and role (admin|member) required.");
  }

  const userSnap = await db().collection("users").doc(user.uid).get();
  const familyId = userSnap.data()?.familyId as string | undefined;
  if (!familyId) {
    throw new HttpsError("failed-precondition", "No family.");
  }
  await assertAdmin(familyId, user.uid);

  const memberRef = db()
    .collection("families")
    .doc(familyId)
    .collection("members")
    .doc(targetUserId);
  const member = await memberRef.get();
  if (!member.exists) {
    throw new HttpsError("not-found", "Member not found.");
  }

  if (member.data()?.role === "admin" && role === "member") {
    const admins = await countAdmins(familyId);
    if (admins <= 1) {
      throw new HttpsError(
        "failed-precondition",
        "Cannot demote the last admin.",
      );
    }
  }

  await memberRef.update({
    role,
    updatedAt: FieldValue.serverTimestamp(),
  });
  return {ok: true};
});

/** transferOwnership — owner transfer; target becomes admin. */
export const transferOwnership = onCall(callableOpts, async (request) => {
  const user = requireAuth(request);
  const newOwnerId = String(request.data?.userId ?? "").trim();
  if (!newOwnerId) {
    throw new HttpsError("invalid-argument", "userId is required.");
  }

  const userSnap = await db().collection("users").doc(user.uid).get();
  const familyId = userSnap.data()?.familyId as string | undefined;
  if (!familyId) {
    throw new HttpsError("failed-precondition", "No family.");
  }

  const familyRef = db().collection("families").doc(familyId);
  const family = await familyRef.get();
  if (family.data()?.ownerId !== user.uid) {
    throw new HttpsError("permission-denied", "Only the owner can transfer ownership.");
  }

  const targetRef = familyRef.collection("members").doc(newOwnerId);
  const target = await targetRef.get();
  if (!target.exists) {
    throw new HttpsError("not-found", "Member not found.");
  }

  const batch = db().batch();
  batch.update(familyRef, {
    ownerId: newOwnerId,
    updatedAt: FieldValue.serverTimestamp(),
  });
  batch.update(targetRef, {
    role: "admin",
    updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  return {ok: true};
});

/** leaveFamily — last admin blocked; sole member orphans family. */
export const leaveFamily = onCall(callableOpts, async (request) => {
  const user = requireAuth(request);
  const userRef = db().collection("users").doc(user.uid);
  const userSnap = await userRef.get();
  const familyId = userSnap.data()?.familyId as string | undefined;
  if (!familyId) {
    throw new HttpsError("failed-precondition", "No family.");
  }

  const familyRef = db().collection("families").doc(familyId);
  const memberRef = familyRef.collection("members").doc(user.uid);
  const member = await memberRef.get();
  if (!member.exists) {
    throw new HttpsError("failed-precondition", "Not a family member.");
  }

  const role = member.data()?.role as Role;
  if (role === "admin") {
    const admins = await countAdmins(familyId);
    if (admins <= 1) {
      throw new HttpsError(
        "failed-precondition",
        "Promote another admin before leaving.",
      );
    }
  }

  const members = await countMembers(familyId);
  const family = await familyRef.get();
  if (family.data()?.ownerId === user.uid && members > 1) {
    throw new HttpsError(
      "failed-precondition",
      "Transfer ownership before leaving.",
    );
  }

  const batch = db().batch();
  batch.delete(memberRef);
  batch.update(userRef, {
    familyId: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  if (members <= 1) {
    batch.update(familyRef, {
      status: "orphaned",
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  return {ok: true};
});
