import { Router, Response } from "express";
import { supabaseAdmin } from "../config/supabase";
import { authMiddleware, AuthRequest } from "../middleware/auth.middleware";
import {
  bandAccessMiddleware,
  BandRequest,
} from "../middleware/bandAccess.middleware";
import { notifyBandMembers } from "../services/notification.service";

// Band-scoped rehearsal routes — mounted at /bands
const bandRehearsalsRouter = Router();

// GET /bands/:id/rehearsals
bandRehearsalsRouter.get(
  "/:id/rehearsals",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    try {
      const { data, error } = await supabaseAdmin
        .from("rehearsals")
        .select("*, setlists(name)")
        .eq("band_id", req.bandId!)
        .order("scheduled_at", { ascending: true });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to fetch rehearsals" });
    }
  }
);

// POST /bands/:id/rehearsals
bandRehearsalsRouter.post(
  "/:id/rehearsals",
  authMiddleware,
  bandAccessMiddleware,
  async (req: BandRequest, res: Response): Promise<void> => {
    const { title, location, scheduled_at, notes, setlist_id } = req.body;

    if (!title || !scheduled_at) {
      res.status(400).json({ error: "Title and scheduled_at are required" });
      return;
    }

    try {
      const { data, error } = await supabaseAdmin
        .from("rehearsals")
        .insert({
          band_id: req.bandId,
          title,
          location: location || null,
          scheduled_at,
          notes: notes || null,
          setlist_id: setlist_id || null,
          created_by: req.userId,
        })
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      // Send push notification to band members
      const scheduledDate = new Date(scheduled_at);
      const formattedDate = scheduledDate.toLocaleDateString("en-US", {
        weekday: "long",
        month: "short",
        day: "numeric",
      });
      const formattedTime = scheduledDate.toLocaleTimeString("en-US", {
        hour: "numeric",
        minute: "2-digit",
      });

      await notifyBandMembers(
        req.bandId!,
        req.userId!,
        "New Rehearsal Scheduled",
        `${title} on ${formattedDate} at ${formattedTime}${location ? ` · ${location}` : ""}`
      );

      res.status(201).json(data);
    } catch {
      res.status(500).json({ error: "Failed to create rehearsal" });
    }
  }
);

// Standalone rehearsal routes — mounted at /rehearsals
const rehearsalsRouter = Router();

// PUT /rehearsals/:id
rehearsalsRouter.put(
  "/:id",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const rehearsalId = req.params.id;
    const { title, location, scheduled_at, notes, setlist_id } = req.body;

    try {
      const { data, error } = await supabaseAdmin
        .from("rehearsals")
        .update({
          ...(title && { title }),
          ...(location !== undefined && { location }),
          ...(scheduled_at && { scheduled_at }),
          ...(notes !== undefined && { notes }),
          ...(setlist_id !== undefined && { setlist_id }),
        })
        .eq("id", rehearsalId)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to update rehearsal" });
    }
  }
);

// DELETE /rehearsals/:id
rehearsalsRouter.delete(
  "/:id",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const rehearsalId = req.params.id;

    try {
      const { error } = await supabaseAdmin
        .from("rehearsals")
        .delete()
        .eq("id", rehearsalId);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json({ message: "Rehearsal deleted" });
    } catch {
      res.status(500).json({ error: "Failed to delete rehearsal" });
    }
  }
);

// GET /rehearsals/my-rsvps?band_id=...
rehearsalsRouter.get(
  "/my-rsvps",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const bandId = req.query.band_id as string;
    if (!bandId) {
      res.status(400).json({ error: "band_id query parameter is required" });
      return;
    }

    try {
      // Get all rehearsal IDs for this band
      const { data: rehearsals, error: rError } = await supabaseAdmin
        .from("rehearsals")
        .select("id")
        .eq("band_id", bandId);

      if (rError) {
        res.status(500).json({ error: rError.message });
        return;
      }

      const rehearsalIds = (rehearsals || []).map((r: any) => r.id);
      if (rehearsalIds.length === 0) {
        res.json([]);
        return;
      }

      const { data, error } = await supabaseAdmin
        .from("rehearsal_rsvps")
        .select("rehearsal_id, status")
        .eq("user_id", req.userId!)
        .in("rehearsal_id", rehearsalIds);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json(data);
    } catch {
      res.status(500).json({ error: "Failed to fetch RSVPs" });
    }
  }
);

// POST /rehearsals/:id/rsvp
rehearsalsRouter.post(
  "/:id/rsvp",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const rehearsalId = req.params.id;
    const { status } = req.body;

    if (!status || !["going", "not_going", "maybe"].includes(status)) {
      res
        .status(400)
        .json({ error: "Status must be 'going', 'not_going', or 'maybe'" });
      return;
    }

    try {
      const { data, error } = await supabaseAdmin
        .from("rehearsal_rsvps")
        .upsert(
          {
            rehearsal_id: rehearsalId,
            user_id: req.userId,
            status,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "rehearsal_id,user_id" }
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

export { bandRehearsalsRouter, rehearsalsRouter };
