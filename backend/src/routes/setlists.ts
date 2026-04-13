import { Router, Response } from "express";
import { supabaseAdmin } from "../config/supabase";
import { authMiddleware, AuthRequest } from "../middleware/auth.middleware";
import {
  bandAccessMiddleware,
  BandRequest,
} from "../middleware/bandAccess.middleware";
import { notifyBandMembers } from "../services/notification.service";

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
    const { name, date, notes, is_template, service_type, location, theme, time } = req.body;

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
          service_type: service_type || null,
          location: location || null,
          theme: theme || null,
          time: time || null,
          created_by: req.userId,
        })
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      // Send push notification to band members (only for real, non-template services)
      if (!is_template) {
        let bodyText = name;
        if (date) {
          const parts: string[] = [];
          // Build a local-ish date like "Sun, Apr 14"
          try {
            const d = new Date(`${date}T00:00:00`);
            parts.push(
              d.toLocaleDateString("en-US", {
                weekday: "short",
                month: "short",
                day: "numeric",
              })
            );
          } catch {
            parts.push(date);
          }
          if (time) parts.push(time);
          if (location) parts.push(location);
          bodyText = `${name} · ${parts.join(" · ")}`;
        }

        await notifyBandMembers(
          req.bandId!,
          req.userId!,
          "New Service Scheduled",
          bodyText
        );
      }

      res.status(201).json(data);
    } catch {
      res.status(500).json({ error: "Failed to create setlist" });
    }
  }
);

// Standalone setlist routes — mounted at /setlists
const setlistsRouter = Router();

// GET /setlists/my-rsvps?band_id=... — current user's RSVPs across all
// setlists in a band. Mirrors /rehearsals/my-rsvps.
setlistsRouter.get(
  "/my-rsvps",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const bandId = req.query.band_id as string;
    if (!bandId) {
      res.status(400).json({ error: "band_id query parameter is required" });
      return;
    }

    try {
      const { data: setlists, error: sErr } = await supabaseAdmin
        .from("setlists")
        .select("id")
        .eq("band_id", bandId);

      if (sErr) {
        res.status(500).json({ error: sErr.message });
        return;
      }
      const setlistIds = (setlists ?? []).map((s: { id: string }) => s.id);
      if (setlistIds.length === 0) {
        res.json([]);
        return;
      }

      const { data, error } = await supabaseAdmin
        .from("setlist_rsvps")
        .select("setlist_id, status")
        .eq("user_id", req.userId!)
        .in("setlist_id", setlistIds);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to fetch service RSVPs" });
    }
  }
);

// POST /setlists/:id/rsvp — upsert this user's RSVP for the service.
setlistsRouter.post(
  "/:id/rsvp",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const setlistId = req.params.id;
    const { status } = req.body;

    if (!status || !["going", "not_going", "maybe"].includes(status)) {
      res
        .status(400)
        .json({ error: "Status must be 'going', 'not_going', or 'maybe'" });
      return;
    }

    try {
      const { data, error } = await supabaseAdmin
        .from("setlist_rsvps")
        .upsert(
          {
            setlist_id: setlistId,
            user_id: req.userId,
            status,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "setlist_id,user_id" }
        )
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to update RSVP" });
    }
  }
);

// GET /setlists/:id/rsvps — all RSVPs for a service, with profile names.
// Used to show "who's going" to a service detail page.
setlistsRouter.get(
  "/:id/rsvps",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const setlistId = req.params.id;
    try {
      const { data, error } = await supabaseAdmin
        .from("setlist_rsvps")
        .select("setlist_id, user_id, status, updated_at, profiles(full_name, avatar_url)")
        .eq("setlist_id", setlistId);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to fetch service RSVPs" });
    }
  }
);

// PUT /setlists/:id
setlistsRouter.put(
  "/:id",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const setlistId = req.params.id;
    const { name, date, notes, is_template, service_type, location, theme, time } = req.body;

    try {
      const { data, error } = await supabaseAdmin
        .from("setlists")
        .update({
          ...(name && { name }),
          ...(date !== undefined && { date }),
          ...(notes !== undefined && { notes }),
          ...(is_template !== undefined && { is_template }),
          ...(service_type !== undefined && { service_type }),
          ...(location !== undefined && { location }),
          ...(theme !== undefined && { theme }),
          ...(time !== undefined && { time }),
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
