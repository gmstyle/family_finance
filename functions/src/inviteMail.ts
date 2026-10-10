/**
 * Send family invite emails from Cloud Functions (self-managed SMTP).
 * Does not use Firebase Extensions (deprecated March 2027).
 */
import nodemailer from "nodemailer";
import {defineSecret, defineString} from "firebase-functions/params";

const DEFAULT_INVITE_BASE_URL = "https://family-finance-gmstyle-app.web.app";

export const smtpPassword = defineSecret("SMTP_PASSWORD");

const smtpHost = defineString("SMTP_HOST", {default: "smtp.gmail.com"});
const smtpPort = defineString("SMTP_PORT", {default: "465"});
const smtpSecure = defineString("SMTP_SECURE", {default: "true"});
const smtpUser = defineString("SMTP_USER", {default: ""});
const smtpFrom = defineString("SMTP_FROM", {default: ""});

export function inviteLinkBaseUrl(): string {
  const fromEnv = process.env.INVITE_LINK_BASE_URL?.trim();
  return (fromEnv && fromEnv.length > 0 ? fromEnv : DEFAULT_INVITE_BASE_URL)
    .replace(/\/$/, "");
}

export function buildInviteUrl(token: string): string {
  return `${inviteLinkBaseUrl()}/invite/${token}`;
}

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function buildInviteBodies(params: {
  inviteLink: string;
  familyName: string;
  inviterDisplayName: string;
}): {subject: string; text: string; html: string} {
  const familyName = params.familyName.trim() || "Family Finance";
  const inviter = params.inviterDisplayName.trim() || "A family admin";
  const link = params.inviteLink;
  const subject = `You're invited to ${familyName} on Family Finance`;
  const text =
    `${inviter} invited you to join "${familyName}" on Family Finance.\n\n` +
    `Open this link to accept (sign in with this email address):\n${link}\n\n` +
    "The link expires in 7 days.";
  const html =
    `<p>${escapeHtml(inviter)} invited you to join ` +
    `<strong>${escapeHtml(familyName)}</strong> on Family Finance.</p>` +
    `<p><a href="${escapeHtml(link)}">Accept invite</a></p>` +
    `<p>Or copy this link:<br><code>${escapeHtml(link)}</code></p>` +
    "<p>The link expires in 7 days. Sign in with the same email this invite was sent to.</p>";
  return {subject, text, html};
}

/** True when invite email was handed off to SMTP. */
export async function sendInviteEmail(params: {
  to: string;
  inviteLink: string;
  familyName: string;
  inviterDisplayName: string;
}): Promise<boolean> {
  if (process.env.FUNCTIONS_EMULATOR === "true") {
    return false;
  }

  const user = smtpUser.value().trim();
  const pass = smtpPassword.value();
  if (!user || !pass) {
    console.warn(
      "invite email skipped: set SMTP_USER and secret SMTP_PASSWORD " +
        "(see docs/invite-email-setup.md)",
    );
    return false;
  }

  const {subject, text, html} = buildInviteBodies(params);
  const from = smtpFrom.value().trim() || user;
  const port = Number.parseInt(smtpPort.value(), 10) || 465;
  const secure = smtpSecure.value().toLowerCase() !== "false";

  const transporter = nodemailer.createTransport({
    host: smtpHost.value(),
    port,
    secure,
    auth: {user, pass},
  });

  await transporter.sendMail({
    from,
    to: params.to,
    subject,
    text,
    html,
  });

  return true;
}
