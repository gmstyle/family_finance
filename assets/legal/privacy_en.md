# Privacy Policy — Family Finance

**Last updated:** 4 October 2026

This policy describes how Family Finance (“the app”) handles your data. We designed the product so that shared ledger data belongs to your family, while account credentials stay with Firebase Authentication.

## Who we are

Family Finance is a shared household ledger for confirmed transactions, budgets, and virtual goals. Contact for privacy requests: replace this placeholder with your support email before publishing a public URL.

## Data we process

- **Account:** email, display name, authentication identifiers (Firebase Auth).
- **Family ledger:** accounts, categories, transactions, transfers, budgets and period spent, goals and contributions, monthly stats rollups.
- **Ingestion drafts:** amount, booking date, merchant, suggested account/category from receipt OCR or payment notifications — never the raw notification text or receipt photo.
- **Device tokens:** FCM tokens for budget threshold alerts (stored under your user profile devices).
- **Preferences:** UI language stored on-device (`shared_preferences`).

## How we use data

- Provide the shared ledger and membership features.
- Project balances, budget periods, and stats via Cloud Functions (server-side only).
- Send budget threshold notifications (80% / 100%) when you have registered devices.
- Create review drafts from on-device OCR or Android notification capture — **transactions are created only after you confirm**.

## On-device processing

- **Receipt OCR (Android):** text recognition runs on-device (ML Kit). Photos are not uploaded to our servers.
- **Notification listener (Android):** payment notifications from allowlisted packages are parsed on-device into draft fields. Raw notification bodies are not persisted.

## Sharing

We do not sell personal data. Data is processed with Google Firebase (Auth, Firestore, Functions, Messaging, Remote Config) as infrastructure. Family members you invite can read and write the shared ledger according to app rules.

## Retention and deletion

- You can export a JSON copy of member-readable family data from Settings.
- You can delete your account from Settings. If you are the only family member, deletion also permanently removes that family’s ledger after an explicit confirmation. If other members remain, you must transfer ownership / promote another admin first; shared data stays with the family.

## Your rights

Depending on your jurisdiction you may request access, correction, or deletion of personal data. Use in-app export/delete where available, or contact the email above once published.

## Children

The app is not directed at children under 13 (or the equivalent minimum age in your country).

## Changes

We may update this policy. The in-app copy and `docs/privacy-policy.md` will be revised together; host a public URL before Play Store publication.
