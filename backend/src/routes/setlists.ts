import { Router, Response } from "express";
import { supabaseAdmin } from "../config/supabase";
import { authMiddleware, AuthRequest } from "../middleware/auth.middleware";
import {
  bandAccessMiddleware,
  BandRequest,
} from "../middleware/bandAccess.middleware";

// Band-scoped setlist routes — mounted at /bands
const bandSetlistsRouter = Router();

// GET /bands/:id/setlists
bandSetlistsRouter.get(
  "/:id/setlists",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    try {
      const { data, error } = await supabaseAdmin
        .from("setlists")
        .select("*, setlist_songs(count)")
        .eq("band_id", req.bandId!)
        .order("date", { ascending: false });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to fetch setlists" });
    }
  }
);

// POST /bands/:id/setlists
bandSetlistsRouter.post(
  "/:id/setlists",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    const { name, date, notes, is_template } = req.body;

    if (!name) {
      res.status(400).json({ error: "Setlist name is required" });
      return;
    }

    try {
      const { data, error } = await supabaseAdmin
        .from("setlists")
        .insert({
          band_id: req.bandId,
          name,
          date: date || null,
          notes: notes || null,
          is_template: is_template || false,
          created_by: req.userId,
        })
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.status(201).json(data);
    } catch {
      res.status(500).json({ error: "Failed to create setlist" });
    }
  }
);

// Standalone setlist routes — mounted at /setlists
const setlistsRouter = Router();

// PUT /setlists/:id
setlistsRouter.put(
  "/:id",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const setlistId = req.params.id;
    const { name, date, notes, is_template } = req.body;

    try {
      const { data, error } = await supabaseAdmin
        .from("setlists")
        .update({
          ...(name && { name }),
          ...(date !== undefined && { date }),
          ...(notes !== undefined && { notes }),
          ...(is_template !== undefined && { is_template }),
        })
        .eq("id", setlistId)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to update setlist" });
    }
  }
);

// DELETE /setlists/:id
setlistsRouter.delete(
  "/:id",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const setlistId = req.params.id;

    try {
      const { error } = await supabaseAdmin
        .from("setlists")
        .delete()
        .eq("id", setlistId);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json({ message: "Setlist deleted" });
    } catch {
      res.status(500).json({ error: "Failed to delete setlist" });
    }
  }
);

// GET /setlists/:id/songs
setlistsRouter.get(
  "/:id/songs",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const setlistId = req.params.id;

    try {
      const { data, error } = await supabaseAdmin
        .from("setlist_songs")
        .select("*, songs(*)")
        .eq("setlist_id", setlistId)
        .order("position", { ascending: true });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to fetch setlist songs" });
    }
  }
);

// POST /setlists/:id/songs — Add song to setlist
setlistsRouter.post(
  "/:id/songs",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const setlistId = req.params.id;
    const { song_id, key_override, notes } = req.body;

    if (!song_id) {
      res.status(400).json({ error: "song_id is required" });
      return;
    }

    try {
      const { data: existing } = await supabaseAdmin
        .from("setlist_songs")
        .select("position")
        .eq("setlist_id", setlistId)
        .order("position", { ascending: false })
        .limit(1);

      const nextPosition = existing && existing.length > 0 ? existing[0].position + 1 : 1;

      const { data, error } = await supabaseAdmin
        .from("setlist_songs")
        .insert({
          setlist_id: setlistId,
          song_id,
          position: nextPosition,
          key_override: key_override || null,
          notes: notes || null,
        })
        .select("*, songs(*)")
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.status(201).json(data);
    } catch {
      res.status(500).json({ error: "Failed to add song to setlist" });
    }
  }
);

// DELETE /setlists/:id/songs/:songId
setlistsRouter.delete(
  "/:id/songs/:songId",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const { id: setlistId, songId } = req.params;

    try {
      const { error } = await supabaseAdmin
        .from("setlist_songs")
        .delete()
        .eq("setlist_id", setlistId)
        .eq("song_id", songId);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json({ message: "Song removed from setlist" });
    } catch {
      res.status(500).json({ error: "Failed to remove song from setlist" });
    }
  }
);

// PATCH /setlists/:id/songs/reorder
setlistsRouter.patch(
  "/:id/songs/reorder",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const setlistId = req.params.id;
    const { positions } = req.body;

    if (!positions || !Array.isArray(positions)) {
      res.status(400).json({ error: "positions array is required" });
      return;
    }

    try {
      const updates = positions.map(
        (p: { id: string; position: number }) =>
          supabaseAdmin
            .from("setlist_songs")
            .update({ position: p.position })
            .eq("id", p.id)
            .eq("setlist_id", setlistId)
      );

      await Promise.all(updates);

      res.json({ message: "Setlist reordered" });
    } catch {
      res.status(500).json({ error: "Failed to reorder setlist" });
    }
  }
);

export { bandSetlistsRouter, setlistsRouter };
