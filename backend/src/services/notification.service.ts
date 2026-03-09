import admin from "firebase-admin";
import { supabaseAdmin } from "../config/supabase";

// Initialize Firebase Admin (only once)
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FCM_PROJECT_ID,
        privateKey: process.env.FCM_PRIVATE_KEY?.replace(/\\n/g, "\n"),
        clientEmail: process.env.FCM_CLIENT_EMAIL,
      }),
    });
  } catch {
    console.warn("Firebase Admin initialization skipped (missing credentials)");
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
