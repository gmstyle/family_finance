#!/usr/bin/env bash
# Run the Flutter app on a USB-connected physical Android device against local
# Firebase emulators over Wi‑Fi (LAN IP).
#
# IMPORTANT: Do NOT use EMULATOR_HOST=127.0.0.1 on Android. The Firebase Flutter
# plugins remap 127.0.0.1 → 10.0.2.2 (AVD loopback). On a physical device that
# host is unreachable → Auth "network / host" errors. Use the PC's LAN IP instead.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEVICE="${1:-}"
if [[ -z "$DEVICE" ]]; then
  mapfile -t physical < <(adb devices -l | awk 'NR>1 && $2=="device" && $0 ~ /usb:/ {print $1}')
  mapfile -t all_devices < <(adb devices | awk 'NR>1 && $2=="device" {print $1}')

  if [[ ${#physical[@]} -eq 1 ]]; then
    DEVICE="${physical[0]}"
    echo "Auto-selected USB device: $DEVICE"
  elif [[ ${#physical[@]} -gt 1 ]]; then
    echo "Multiple USB devices; pass one explicitly:" >&2
    printf '  %s\n' "${physical[@]}" >&2
    echo "Usage: $0 <adb-device-id>" >&2
    exit 1
  elif [[ ${#all_devices[@]} -eq 1 ]]; then
    DEVICE="${all_devices[0]}"
    echo "No USB device listed; using only connected device: $DEVICE"
  else
    echo "Could not auto-pick a physical device." >&2
    echo "Connected:" >&2
    adb devices -l >&2 || true
    echo "Usage: $0 <adb-device-id>   # e.g. $0 70109b2c0504" >&2
    exit 1
  fi
fi

LAN_IP="${EMULATOR_HOST:-}"
if [[ -z "$LAN_IP" ]]; then
  LAN_IP="$(ip -4 addr show scope global 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1 || true)"
fi
if [[ -z "$LAN_IP" || "$LAN_IP" == "127.0.0.1" ]]; then
  echo "Could not detect LAN IP. Set EMULATOR_HOST=192.168.x.x" >&2
  exit 1
fi

echo "Using device: $DEVICE"
echo "EMULATOR_HOST=$LAN_IP (LAN — not 127.0.0.1; Firebase remaps localhost→10.0.2.2 on Android)"

if ! curl -sf -o /dev/null "http://${LAN_IP}:9099/"; then
  echo "Auth emulator not reachable at http://${LAN_IP}:9099/" >&2
  echo "Start ./start_firebase_emulators.sh first (binds 0.0.0.0)." >&2
  exit 1
fi

# Optional: verify phone can reach the PC (same Wi‑Fi required).
if ! adb -s "$DEVICE" shell "toybox nc -w 2 ${LAN_IP} 9099 </dev/null >/dev/null 2>&1"; then
  echo "WARNING: device cannot open TCP ${LAN_IP}:9099. Check phone Wi‑Fi / firewall." >&2
fi

exec flutter run -d "$DEVICE" \
  --dart-define=USE_EMULATORS=true \
  --dart-define=EMULATOR_HOST="$LAN_IP"
