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

// POST /bands/:id/songs/bulk — Insert many songs at once (title + optional artist).
// Body: { songs: Array<{ title: string; artist?: string | null }> }
// Returns: { songs: Song[] } — the created rows in the same order as the input.
//
// Designed for the "paste a list of titles" UX: limited to 200 per call, and
// silently dedupes empty titles. Uses a single bulk insert for performance.
bandSongsRouter.post(
  "/:id/songs/bulk",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    const { songs } = req.body as {
      songs?: Array<{ title?: unknown; artist?: unknown }>;
    };

    if (!Array.isArray(songs) || songs.length === 0) {
      res.status(400).json({ error: "songs must be a non-empty array" });
      return;
    }
    if (songs.length > 200) {
      res.status(400).json({ error: "Maximum 200 songs per bulk insert" });
      return;
    }

    const rows = songs
      .map((s) => {
        const title = typeof s?.title === "string" ? s.title.trim() : "";
        const artistRaw = typeof s?.artist === "string" ? s.artist.trim() : "";
        if (!title) return null;
        return {
          band_id: req.bandId,
          title,
          artist: artistRaw.length > 0 ? artistRaw : null,
          created_by: req.userId,
        };
      })
      .filter((r): r is NonNullable<typeof r> => r !== null);

    if (rows.length === 0) {
      res.status(400).json({ error: "No valid song titles in payload" });
      return;
    }

    try {
      const { data, error } = await supabaseAdmin
        .from("songs")
        .insert(rows)
        .select();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.status(201).json({ songs: data ?? [] });
    } catch {
      res.status(500).json({ error: "Failed to bulk-create songs" });
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

// MARK: - Song Stems (multitracks)

/**
 * Normalize a user-provided streaming URL so that major cloud providers
 * serve the raw file instead of an HTML landing page.
 *
 *  - Dropbox: rewrite `www.dropbox.com` → `dl.dropboxusercontent.com`
 *      and strip `dl` / `raw` flags. This bypasses Dropbox's normal 302
 *      redirect chain and returns the file bytes in a single response
 *      with `Access-Control-Allow-Origin: *` — required for the web
 *      Multitrack player's `fetch` + `decodeAudioData` to succeed on
 *      both legacy `/s/...` and modern `/scl/fi/...?rlkey=...` share
 *      formats. Previously we tried `?raw=1` and `?dl=1`, but both
 *      either served an HTML preview or dropped CORS headers after the
 *      redirect in some browsers / networks. The `rlkey=` and `st=`
 *      tokens continue to work on the `dl.dropboxusercontent.com`
 *      subdomain unchanged.
 *  - OneDrive: append `?download=1`.
 */
function normalizeStreamingUrl(raw: string): string {
  try {
    const u = new URL(raw.trim());
    const host = u.hostname.toLowerCase();

    if (host === "www.dropbox.com" || host === "dropbox.com") {
      u.hostname = "dl.dropboxusercontent.com";
      u.searchParams.delete("dl");
      u.searchParams.delete("raw");
      return u.toString();
    }
    if (host.endsWith("1drv.ms") || host.endsWith("onedrive.live.com")) {
      u.searchParams.set("download", "1");
      return u.toString();
    }
    return u.toString();
  } catch {
    return raw.trim();
  }
}

/** iCloud public share links always return an HTML landing page, not the file. */
function isUnsupportedStreamingHost(raw: string): string | null {
  try {
    const host = new URL(raw.trim()).hostname.toLowerCase();
    if (host.endsWith("icloud.com")) {
      return "iCloud share links can't stream audio. Upload the file to Dropbox, Google Drive, OneDrive, or any direct audio host, and paste that link instead.";
    }
    return null;
  } catch {
    return "Please provide a valid URL.";
  }
}

const ALLOWED_STEM_KINDS = new Set([
  "click",
  "guide",
  "drums",
  "bass",
  "keys",
  "pad",
  "vocal",
  "guitar",
  "other",
]);

/** Assert the caller is a member of the band that owns the given song. */
async function assertSongBandAccess(
  songId: string,
  userId: string
): Promise<{ ok: true; bandId: string } | { ok: false; status: number; error: string }> {
  const { data: song, error: songErr } = await supabaseAdmin
    .from("songs")
    .select("id, band_id")
    .eq("id", songId)
    .single();

  if (songErr || !song) {
    return { ok: false, status: 404, error: "Song not found" };
  }

  const { data: membership, error: memErr } = await supabaseAdmin
    .from("band_members")
    .select("user_id")
    .eq("band_id", song.band_id)
    .eq("user_id", userId)
    .maybeSingle();

  if (memErr) {
    return { ok: false, status: 500, error: memErr.message };
  }
  if (!membership) {
    return { ok: false, status: 403, error: "Not a member of this band" };
  }

  return { ok: true, bandId: song.band_id };
}

// GET /songs/:id/stems — List stems for a song
songsRouter.get(
  "/:id/stems",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const songId = req.params.id;
    const access = await assertSongBandAccess(songId, req.userId!);
    if (!access.ok) {
      res.status(access.status).json({ error: access.error });
      return;
    }

    const { data, error } = await supabaseAdmin
      .from("song_stems")
      .select("*")
      .eq("song_id", songId)
      .order("position", { ascending: true })
      .order("created_at", { ascending: true });

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    res.json(data);
  }
);

// POST /songs/:id/stems — Add a stem (URL-only)
songsRouter.post(
  "/:id/stems",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const songId = req.params.id;
    const { kind, label, url, position } = req.body as {
      kind?: unknown;
      label?: unknown;
      url?: unknown;
      position?: unknown;
    };

    if (typeof kind !== "string" || !ALLOWED_STEM_KINDS.has(kind)) {
      res.status(400).json({ error: "Invalid stem kind" });
      return;
    }
    if (typeof label !== "string" || label.trim().length === 0) {
      res.status(400).json({ error: "label is required" });
      return;
    }
    if (typeof url !== "string" || url.trim().length === 0) {
      res.status(400).json({ error: "url is required" });
      return;
    }

    const unsupported = isUnsupportedStreamingHost(url);
    if (unsupported) {
      res.status(400).json({ error: unsupported });
      return;
    }

    const access = await assertSongBandAccess(songId, req.userId!);
    if (!access.ok) {
      res.status(access.status).json({ error: access.error });
      return;
    }

    const normalized = normalizeStreamingUrl(url);

    const { data, error } = await supabaseAdmin
      .from("song_stems")
      .insert({
        song_id: songId,
        band_id: access.bandId,
        kind,
        label: label.trim(),
        url: normalized,
        position: typeof position === "number" ? position : 0,
        created_by: req.userId,
      })
      .select()
      .single();

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    res.status(201).json(data);
  }
);

