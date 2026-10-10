#!/usr/bin/env bash
# Build Flutter web (release) and deploy to classic Firebase Hosting with a
# privacy-policy overlay. Never deploy Hosting without the overlay — that would
# wipe live privacy.html pages.
#
# Usage (from repo root or this script):
#   ./scripts/deploy_web_hosting.sh
#
# Requires: Flutter SDK, Firebase CLI (via npx), project family-finance-gmstyle-app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="${FIREBASE_PROJECT:-family-finance-gmstyle-app}"
PRIVACY_SRC="$ROOT/hosting/public"
WEB_OUT="$ROOT/build/web"

echo "==> flutter build web --release (no emulator defines)"
flutter build web --release

echo "==> overlay privacy + App Links from hosting/public/ into build/web/"
for f in privacy.html privacy-it.html; do
  if [[ ! -f "$PRIVACY_SRC/$f" ]]; then
    echo "Missing privacy source: $PRIVACY_SRC/$f" >&2
    exit 1
  fi
  cp -f "$PRIVACY_SRC/$f" "$WEB_OUT/$f"
done
mkdir -p "$WEB_OUT/.well-known"
cp -f "$PRIVACY_SRC/.well-known/assetlinks.json" "$WEB_OUT/.well-known/assetlinks.json"

echo "==> firebase deploy --only hosting --project $PROJECT"
npx -y firebase-tools@latest deploy \
  --project "$PROJECT" \
  --only hosting

echo "Done."
echo "  App:     https://${PROJECT}.web.app/"
echo "  Privacy: https://${PROJECT}.web.app/privacy.html"
echo "  Privacy (IT): https://${PROJECT}.web.app/privacy-it.html"
