# AGENTS.md — Family Finance

Guidance for AI coding agents working in this repository.

## Product

Shared family ledger (Flutter + Firebase): authenticated households, accounts, categories, confirmed transactions, budgets, goals, receipt OCR / notification ingestion drafts, and privacy/export/account lifecycle.

- Locales: **Italian + English** (`lib/l10n/`, ARB → generated `app_localizations*.dart`)
- Firebase project: `family-finance-gmstyle-app` (already wired). Do **not** re-run `flutterfire configure` unless platforms intentionally change.
- Emulator project id for local work: `demo-family-finance`

## Stack

| Layer | Tech |
|---|---|
| App | Flutter (stable), Dart ^3.13, Material 3 |
| State | `provider` |
| Navigation | `go_router` (`StatefulShellRoute`) |
| Backend | Firebase Auth, Firestore, Cloud Functions (`europe-west1`), FCM, Remote Config |
| Functions | TypeScript under `functions/` |
| Fonts / UI | Plus Jakarta Sans (`google_fonts`), Kinship design tokens |

## Layout (where to edit)

```text
lib/
  main.dart                 # MaterialApp.router, themeMode, providers
  core/
    theme/                  # AppPalette, AppTheme, AppTokens, ThemeModeController
    ui/                     # KinshipScaffold, Kinship* widgets, AppPage
    router/app_router.dart  # routes + auth redirects
    di/app_providers.dart
    money/, locale/, invite/, errors/
  features/<feature>/
    data/ | domain/ | presentation/
  l10n/                     # app_en.arb, app_it.arb (+ generated)
functions/                  # callables + ledger triggers
firestore.rules
firestore.indexes.json
docs/                       # privacy, invite email, Play listener notes
scripts/                    # deploy helpers, physical-device emulator runner
```

Feature folders are the unit of work (auth, family, accounts, categories, transactions, budgets, goals, dashboard, receipt_ocr, notification_ingest, settings, devices).

## UI / design system (Kinship)

UI follows the Stitch **Kinship Finance** system (teal primary, terracotta secondary, Plus Jakarta, pill controls, L1 card elevation).

- Tokens: `lib/core/theme/app_tokens.dart`, `app_theme.dart`, `app_breakpoints.dart`
- Shared widgets: `package:family_finance/core/ui/kinship_widgets.dart`
- Shell: `KinshipScaffold` — wide sidebar (~288px) + top bar; compact header + **4-tab** bottom nav + FAB
- Auth chrome: `KinshipAuthScaffold` / `KinshipAuthPanel`

Prefer tokens and Kinship widgets over hard-coded colors/spacing. Do not reintroduce a 5th bottom-nav tab for Settings.

### Shell destinations

1. `/` — Dashboard  
2. `/transactions` — Ledger  
3. `/ingestion` — Review queue (badge from pending drafts)  
4. `/budgets` — Budget & Goals (unified; `/goals` → `/budgets?tab=goals`)

Settings (`/settings`) and Family (`/family`) are **outside** the indexed shell (header/sidebar links). Full-screen editors (`/transactions/new`, budget/goal edit, `/ingestion/:id`, …) stay top-level.

**Navigation caveat:** do not `context.push` a shell branch route from a page that was itself `push`ed on top of the shell (duplicate `ShellRouteMatch` pageKey). Prefer `context.go` to switch shell tabs.

## Architecture rules

- Keep **presentation** thin: controllers + repositories own Firebase/IO.
- Do not rewrite Firestore schema, rules, or Cloud Functions unless the task explicitly requires backend work.
- Money amounts: use existing money helpers / tabular amount text styles.
- New user-facing strings: add keys to **both** `app_en.arb` and `app_it.arb`, then regenerate (`flutter gen-l10n` via build) — avoid hardcoded UI copy when the screen already uses l10n.
- Match existing patterns in the feature you touch (naming, error surfacing, `LedgerAsyncBody`, etc.).

## Local commands

### Emulators

```bash
npx -y firebase-tools@latest emulators:start --project demo-family-finance
# UI http://127.0.0.1:4000 — Auth 9099, Firestore 8080, Functions 5001
```

```bash
cd functions && npm install && npm run build && cd ..
```

### Flutter

```bash
flutter run -d chrome --dart-define=USE_EMULATORS=true
flutter run -d android --dart-define=USE_EMULATORS=true
# Physical Android: pass LAN IP — see README (never localhost on device)
```

### Tests

```bash
flutter test test/money_test.dart
cd test/rules && npm install && npm test   # needs Java + Firestore emulator
```

### Deploy (only when asked)

- Backend: `npx -y firebase-tools@latest deploy --project family-finance-gmstyle-app --only firestore,functions`
- Web hosting: `./scripts/deploy_web_hosting.sh`

## Required finish checklist

After every completed implementation (feature, fix, refactor, UI):

1. `dart format` on changed paths (or `lib/` if broad).
2. `flutter analyze` — fix issues you introduced; call out pre-existing noise.
3. Do not claim done until both succeed (or remaining issues are documented).

(Optional local Cursor rule under `.cursor/rules/` — that directory is gitignored.)

## Out of scope defaults

Unless the user asks otherwise:

- No force-push / destructive git
- No commits unless explicitly requested
- No `flutterfire configure` / changing Firebase project wiring
- No inventing product features that only appear as Stitch mock chrome without domain support (leave placeholder or wire existing data)
