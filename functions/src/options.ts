/**
 * Shared Functions options. Import this module before defining any callables
 * so setGlobalOptions applies (ESM evaluates imports before the body of
 * index.ts, which previously left membership callables in us-central1).
 */
import {setGlobalOptions} from "firebase-functions/v2";

export const FUNCTIONS_REGION = "europe-west1" as const;

setGlobalOptions({
  region: FUNCTIONS_REGION,
  maxInstances: 10,
});

/** Default opts for HTTPS callables (emulator + production). */
export const callableOpts = {
  region: FUNCTIONS_REGION,
  enforceAppCheck: false,
} as const;
