# Privacy Policy — Family Finance

**Last updated:** 4 October 2026

This document mirrors the in-app privacy text (`assets/legal/privacy_en.md` / `privacy_it.md`) and the static Hosting pages (`hosting/public/privacy.html`, `privacy-it.html`).

**Privacy contact:** contattagmstyle@gmail.com

## Summary

Family Finance processes account credentials (Firebase Auth), shared family ledger data in Cloud Firestore, FCM device tokens for budget alerts, and short-lived ingestion draft fields from on-device receipt OCR or Android payment-notification capture. Raw notification text and receipt photos are not stored. Ledger transactions are never created silently from OCR or notifications.

## Full policy

See the English in-app asset for the complete clauses (data categories, purposes, on-device processing, sharing, retention/deletion including sole-member family wipe, rights, children, changes). Italian: `assets/legal/privacy_it.md`.

## Public URL

- App (Flutter web): `https://family-finance-gmstyle-app.web.app/`
- English privacy: `https://family-finance-gmstyle-app.web.app/privacy.html` (also `/privacy`)
- Italian privacy: `https://family-finance-gmstyle-app.web.app/privacy-it.html` (also `/privacy-it`)

Redeploy via `./scripts/deploy_web_hosting.sh` (build + privacy overlay + hosting). Use the English HTTPS URL in Play Console → App content → Privacy policy.
