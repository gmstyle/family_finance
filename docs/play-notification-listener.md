# Play declaration — `BIND_NOTIFICATION_LISTENER_SERVICE`

Use this text when declaring sensitive permissions / Data safety for Family Finance on Google Play.

## Permission

- **Android permission / service:** `android.permission.BIND_NOTIFICATION_LISTENER_SERVICE`
- **Component:** `BankNotificationListenerService` (`android/app/src/main/AndroidManifest.xml`)
- **User control:** Settings → Payment notification capture → system Notification access screen. Capture is Android-only; web is a no-op for capture (review queue still works).

## Declared purpose

Family Finance listens only to **allowlisted payment / wallet packages** (default Google Wallet; extendable via Firebase Remote Config `notification_package_allowlist`) to extract payment amount, date, and merchant into an **Ingestion draft** that the user must confirm or discard.

## What we do **not** do

- We do **not** create ledger transactions silently from notifications.
- We do **not** persist raw notification title/body/text.
- We do **not** read SMS, call logs, or unrelated app notifications outside the allowlist.
- We do **not** sell notification content.

## Data handling

1. Parse on-device → write draft fields (`amountMinor`, `bookingDate`, `merchant`, suggested `accountId` / `categoryId`) under `families/{id}/ingestion/{dedupKey}`.
2. Alert the user with an aggregated local notification (“N drafts to review”) unless the review queue is already open.
3. User confirms → creates a normal confirmed transaction; or discards the draft.

## Data safety form hints

| Question | Suggested answer |
|----------|------------------|
| Collects financial info? | Yes — user-entered / confirmed ledger amounts in Firestore |
| Collects personal info? | Yes — email, display name |
| Notification access? | Yes — used only to create review drafts from allowlisted payment apps |
| Data encrypted in transit? | Yes (Firebase TLS) |
| Users can request deletion? | Yes — Settings → Delete account (sole member may wipe family data after warning) |

## Remote Config (optional)

- `notification_package_allowlist` — JSON string array of package names
- `notification_parse_patterns` — JSON with regex lists for amount / merchant / date
