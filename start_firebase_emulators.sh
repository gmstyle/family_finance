#!/usr/bin/env bash
# Build Functions and start Auth/Firestore/Functions emulators (LAN-reachable).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

cd functions && npm run build && cd ..

LAN_IP="$(ip -4 addr show scope global 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1 || true)"
echo "Emulators bind to 0.0.0.0 (see firebase.json)."
if [[ -n "${LAN_IP:-}" ]]; then
  echo "Physical device over Wi‑Fi:"
  echo "  flutter run -d <device> \\"
  echo "    --dart-define=USE_EMULATORS=true \\"
  echo "    --dart-define=EMULATOR_HOST=${LAN_IP}"
fi
echo "Physical Android (same Wi‑Fi; uses LAN IP — never 127.0.0.1):"
echo "  ./scripts/run_physical_android_emulators.sh"
echo

exec npx -y firebase-tools@latest emulators:start --project demo-family-finance
