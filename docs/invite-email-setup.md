# Family invite email (production)

Invites use a **universal HTTPS link**:

`https://family-finance-gmstyle-app.web.app/invite/<token>`

- **Web:** Flutter SPA + `go_router` route `/invite/:token`
- **Android:** App Links (`AndroidManifest` + `/.well-known/assetlinks.json` on Hosting)

## Email delivery (self-managed Cloud Functions)

We **do not** use Firebase Extensions for email. Extensions are [deprecated and shut down on 31 March 2027](https://firebase.google.com/docs/extensions/faq-and-troubleshooting); **Trigger Email** has **no official function-kit replacement**.

Instead, `createInvite` sends mail directly via **SMTP** (`nodemailer`) inside the callable.

### 1. Configure SMTP secrets / params

From the repo root, project `family-finance-gmstyle-app`:

```bash
# Required secret (Gmail app password, SendGrid SMTP password, etc.)
npx -y firebase-tools@latest functions:secrets:set SMTP_PASSWORD \
  --project family-finance-gmstyle-app

# Optional params (defaults shown) — set in Firebase Console → Functions → Environment
# or via .env / params files for your deploy workflow:
#   SMTP_HOST=smtp.gmail.com
#   SMTP_PORT=465
#   SMTP_SECURE=true
#   SMTP_USER=your-sender@gmail.com
#   SMTP_FROM="Family Finance <your-sender@gmail.com>"
```

**Gmail:** use an [App Password](https://support.google.com/accounts/answer/185833) (2FA required), not your normal account password.

### 2. Deploy `createInvite`

```bash
cd functions && npm install && npm run build && cd ..
npx -y firebase-tools@latest deploy \
  --project family-finance-gmstyle-app \
  --only functions:createInvite
```

### 3. Smoke test

1. Admin → Family → invite an email you control
2. Snackbar: *Invite email sent* (if SMTP configured) or *link copied* if not
3. Open the link on web or Android

If SMTP is missing, the invite is still created and the app copies the link.

Optional link base override: `INVITE_LINK_BASE_URL` (defaults to Hosting URL).

## Android App Links

`hosting/public/.well-known/assetlinks.json` includes the **debug** keystore SHA-256.  
When you create a **release** keystore, append its SHA-256 fingerprint and redeploy Hosting (`./scripts/deploy_web_hosting.sh`).

Verify: [Digital Asset Links](https://developers.google.com/digital-asset-links/v1/statements)
