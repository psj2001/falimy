const nodemailer = require('nodemailer');
const config = require('../config');

let transporterPromise;

function isMailConfigured() {
  return Boolean(config.smtpUser && config.smtpPass);
}

function escapeHtml(value) {
  return String(value || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

async function getTransporter() {
  if (!isMailConfigured()) {
    return null;
  }

  if (!transporterPromise) {
    transporterPromise = Promise.resolve(
      nodemailer.createTransport({
        host: config.smtpHost,
        port: config.smtpPort,
        secure: config.smtpSecure,
        auth: {
          user: config.smtpUser,
          pass: config.smtpPass,
        },
      }),
    );
  }

  return transporterPromise;
}

/**
 * Sends a 6-digit signup OTP via free SMTP (Gmail App Password, Brevo, etc.).
 * When SMTP is not configured, logs the OTP for local development.
 */
async function sendSignupOtp({ to, otp }) {
  const subject = 'Your Falimy verification code';
  const text = [
    'Welcome to Falimy!',
    '',
    `Your verification code is: ${otp}`,
    '',
    'This code expires in 10 minutes.',
    'If you did not create an account, you can ignore this email.',
  ].join('\n');

  const html = `
    <div style="font-family: system-ui, sans-serif; max-width: 480px; margin: 0 auto;">
      <h2 style="color: #1a1a1a;">Welcome to Falimy</h2>
      <p>Use this code to verify your email and finish creating your account:</p>
      <p style="font-size: 28px; font-weight: 700; letter-spacing: 6px; color: #1a1a1a;">${otp}</p>
      <p style="color: #666;">This code expires in 10 minutes.</p>
    </div>
  `;

  const transporter = await getTransporter();
  if (!transporter) {
    console.warn(
      `[mail] SMTP not configured — OTP for ${to}: ${otp} (set SMTP_USER / SMTP_PASS)`,
    );
    return { delivered: false, reason: 'smtp_not_configured' };
  }

  await transporter.sendMail({
    from: config.mailFrom,
    to,
    subject,
    text,
    html,
  });

  return { delivered: true };
}

async function sendFamilyInvite({
  to,
  inviterName,
  memberName,
  memberRole,
  familyName,
  referralCode,
}) {
  const fromName = inviterName || 'A family member';
  const safeFrom = escapeHtml(fromName);
  const safeMember = escapeHtml(memberName || 'there');
  const safeRole = escapeHtml(memberRole);
  const safeFamily = familyName ? escapeHtml(familyName) : '';
  const safeCode = escapeHtml(referralCode);
  const safeTo = escapeHtml(to);
  const familyLine = familyName ? ` of the ${familyName} family` : '';
  const safeFamilyLine = safeFamily ? ` of the ${safeFamily} family` : '';
  const subject = `${fromName} invited you to Falimy`;
  const text = [
    `Hi ${memberName || 'there'},`,
    '',
    `${fromName} invited you to join their family tree on Falimy${familyLine} as "${memberRole}".`,
    '',
    `Your referral code is: ${referralCode}`,
    '',
    'To join:',
    '1. Install the Falimy app',
    '2. Open Sign up and choose Join with a referral code',
    `3. Enter this code (${referralCode}) — we will show who invited you and your relation`,
    `4. Create your account with this email: ${to}`,
    '',
    'If you did not expect this invite, you can ignore this email.',
    '',
    '— Falimy',
  ].join('\n');

  const html = `
    <div style="font-family: Georgia, 'Times New Roman', serif; max-width: 520px; margin: 0 auto; color: #1b4332;">
      <h2 style="margin-bottom: 8px;">You're invited to Falimy</h2>
      <p>Hi ${safeMember},</p>
      <p>${safeFrom} invited you to join their family tree${safeFamilyLine} as <strong>${safeRole}</strong>.</p>
      <p style="margin: 24px 0 8px;">Your referral code</p>
      <p style="font-size: 28px; font-weight: 700; letter-spacing: 4px; color: #1a1a1a;">${safeCode}</p>
      <p>On Sign up, tap <strong>Join with a referral code</strong> and enter this code. Falimy will show who invited you and your relation.</p>
      <p>Create your account with <strong>${safeTo}</strong> so we can link you to the family tree.</p>
      <p style="color: #666; font-size: 14px;">If you did not expect this invite, you can ignore this email.</p>
    </div>
  `;

  const transporter = await getTransporter();
  if (!transporter) {
    console.warn(
      `[mail] SMTP not configured — family invite for ${to}: ${referralCode}`,
    );
    return { delivered: false, reason: 'smtp_not_configured' };
  }

  await transporter.sendMail({
    from: config.mailFrom,
    to,
    subject,
    text,
    html,
  });

  return { delivered: true };
}

module.exports = {
  isMailConfigured,
  sendSignupOtp,
  sendFamilyInvite,
};
