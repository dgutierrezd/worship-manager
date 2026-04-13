import admin from "firebase-admin";
import { supabaseAdmin } from "../config/supabase";

/**
 * Normalises a PEM private key that came from a hosting-provider env var
 * (Vercel, Render, Heroku, etc.). Handles every common paste mistake:
 *
 *  1. Surrounding double or single quotes (Vercel sometimes preserves the
 *     JSON quotes if you copy `"private_key": "..."` verbatim).
 *  2. Literal `\n` escape sequences instead of real newlines.
 *  3. CRLF line endings (Windows clipboards).
 *  4. Trailing whitespace.
 */
function normaliseFcmPrivateKey(raw: string | undefined): string | undefined {
  if (!raw) return undefined;
  let key = raw.trim();
  if ((key.startsWith('"') && key.endsWith('"')) ||
      (key.startsWith("'") && key.endsWith("'"))) {
    key = key.slice(1, -1);
  }
  // Convert literal "\n" sequences to real newlines.
  key = key.replace(/\\n/g, "\n");
  // Normalise CRLF → LF.
  key = key.replace(/\r\n/g, "\n");
  return key;
}

// Initialize Firebase Admin (only once per cold start)
if (!admin.apps.length) {
  const projectId  = process.env.FCM_PROJECT_ID;
  const clientEmail = process.env.FCM_CLIENT_EMAIL;
  const privateKey  = normaliseFcmPrivateKey(process.env.FCM_PRIVATE_KEY);

  if (!projectId || !clientEmail || !privateKey) {
    console.warn(
      "[FCM] Skipping Firebase Admin init — missing env vars:",
      {
        FCM_PROJECT_ID:   !!projectId,
        FCM_CLIENT_EMAIL: !!clientEmail,
        FCM_PRIVATE_KEY:  !!privateKey,
      }
    );
  } else if (!privateKey.includes("BEGIN PRIVATE KEY")) {
    console.error(
      "[FCM] FCM_PRIVATE_KEY does not look like a PEM key " +
      "(missing BEGIN PRIVATE KEY header). Check the Vercel env var — " +
      "paste the value of `private_key` from the service-account JSON " +
      "WITHOUT the surrounding quotes."
    );
  } else {
    try {
      admin.initializeApp({
        credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
      });
      console.log("[FCM] Firebase Admin initialised for project:", projectId);
    } catch (err) {
      console.error("[FCM] Firebase Admin init failed:", err);
    }
  }
}

export async function notifyBandMembers(
  bandId: string,
  excludeUserId: string,
  title: string,
  body: string
): Promise<void> {
  try {
    if (!admin.apps.length) return;

    // Fetch all member user IDs except the sender
    const { data: members } = await supabaseAdmin
      .from("band_members")
      .select("user_id")
      .eq("band_id", bandId)
      .neq("user_id", excludeUserId);

    const userIds = members?.map((m) => m.user_id) ?? [];
    if (userIds.length === 0) return;

    // Fetch device tokens for those users
    const { data: tokens } = await supabaseAdmin
      .from("device_tokens")
      .select("token")
      .in("user_id", userIds);

    if (!tokens || tokens.length === 0) return;

    const messages = tokens.map((t) => ({
      token: t.token,
      notification: { title, body },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
    }));

    const results = await Promise.allSettled(
      messages.map((msg) => admin.messaging().send(msg))
    );

    const failures = results.filter((r) => r.status === "rejected").length;
    if (failures > 0) {
      console.warn(`Push notifications: ${failures}/${results.length} failed`);
    }
  } catch (error) {
    console.error("Failed to send push notifications:", error);
  }
}
