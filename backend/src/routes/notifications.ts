import { Router, Response } from "express";
import admin from "firebase-admin";
import { supabaseAdmin } from "../config/supabase";
import { authMiddleware, AuthRequest } from "../middleware/auth.middleware";

const router = Router();

// POST /notifications/register — Register device token for push notifications
router.post(
  "/register",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const { token } = req.body;

    if (!token) {
      res.status(400).json({ error: "Device token is required" });
      return;
    }

    try {
      const { error } = await supabaseAdmin.from("device_tokens").upsert(
        {
          user_id: req.userId,
          token,
        },
        { onConflict: "token" }
      );

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json({ message: "Device registered" });
    } catch {
      res.status(500).json({ error: "Failed to register device" });
    }
  }
);

// GET /notifications/diagnostics — returns the calling user's registered
// FCM tokens and whether Firebase Admin is initialised. Useful for the
// in-app push diagnostics screen.
router.get(
  "/diagnostics",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const fcmReady = admin.apps.length > 0;

    const { data, error } = await supabaseAdmin
      .from("device_tokens")
      .select("token, created_at")
      .eq("user_id", req.userId!);

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    // Mask all but the first 12 chars so we can compare against the iOS log
    // without leaking the full token value.
    const tokens = (data ?? []).map((t) => ({
      preview: `${t.token.slice(0, 12)}…(${t.token.length})`,
      created_at: t.created_at,
    }));

    res.json({ fcm_ready: fcmReady, token_count: tokens.length, tokens });
  }
);

// POST /notifications/test — Send a push notification to the calling user's
// own registered devices. Returns FCM's per-token result so the iOS client
// can display exactly why a push didn't arrive (invalid token, sandbox
// mismatch, etc.).
router.post(
  "/test",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    if (!admin.apps.length) {
      res.status(503).json({
        error: "Firebase Admin not initialised — check FCM_* env vars",
      });
      return;
    }

    const { data: tokens, error } = await supabaseAdmin
      .from("device_tokens")
      .select("token")
      .eq("user_id", req.userId!);

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }
    if (!tokens || tokens.length === 0) {
      res.status(404).json({
        error:
          "No registered devices for this user — open the iOS app, sign in, and grant the notification permission first.",
      });
      return;
    }

    const messaging = admin.messaging();
    const results = await Promise.all(
      tokens.map(async (t) => {
        try {
          const messageId = await messaging.send({
            token: t.token,
            notification: {
              title: "🔔 Test push from Worship Manager",
              body: `Sent at ${new Date().toLocaleTimeString()}`,
            },
            apns: {
              payload: { aps: { sound: "default", badge: 1 } },
            },
          });
          return {
            token_preview: `${t.token.slice(0, 12)}…`,
            ok: true,
            messageId,
          };
        } catch (err) {
          const e = err as { code?: string; message?: string };
          return {
            token_preview: `${t.token.slice(0, 12)}…`,
            ok: false,
            code: e.code ?? "unknown",
            message: e.message ?? String(err),
          };
        }
      })
    );

    const succeeded = results.filter((r) => r.ok).length;
    res.json({
      attempted: results.length,
      succeeded,
      failed: results.length - succeeded,
      results,
    });
  }
);

export default router;
