import { Router, Response } from "express";
import multer from "multer";
import { supabaseAdmin } from "../config/supabase";
import { authMiddleware, AuthRequest } from "../middleware/auth.middleware";
import {
  bandAccessMiddleware,
  leaderOnlyMiddleware,
  BandRequest,
} from "../middleware/bandAccess.middleware";

const router = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

function generateInviteCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no I/O/0/1 to avoid confusion
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

// POST /bands — Create band
router.post(
  "/",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const { name, church, avatar_emoji, avatar_color } = req.body;

    if (!name) {
      res.status(400).json({ error: "Band name is required" });
      return;
    }

    try {
      // Generate unique invite code
      let invite_code = generateInviteCode();
      let attempts = 0;
      while (attempts < 10) {
        const { data: existing } = await supabaseAdmin
          .from("bands")
          .select("id")
          .eq("invite_code", invite_code)
          .single();
        if (!existing) break;
        invite_code = generateInviteCode();
        attempts++;
      }

      const { data: band, error } = await supabaseAdmin
        .from("bands")
        .insert({
          name,
          church: church || null,
          invite_code,
          avatar_emoji: avatar_emoji || "🎸",
          avatar_color: avatar_color || "#1C1C1E",
          created_by: req.userId,
        })
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      // Add creator as leader
      await supabaseAdmin.from("band_members").insert({
        band_id: band.id,
        user_id: req.userId,
        role: "leader",
      });

      res.status(201).json(band);
    } catch {
      res.status(500).json({ error: "Failed to create band" });
    }
  }
);

// POST /bands/join — Join band with invite code
router.post(
  "/join",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const { code } = req.body;

    if (!code || code.length !== 6) {
      res.status(400).json({ error: "A valid 6-character code is required" });
      return;
    }

    try {
      const { data: band, error } = await supabaseAdmin
        .from("bands")
        .select("*")
        .eq("invite_code", code.toUpperCase())
        .single();

      if (error || !band) {
        res.status(404).json({ error: "Invalid invite code" });
        return;
      }

      // Check if already a member
      const { data: existing } = await supabaseAdmin
        .from("band_members")
        .select("id")
        .eq("band_id", band.id)
        .eq("user_id", req.userId!)
        .single();

      if (existing) {
        res.status(409).json({ error: "You are already a member of this band" });
        return;
      }

      // Get user's instrument from profile
      const { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("instrument")
        .eq("id", req.userId!)
        .single();

      await supabaseAdmin.from("band_members").insert({
        band_id: band.id,
        user_id: req.userId,
        role: "member",
        instrument: profile?.instrument || null,
      });

      res.json(band);
    } catch {
      res.status(500).json({ error: "Failed to join band" });
    }
  }
);

// GET /bands/my — My bands
router.get(
  "/my",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    try {
      const { data: memberships, error } = await supabaseAdmin
        .from("band_members")
        .select("band_id, role, bands(*)")
        .eq("user_id", req.userId!);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      const bands = memberships?.map((m) => ({
        ...m.bands,
        my_role: m.role,
      }));

      res.json(bands);
    } catch {
      res.status(500).json({ error: "Failed to fetch bands" });
    }
  }
);

// GET /bands/:id — Band details
router.get(
  "/:id",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    try {
      const { data: band, error } = await supabaseAdmin
        .from("bands")
        .select("*")
        .eq("id", req.bandId!)
        .single();

      if (error) {
        res.status(404).json({ error: "Band not found" });
        return;
      }

      // Get member count
      const { count } = await supabaseAdmin
        .from("band_members")
        .select("*", { count: "exact", head: true })
        .eq("band_id", req.bandId!);

      res.json({ ...band, member_count: count, my_role: req.bandRole });
    } catch {
      res.status(500).json({ error: "Failed to fetch band" });
    }
  }
);

// PUT /bands/:id — Update band (leader only)
router.put(
  "/:id",
  authMiddleware,
  bandAccessMiddleware,
  leaderOnlyMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    const { name, church, avatar_emoji, avatar_color, avatar_url } = req.body;

    try {
      const { data, error } = await supabaseAdmin
        .from("bands")
        .update({
          ...(name && { name }),
          ...(church !== undefined && { church }),
          ...(avatar_emoji && { avatar_emoji }),
          ...(avatar_color && { avatar_color }),
          ...(avatar_url !== undefined && { avatar_url }),
        })
        .eq("id", req.bandId!)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to update band" });
    }
  }
);

// POST /bands/:id/avatar — Upload band avatar image (leader only)
router.post(
  "/:id/avatar",
  authMiddleware,
  bandAccessMiddleware,
  leaderOnlyMiddleware,
  upload.single("avatar"),
  async (req: BandRequest, res: Response): Promise<void> => {
    if (!req.file) {
      res.status(400).json({ error: "No image file provided" });
      return;
    }

    try {
      const bandId = req.bandId!;
      const ext = req.file.mimetype === "image/png" ? "png" : "jpg";
      const filePath = `bands/${bandId}/avatar.${ext}`;

      // Upload to Supabase Storage
      const { error: uploadError } = await supabaseAdmin.storage
        .from("band-avatars")
        .upload(filePath, req.file.buffer, {
          contentType: req.file.mimetype,
          upsert: true,
        });

      if (uploadError) {
        res.status(500).json({ error: uploadError.message });
        return;
      }

      // Get public URL
      const { data: urlData } = supabaseAdmin.storage
        .from("band-avatars")
        .getPublicUrl(filePath);

      const avatarUrl = urlData.publicUrl + `?t=${Date.now()}`;

      // Update band record
      const { data, error } = await supabaseAdmin
        .from("bands")
        .update({ avatar_url: avatarUrl })
        .eq("id", bandId)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to upload avatar" });
    }
  }
);

// DELETE /bands/:id — Delete band (leader only)
router.delete(
  "/:id",
  authMiddleware,
  bandAccessMiddleware,
  leaderOnlyMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    try {
      const { error } = await supabaseAdmin
        .from("bands")
        .delete()
        .eq("id", req.bandId!);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json({ message: "Band deleted" });
    } catch {
      res.status(500).json({ error: "Failed to delete band" });
    }
  }
);

// POST /bands/:id/regenerate-code — Generate new invite code (leader only)
router.post(
  "/:id/regenerate-code",
  authMiddleware,
  bandAccessMiddleware,
  leaderOnlyMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    try {
      const newCode = generateInviteCode();

      const { data, error } = await supabaseAdmin
        .from("bands")
        .update({ invite_code: newCode })
        .eq("id", req.bandId!)
        .select("invite_code")
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to regenerate code" });
    }
  }
);

export default router;
