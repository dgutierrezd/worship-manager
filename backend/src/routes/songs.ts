import { Router, Response } from "express";
import { supabaseAdmin } from "../config/supabase";
import { authMiddleware, AuthRequest } from "../middleware/auth.middleware";
import {
  bandAccessMiddleware,
  BandRequest,
} from "../middleware/bandAccess.middleware";
import { lookupSongs, AISongResult } from "../services/groq.service";

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
    const { title, artist, default_key, tempo_bpm, duration_sec, notes, lyrics, tags, theme, youtube_url, spotify_url } =
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
          lyrics: lyrics || null,
          tags: tags && tags.length > 0 ? tags : null,
          theme: theme || null,
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

// POST /bands/:id/songs/ai-lookup — AI-powered song lookup (does NOT save anything)
bandSongsRouter.post(
  "/:id/songs/ai-lookup",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    const { names } = req.body as { names?: unknown };

    if (!Array.isArray(names) || names.length === 0) {
      res.status(400).json({ error: "names must be a non-empty array of song name strings" });
      return;
    }
    if (names.length > 10) {
      res.status(400).json({ error: "Maximum 10 songs per lookup" });
      return;
    }

    const nameStrings = (names as unknown[])
      .filter((n): n is string => typeof n === "string" && n.trim().length > 0)
      .map((n) => n.trim());

    if (nameStrings.length === 0) {
      res.status(400).json({ error: "All names must be non-empty strings" });
      return;
    }

    try {
      const results = await lookupSongs(nameStrings);
      res.json({ results });
    } catch (err) {
      const message = err instanceof Error ? err.message : "AI lookup failed";
      res.status(500).json({ error: message });
    }
  }
);

// POST /bands/:id/songs/ai-import — Save AI-sourced songs + chord sheets
bandSongsRouter.post(
  "/:id/songs/ai-import",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    const { songs } = req.body as { songs?: AISongResult[] };

    if (!Array.isArray(songs) || songs.length === 0) {
      res.status(400).json({ error: "songs must be a non-empty array" });
      return;
    }

    const createdSongs: Record<string, unknown>[] = [];

    try {
      for (const song of songs) {
        // 1. Insert the song row
        const { data: newSong, error: songError } = await supabaseAdmin
          .from("songs")
          .insert({
            band_id: req.bandId,
            title: song.title,
            artist: song.artist || null,
            default_key: song.default_key || null,
            tempo_bpm: song.tempo_bpm || null,
            duration_sec: song.duration_sec || null,
            lyrics: song.lyrics || null,
            theme: song.theme || null,
            youtube_url: song.youtube_url || null,
            spotify_url: song.spotify_url || null,
            created_by: req.userId,
          })
          .select()
          .single();

        if (songError || !newSong) {
          console.error("Failed to insert AI song:", songError?.message);
          continue;
        }

        createdSongs.push(newSong);

        // 2. Create chord sheet if sections were provided
        if (Array.isArray(song.chord_sections) && song.chord_sections.length > 0) {
          const sections = song.chord_sections.map((section) => ({
            id: crypto.randomUUID(),
            name: section.name,
            chords: section.chords.map((chord) => ({
              id: crypto.randomUUID(),
              degree: chord.degree,
              is_pass: false,           // must match iOS ChordEntry.CodingKeys ("is_pass")
              modifier: chord.modifier ?? null,
            })),
          }));

          const content = JSON.stringify({ sections });

          const { error: chordError } = await supabaseAdmin
            .from("chord_sheets")
            .insert({
              song_id: newSong.id,
              title: "AI Generated",
              content,
              created_by: req.userId,
            });

          if (chordError) {
            console.error("Failed to insert chord sheet for AI song:", chordError.message);
          }
        }
      }

      res.status(201).json({ songs: createdSongs });
    } catch {
      res.status(500).json({ error: "Failed to import songs" });
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
