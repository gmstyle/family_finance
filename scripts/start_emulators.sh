#!/usr/bin/env bash
# Build Cloud Functions (optional) and start local Firebase emulators
# (Auth, Firestore, Functions + Emulator UI).
#
# Usage (from repo root):
#   ./scripts/start_emulators.sh
#
# Optional:
#   FIREBASE_PROJECT=demo-family-finance ./scripts/start_emulators.sh
#   SKIP_BUILD=1 ./scripts/start_emulators.sh          # skip functions npm build
#   IMPORT_DIR=./.emulator-data ./scripts/start_emulators.sh
#   EXPORT_ON_EXIT=./.emulator-data ./scripts/start_emulators.sh
#
# Then run the app with:
#   flutter run -d chrome --dart-define=USE_EMULATORS=true
#   flutter run -d android --dart-define=USE_EMULATORS=true
#   ./scripts/run_physical_android_emulators.sh   # physical device + LAN IP
#
# Requires: Node/npm, Java (Firestore), Firebase CLI via npx.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="${FIREBASE_PROJECT:-demo-family-finance}"
SKIP_BUILD="${SKIP_BUILD:-0}"

if [[ "$SKIP_BUILD" != "1" ]]; then
  echo "==> functions: npm install/ci && npm run build"
  (
    cd "$ROOT/functions"
    if [[ -f package-lock.json ]]; then
      npm ci
    else
      npm install
    fi
    npm run build
  )
else
  echo "==> SKIP_BUILD=1 — not rebuilding functions"
fi

ARGS=(emulators:start --project "$PROJECT")

if [[ -n "${IMPORT_DIR:-}" ]]; then
  if [[ ! -d "$IMPORT_DIR" ]]; then
    echo "IMPORT_DIR is not a directory: $IMPORT_DIR" >&2
    exit 1
  fi
  ARGS+=(--import="$IMPORT_DIR")
fi

if [[ -n "${EXPORT_ON_EXIT:-}" ]]; then
  mkdir -p "$EXPORT_ON_EXIT"
  ARGS+=(--export-on-exit="$EXPORT_ON_EXIT")
fi

echo "==> firebase ${ARGS[*]}"
echo "    UI:        http://127.0.0.1:4000"
echo "    Auth:      9099  Firestore: 8080  Functions: 5001"
echo "    Project:   $PROJECT"
echo "    Ctrl+C to stop (in-memory data is discarded unless EXPORT_ON_EXIT is set)."
echo

exec npx -y firebase-tools@latest "${ARGS[@]}"
