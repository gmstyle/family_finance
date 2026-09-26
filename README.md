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

**Emulator-only** (demo project id, no real credentials):

```bash
flutter run -d chrome \
  --dart-define=EMULATOR_ONLY=true
```

**Configured FlutterFire project + emulators** (uses real `firebase_options.dart`, still talks to local emulators):

```bash
flutter run -d chrome \
  --dart-define=USE_EMULATORS=true
```

Optional overrides: `EMULATOR_HOST`, `AUTH_EMULATOR_PORT`, `FIRESTORE_EMULATOR_PORT`, `FUNCTIONS_EMULATOR_PORT`.

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

## Project layout (Phase 1)

```text
lib/
  l10n/                 # en + it ARB
  core/                 # di, router, theme, locale, money, firebase bootstrap
  features/             # settings + empty feature folders for later phases
  shared/
functions/              # TypeScript Cloud Functions scaffold
firestore.rules
firestore.indexes.json
```

## Phase status

Phase 1 (foundations) is in place: l10n, Money, Material 3 shell, router, Firebase bootstrap, rules + tests, Functions stub. Auth, family callables, and ledger CRUD are **not** implemented yet (Phase 2+).