// PATCH /songs/:id/stems/:stemId — Edit a stem
songsRouter.patch(
  "/:id/stems/:stemId",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const { id: songId, stemId } = req.params;
    const { kind, label, url, position } = req.body as {
      kind?: unknown;
      label?: unknown;
      url?: unknown;
      position?: unknown;
    };

    const access = await assertSongBandAccess(songId, req.userId!);
    if (!access.ok) {
      res.status(access.status).json({ error: access.error });
      return;
    }

    const updates: Record<string, unknown> = {};
    if (typeof kind === "string") {
      if (!ALLOWED_STEM_KINDS.has(kind)) {
        res.status(400).json({ error: "Invalid stem kind" });
        return;
      }
      updates.kind = kind;
    }
    if (typeof label === "string" && label.trim().length > 0) {
      updates.label = label.trim();
    }
    if (typeof url === "string" && url.trim().length > 0) {
      const unsupported = isUnsupportedStreamingHost(url);
      if (unsupported) {
        res.status(400).json({ error: unsupported });
        return;
      }
      updates.url = normalizeStreamingUrl(url);
    }
    if (typeof position === "number") {
      updates.position = position;
    }

    if (Object.keys(updates).length === 0) {
      res.status(400).json({ error: "No valid fields to update" });
      return;
    }

    const { data, error } = await supabaseAdmin
      .from("song_stems")
      .update(updates)
      .eq("id", stemId)
      .eq("song_id", songId)
      .select()
      .single();

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    res.json(data);
  }
);

// DELETE /songs/:id/stems/:stemId — Remove a stem
songsRouter.delete(
  "/:id/stems/:stemId",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const { id: songId, stemId } = req.params;

    const access = await assertSongBandAccess(songId, req.userId!);
    if (!access.ok) {
      res.status(access.status).json({ error: access.error });
      return;
    }

    const { error } = await supabaseAdmin
      .from("song_stems")
      .delete()
      .eq("id", stemId)
      .eq("song_id", songId);

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    res.json({ message: "Stem deleted" });
  }
);

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
