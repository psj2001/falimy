/**
 * Falimy Cloud Functions — family invite emails.
 *
 * Deploy:
 *   cd functions && npm install && firebase deploy --only functions
 *
 * Secrets (Gmail App Password recommended):
 *   firebase functions:secrets:set GMAIL_USER
 *   firebase functions:secrets:set GMAIL_APP_PASSWORD
 */
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");
const nodemailer = require("nodemailer");

initializeApp();

const gmailUser = defineSecret("GMAIL_USER");
const gmailAppPassword = defineSecret("GMAIL_APP_PASSWORD");

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

exports.sendFamilyInvite = onCall(
  {
    region: "us-central1",
    secrets: [gmailUser, gmailAppPassword],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to send invites.");
    }

    const uid = request.auth.uid;
    const data = request.data || {};
    const inviteeEmail = normalizeEmail(data.inviteeEmail);
    const memberKey = String(data.memberKey || "").trim();
    const memberName = String(data.memberName || "").trim();
    const memberKind = String(data.memberKind || "").trim();
    const memberRole = String(data.memberRole || "").trim();
    const familyName = data.familyName
      ? String(data.familyName).trim()
      : null;

    if (!isValidEmail(inviteeEmail)) {
      throw new HttpsError("invalid-argument", "Enter a valid email address.");
    }
    if (!memberKey || !memberName || !memberKind || !memberRole) {
      throw new HttpsError("invalid-argument", "Missing member details.");
    }

    const db = getFirestore();
    const inviterSnap = await db.collection("users").doc(uid).get();
    const inviterData = inviterSnap.data() || {};
    const inviterName =
      inviterData.fullName ||
      request.auth.token.email ||
      "A family member";

    const authEmail = normalizeEmail(request.auth.token.email || "");
    if (authEmail && authEmail === inviteeEmail) {
      throw new HttpsError(
        "invalid-argument",
        "You cannot invite your own email address.",
      );
    }

    // Avoid duplicate pending invites for the same member + email.
    const existing = await db
      .collection("invites")
      .where("inviterUserId", "==", uid)
      .where("memberKey", "==", memberKey)
      .where("inviteeEmail", "==", inviteeEmail)
      .where("status", "==", "pending")
      .limit(1)
      .get();

    let inviteRef;
    if (!existing.empty) {
      inviteRef = existing.docs[0].ref;
      await inviteRef.set(
        {
          memberName,
          memberKind,
          memberRole,
          familyName,
          inviterName,
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    } else {
      inviteRef = db.collection("invites").doc();
      await inviteRef.set({
        inviteeEmail,
        inviterUserId: uid,
        inviterName,
        memberKey,
        memberName,
        memberKind,
        memberRole,
        familyName,
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    const user = gmailUser.value();
    const pass = gmailAppPassword.value();
    if (!user || !pass) {
      throw new HttpsError(
        "failed-precondition",
        "Email is not configured. Set GMAIL_USER and GMAIL_APP_PASSWORD secrets.",
      );
    }

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {user, pass},
    });

    const subject = `${inviterName} invited you to Falimy as ${memberName}`;
    const text = [
      `Hi${memberName ? ` ${memberName}` : ""},`,
      "",
      `${inviterName} invited you to join their family tree on Falimy as "${memberRole}".`,
      "",
      "1. Install the Falimy app",
      `2. Create an account using this email: ${inviteeEmail}`,
      "3. You will automatically be linked to their family tree",
      "",
      "If you did not expect this invite, you can ignore this email.",
      "",
      "— Falimy",
    ].join("\n");

    const html = `
      <div style="font-family: Georgia, serif; color: #1B4332; line-height: 1.5;">
        <h2 style="color: #2D6A4F;">You're invited to Falimy</h2>
        <p><strong>${inviterName}</strong> invited you to join their family tree as
        <strong>${memberName}</strong> (${memberRole}).</p>
        <ol>
          <li>Install the Falimy app</li>
          <li>Sign up with <strong>${inviteeEmail}</strong></li>
          <li>You'll be identified automatically as this family member</li>
        </ol>
        <p style="color: #52796F; font-size: 14px;">
          Use exactly this email when registering so we can match the invite.
        </p>
      </div>
    `;

    try {
      await transporter.sendMail({
        from: `"Falimy" <${user}>`,
        to: inviteeEmail,
        subject,
        text,
        html,
      });
    } catch (err) {
      console.error("sendMail failed", err);
      throw new HttpsError(
        "internal",
        "Could not send the invitation email. Check Gmail credentials.",
      );
    }

    // Best-effort: if invitee already has an account, leave for claim on next login.
    try {
      await getAuth().getUserByEmail(inviteeEmail);
    } catch (_) {
      // User does not exist yet — expected.
    }

    return {inviteId: inviteRef.id, status: "pending"};
  },
);

/**
 * Called after sign-up (or sign-in) so an invited email is linked
 * to the matching family-tree member.
 */
exports.claimFamilyInvites = onCall(
  {region: "us-central1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to claim invites.");
    }

    const uid = request.auth.uid;
    const email = normalizeEmail(
      request.auth.token.email || request.data?.email || "",
    );
    if (!isValidEmail(email)) {
      throw new HttpsError("invalid-argument", "Account has no valid email.");
    }

    const db = getFirestore();
    const pending = await db
      .collection("invites")
      .where("inviteeEmail", "==", email)
      .where("status", "==", "pending")
      .get();

    if (pending.empty) {
      return {claimed: []};
    }

    const claimed = [];
    const batch = db.batch();

    for (const doc of pending.docs) {
      const invite = doc.data();
      batch.update(doc.ref, {
        status: "accepted",
        acceptedUserId: uid,
        acceptedAt: FieldValue.serverTimestamp(),
      });

      batch.set(
        db.collection("users").doc(invite.inviterUserId),
        {
          memberLinks: {
            [invite.memberKey]: {
              userId: uid,
              email,
              name: invite.memberName,
              kind: invite.memberKind,
              role: invite.memberRole,
              linkedAt: FieldValue.serverTimestamp(),
            },
          },
        },
        {merge: true},
      );

      batch.set(
        db.collection("users").doc(uid),
        {
          email,
          fullName: invite.memberName || null,
          familyName: invite.familyName || null,
          linkedFromInvites: FieldValue.arrayUnion([
            {
              inviteId: doc.id,
              inviterUserId: invite.inviterUserId,
              inviterName: invite.inviterName || "",
              memberKey: invite.memberKey,
              memberName: invite.memberName,
              memberKind: invite.memberKind,
              memberRole: invite.memberRole,
              familyName: invite.familyName || null,
            },
          ]),
        },
        {merge: true},
      );

      claimed.push({
        inviteId: doc.id,
        memberName: invite.memberName,
        memberRole: invite.memberRole,
        inviterName: invite.inviterName || "",
        familyName: invite.familyName || null,
      });
    }

    await batch.commit();
    return {claimed};
  },
);
