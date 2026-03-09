import { Response, NextFunction } from "express";
import { AuthRequest } from "./auth.middleware";
import { supabaseAdmin } from "../config/supabase";

export interface BandRequest extends AuthRequest {
  bandId?: string;
  bandRole?: "leader" | "member";
}

// Checks that the authenticated user is a member of the band specified by :id
export async function bandAccessMiddleware(
  req: BandRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const bandId = req.params.id;

  if (!bandId) {
    res.status(400).json({ error: "Band ID is required" });
    return;
  }

  try {
    const { data: membership, error } = await supabaseAdmin
      .from("band_members")
      .select("role")
      .eq("band_id", bandId)
      .eq("user_id", req.userId!)
      .single();

    if (error || !membership) {
      res.status(403).json({ error: "You are not a member of this band" });
      return;
    }

    req.bandId = bandId;
    req.bandRole = membership.role as "leader" | "member";
    next();
  } catch {
    res.status(500).json({ error: "Failed to verify band access" });
  }
}

// Ensures the user is a leader of the band
export async function leaderOnlyMiddleware(
  req: BandRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  if (req.bandRole !== "leader") {
    res.status(403).json({ error: "Only band leaders can perform this action" });
    return;
  }
  next();
}
