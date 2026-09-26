/**
 * Family Finance Cloud Functions — Phase 1 scaffold.
 *
 * Membership callables, ledger triggers, and FCM land in later phases.
 * Keep this entrypoint light so emulators and deploy wiring work now.
 */
import {initializeApp} from "firebase-admin/app";
import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError} from "firebase-functions/v2/https";

initializeApp();

setGlobalOptions({
  region: "europe-west1",
  maxInstances: 10,
});

/**
 * Health-check callable used to verify Functions emulator wiring.
 * Real membership / transfer callables arrive in Phase 2+.
 */
export const ping = onCall({enforceAppCheck: false}, () => {
  return {ok: true, service: "family-finance-functions"};
});

/** Placeholder so unused-import lint stays quiet if HttpsError is needed later. */
export function notImplemented(name: string): never {
  throw new HttpsError("unimplemented", `${name} is not implemented yet`);
}
