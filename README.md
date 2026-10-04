# Family Finance

Shared family ledger (Flutter + Firebase): budgets, goals, and confirmed transactions — Italian and English.

FlutterFire is already configured for project `family-finance-gmstyle-app` (`lib/firebase_options.dart`, Android `google-services.json`). Do **not** re-run `flutterfire configure` unless you intentionally change apps/platforms.

## Prerequisites

- Flutter SDK (stable)
- Node.js 20+
- Java (for Firestore emulator)
- Firebase CLI via npx: `npx -y firebase-tools@latest --version`

## Local emulators

Start Auth, Firestore, Functions, and the Emulator UI:

```bash
npx -y firebase-tools@latest emulators:start --project demo-family-finance
```

UI: http://127.0.0.1:4000  
Ports: Auth `9099`, Firestore `8080`, Functions `5001`.

Install Functions dependencies once:

```bash
cd functions && npm install && npm run build && cd ..
```

### Flutter against emulators

Start the suite with `--project demo-family-finance`, then run the app with either
`USE_EMULATORS` or `EMULATOR_ONLY` (both reuse FlutterFire apiKey/appId with
project id `demo-family-finance` so Auth/Firestore/Functions paths match).

```bash
flutter run -d chrome \
  --dart-define=USE_EMULATORS=true
# or: --dart-define=EMULATOR_ONLY=true
```

**Android emulator (AVD):** same defines. The app defaults the emulator host to
`10.0.2.2` (the AVD’s alias for the host machine). Debug builds allow cleartext
HTTP to that host.

```bash
flutter run -d android \
  --dart-define=USE_EMULATORS=true
```

**Physical Android device:** phone and PC on the same Wi‑Fi. Emulators bind
`0.0.0.0` (`firebase.json`). Pass the PC’s **LAN IP** — never `127.0.0.1` /
`localhost` on Android: the Firebase Flutter plugins remap those to
`10.0.2.2` (AVD-only), which breaks physical devices.

```bash
# emulators already running
./scripts/run_physical_android_emulators.sh
# or explicitly:
flutter run -d <device> \
  --dart-define=USE_EMULATORS=true \
  --dart-define=EMULATOR_HOST=192.168.31.205
```

**Advanced — keep real FlutterFire project id** (must start emulators with the
same id, e.g. `family-finance-gmstyle-app`):

```bash
npx -y firebase-tools@latest emulators:start --project family-finance-gmstyle-app
flutter run -d chrome \
  --dart-define=USE_EMULATORS=true \
  --dart-define=EMULATOR_USE_FIREBASE_OPTIONS=true
```

Optional overrides: `EMULATOR_HOST`, `AUTH_EMULATOR_PORT`, `FIRESTORE_EMULATOR_PORT`, `FUNCTIONS_EMULATOR_PORT`. Web/desktop default host is `127.0.0.1`.

Emulator mode signs out on cold start (avoids stale “invalid refresh token”). If you still see that error, clear app data (Android: Settings → Apps → Family Finance → Clear storage) or hard-refresh the web tab, then sign in again.

### Flutter against real Firebase

Omit emulator defines (default):

```bash
flutter run -d chrome
```

Android:

```bash
flutter run -d android
```

## Tests

Money unit tests:

```bash
flutter test test/money_test.dart
```

Firestore rules (starts the Firestore emulator automatically):

```bash
cd test/rules
npm install
npm test
```

(`npm test` runs from repo root via `firebase emulators:exec` and needs Java.)

## Project layout

```text
lib/
  l10n/                 # en + it ARB
  core/                 # di, router, theme, locale, money, firebase bootstrap
    theme/              # AppTheme, breakpoints, spacing/radius/sizes tokens
    ui/                 # AppPage, AppSectionTitle
  features/auth|family  # Phase 2
  features/settings …
functions/              # TypeScript Cloud Functions (membership callables)
firestore.rules
firestore.indexes.json
```

### UI design tokens

Material 3 Expressive-inspired tokens live under `lib/core/theme/`:

| File | Role |
|------|------|
| `app_breakpoints.dart` | mobile &lt;600 / tablet 600–839 / wide ≥840; `AppBreakpoint.of`, rail helper |
| `app_tokens.dart` | `AppSpacing`, `AppRadius` (incl. asymmetric hero), `AppSizes`, `AppInsets`, `AppDurations`, `AppExtraColors` ThemeExtension |
| `app_theme.dart` | `AppTheme.light()` / `dark()` — ColorScheme seed, TextTheme, component themes |
| `lib/core/ui/app_page.dart` | centered max-width page + section titles |

Prefer tokens over magic numbers when adding Phase 3+ screens. Interactive mock: `docs/family-finance-ui-mock.canvas.tsx`.

## Phase status

- **Phase 1** — foundations (done)
- **Phase 2** — Auth + family (done): email/password, Google Sign-In, verify/reset, createFamily / invites / accept / leave, router gates, invite deep link `/invite/:token`
- **Phase 3** — ledger (done)
- **Phase 4** — budgets, goals, dashboard, FCM (done)
- **Phase 5** — receipt OCR → Ingestion drafts (done)
- **Phase 6** — Android notification ingest → Ingestion drafts (done): `NotificationListenerService` (Google Wallet allowlist via Remote Config), parse → draft only, aggregated local alerts, confirm/discard in review queue
- **Phase 7** — pre-release (done): account deletion (sole-member family wipe with warning), JSON export, in-app privacy policy, Play notification-listener declaration — see [`docs/privacy-policy.md`](docs/privacy-policy.md) and [`docs/play-notification-listener.md`](docs/play-notification-listener.md)

### Privacy & data (Settings)

1. **Privacy policy** — in-app at Settings → Privacy & data (en/it assets under `assets/legal/`). Host [`docs/privacy-policy.md`](docs/privacy-policy.md) at a public URL before Play publication.
2. **Export** — JSON of member-readable family data via the system share sheet.
3. **Delete account** — reauth required; if you are the only family member, an explicit warning appears and the family ledger is wiped server-side.

### Notification ingest (Android)

1. Sign in with a family, open **Settings → Payment notification capture**, and enable Family Finance in the system notification-access screen.
2. Optionally set **Account bindings** (package → suggested account).
3. Trigger a Google Wallet / allowlisted payment notification (or post a test notification from that package).
4. The app creates an Ingestion draft (`needsReview` / `possibleDuplicate`) — never a ledger transaction — and shows an aggregated local notification unless you are already on the review queue.
5. Confirm or discard in **Review queue** (same UI as OCR; works on web too). Capture itself is Android-only / no-op on web.

Remote Config keys (optional): `notification_package_allowlist` (JSON string array), `notification_parse_patterns` (JSON with `amountPatterns` / `merchantPatterns` / `datePatterns` regex lists).

### Auth notes

1. In Firebase Console enable **Email/Password** (and Google if you use it).
2. Configure **OAuth consent screen** + Web/Android OAuth clients for Google Sign-In.
3. Emulator: email verification links appear in Auth emulator UI; invite links are copied from Family → Invites (no Trigger Email required locally).
4. Callables run in region `europe-west1` — start Functions emulator with the rest of the suite.

```bash
npx -y firebase-tools@latest emulators:start --project demo-family-finance
# then (project id must be demo-family-finance — USE_EMULATORS does that)
flutter run -d chrome --dart-define=USE_EMULATORS=true
```
