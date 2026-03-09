import { Router, Response } from "express";
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

export default router;
