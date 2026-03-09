import { Router, Response } from "express";
import { supabaseAdmin } from "../config/supabase";
import { authMiddleware, AuthRequest } from "../middleware/auth.middleware";
import {
  bandAccessMiddleware,
  BandRequest,
} from "../middleware/bandAccess.middleware";

// Band-scoped song routes — mounted at /bands
const bandSongsRouter = Router();

// GET /bands/:id/songs — Song library
bandSongsRouter.get(
  "/:id/songs",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    try {
      const { data, error } = await supabaseAdmin
        .from("songs")
        .select("*")
        .eq("band_id", req.bandId!)
        .order("title", { ascending: true });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to fetch songs" });
    }
  }
);

// POST /bands/:id/songs — Add song
bandSongsRouter.post(
  "/:id/songs",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    const { title, artist, default_key, tempo_bpm, duration_sec, notes, youtube_url, spotify_url } =
      req.body;

    if (!title) {
      res.status(400).json({ error: "Song title is required" });
      return;
    }

    try {
      const { data, error } = await supabaseAdmin
        .from("songs")
        .insert({
          band_id: req.bandId,
          title,
          artist: artist || null,
          default_key: default_key || null,
          tempo_bpm: tempo_bpm || null,
          duration_sec: duration_sec || null,
          notes: notes || null,
          youtube_url: youtube_url || null,
          spotify_url: spotify_url || null,
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
      res.status(500).json({ error: "Failed to add song" });
    }
  }
);

// PUT /bands/:id/songs/:songId — Edit song
bandSongsRouter.put(
  "/:id/songs/:songId",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    const { songId } = req.params;
    const updates = req.body;

    try {
      const { data, error } = await supabaseAdmin
        .from("songs")
        .update(updates)
        .eq("id", songId)
        .eq("band_id", req.bandId!)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to update song" });
    }
  }
);

// DELETE /bands/:id/songs/:songId — Delete song
bandSongsRouter.delete(
  "/:id/songs/:songId",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    const { songId } = req.params;

    try {
      const { error } = await supabaseAdmin
        .from("songs")
        .delete()
        .eq("id", songId)
        .eq("band_id", req.bandId!);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json({ message: "Song deleted" });
    } catch {
      res.status(500).json({ error: "Failed to delete song" });
    }
  }
);

// Standalone song routes — mounted at /songs
const songsRouter = Router();

// GET /songs/:id/chords — All chord sheets for a song
songsRouter.get(
  "/:id/chords",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const songId = req.params.id;

    try {
      const { data, error } = await supabaseAdmin
        .from("chord_sheets")
        .select("*, profiles(full_name)")
        .eq("song_id", songId)
        .order("updated_at", { ascending: false });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to fetch chord sheets" });
    }
  }
);

// POST /songs/:id/chords — Create chord sheet
songsRouter.post(
  "/:id/chords",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const songId = req.params.id;
    const { instrument, title, content } = req.body;

    if (!content) {
      res.status(400).json({ error: "Chord sheet content is required" });
      return;
    }

    try {
      const { data, error } = await supabaseAdmin
        .from("chord_sheets")
        .insert({
          song_id: songId,
          instrument: instrument || null,
          title: title || "Chord Sheet",
          content,
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
      res.status(500).json({ error: "Failed to create chord sheet" });
    }
  }
);

// Chord sheet routes — mounted at /chords
const chordsRouter = Router();

// PUT /chords/:id — Update chord sheet
chordsRouter.put(
  "/:id",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const chordId = req.params.id;
    const { title, content, instrument } = req.body;

    try {
      const { data, error } = await supabaseAdmin
        .from("chord_sheets")
        .update({
          ...(title && { title }),
          ...(content && { content }),
          ...(instrument !== undefined && { instrument }),
          updated_at: new Date().toISOString(),
        })
        .eq("id", chordId)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to update chord sheet" });
    }
  }
);

export { bandSongsRouter, songsRouter, chordsRouter };
