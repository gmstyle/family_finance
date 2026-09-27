/**
 * Family Finance Cloud Functions.
 *
 * Region: europe-west1. Client must call FirebaseFunctions.instanceFor(region: …).
 */
import {initializeApp} from "firebase-admin/app";
import {onCall} from "firebase-functions/v2/https";

import {callableOpts} from "./options";
import {
  acceptInvite,
  createFamily,
  createInvite,
  leaveFamily,
  removeMember,
  revokeInvite,
  transferOwnership,
  updateMemberRole,
} from "./membership";

initializeApp();

/** Health-check callable used to verify Functions emulator wiring. */
export const ping = onCall(callableOpts, () => {
  return {ok: true, service: "family-finance-functions"};
});

export {
  createFamily,
  createInvite,
  revokeInvite,
  acceptInvite,
  removeMember,
  updateMemberRole,
  transferOwnership,
  leaveFamily,
};
