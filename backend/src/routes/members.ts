import { Router, Response } from "express";
import { supabaseAdmin } from "../config/supabase";
import { authMiddleware } from "../middleware/auth.middleware";
import {
  bandAccessMiddleware,
  leaderOnlyMiddleware,
  BandRequest,
} from "../middleware/bandAccess.middleware";

const router = Router();

// GET /bands/:id/members
router.get(
  "/:id/members",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    try {
      const { data, error } = await supabaseAdmin
        .from("band_members")
        .select("*, profiles(full_name, avatar_url, instrument)")
        .eq("band_id", req.bandId!)
        .order("joined_at", { ascending: true });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      const members = data?.map((m) => ({
        id: m.user_id,
        role: m.role,
        instrument: m.instrument,
        joined_at: m.joined_at,
        ...(m.profiles as any),
      }));

      res.json(members);
    } catch {
      res.status(500).json({ error: "Failed to fetch members" });
    }
  }
);

// DELETE /bands/:id/members/:userId — Remove member (leader only)
router.delete(
  "/:id/members/:userId",
  authMiddleware,
  bandAccessMiddleware,
  leaderOnlyMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    const { userId } = req.params;

    // Prevent removing yourself
    if (userId === req.userId) {
      res.status(400).json({ error: "You cannot remove yourself" });
      return;
    }

    try {
      const { error } = await supabaseAdmin
        .from("band_members")
        .delete()
        .eq("band_id", req.bandId!)
        .eq("user_id", userId);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json({ message: "Member removed" });
    } catch {
      res.status(500).json({ error: "Failed to remove member" });
    }
  }
);

// PATCH /bands/:id/members/:userId — Update role (leader only)
router.patch(
  "/:id/members/:userId",
  authMiddleware,
  bandAccessMiddleware,
  leaderOnlyMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    const { userId } = req.params;
    const { role } = req.body;

    if (!role || !["leader", "member"].includes(role)) {
      res.status(400).json({ error: "Role must be 'leader' or 'member'" });
      return;
    }

    try {
      const { data, error } = await supabaseAdmin
        .from("band_members")
        .update({ role })
        .eq("band_id", req.bandId!)
        .eq("user_id", userId)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to update member role" });
    }
  }
);

export default router;
