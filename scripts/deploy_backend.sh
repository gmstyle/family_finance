#!/usr/bin/env bash
# Build Cloud Functions and deploy Firestore rules/indexes + Functions to
# production. Does not deploy Hosting (use ./scripts/deploy_web_hosting.sh).
#
# Usage (from repo root):
#   ./scripts/deploy_backend.sh
#
# Optional:
#   FIREBASE_PROJECT=other-project ./scripts/deploy_backend.sh
#   ONLY=functions ./scripts/deploy_backend.sh   # skip firestore
#   ONLY=firestore ./scripts/deploy_backend.sh   # skip functions build/deploy
#
# Requires: Node/npm, Firebase CLI (via npx), project family-finance-gmstyle-app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="${FIREBASE_PROJECT:-family-finance-gmstyle-app}"
ONLY="${ONLY:-firestore,functions}"

if [[ "$ONLY" != "firestore" && "$ONLY" != "functions" && "$ONLY" != "firestore,functions" ]]; then
  echo "ONLY must be firestore, functions, or firestore,functions (got: $ONLY)" >&2
  exit 1
fi

if [[ "$ONLY" == *"functions"* ]]; then
  echo "==> functions: npm ci && npm run build"
  (
    cd "$ROOT/functions"
    if [[ -f package-lock.json ]]; then
      npm ci
    else
      npm install
    fi
    npm run build
  )
fi

echo "==> firebase deploy --only $ONLY --project $PROJECT"
npx -y firebase-tools@latest deploy \
  --project "$PROJECT" \
  --only "$ONLY"

echo "Done."
echo "  Project:  $PROJECT"
echo "  Deployed: $ONLY"
echo "  Region:   europe-west1 (functions)"
