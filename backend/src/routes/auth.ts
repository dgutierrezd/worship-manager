import { Router, Request, Response } from "express";
import { supabaseAdmin, createAuthClient } from "../config/supabase";
import { authMiddleware, AuthRequest } from "../middleware/auth.middleware";

const router = Router();

// POST /auth/signup
router.post("/signup", async (req: Request, res: Response): Promise<void> => {
  const { email, password, full_name, instrument } = req.body;

  if (!email || !password || !full_name) {
    res.status(400).json({ error: "Email, password, and full_name are required" });
    return;
  }

  try {
    // Create user with auto-confirm (skips email verification)
    const { data: authData, error: authError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { full_name, instrument: instrument || null },
      });

    if (authError) {
      res.status(400).json({ error: authError.message });
      return;
    }

    // Upsert profile with instrument (trigger creates basic profile)
    await supabaseAdmin
      .from("profiles")
      .upsert({
        id: authData.user.id,
        full_name,
        instrument: instrument || null,
      });

    // Sign in to get session tokens (use disposable client to avoid polluting admin)
    const authClient = createAuthClient();
    const { data: session, error: signInError } =
      await authClient.auth.signInWithPassword({ email, password });

    if (signInError) {
      res.status(500).json({ error: "Account created but sign-in failed. Try signing in manually." });
      return;
    }

    res.status(201).json({
      user: { id: authData.user.id, email, full_name, instrument },
      session: session.session,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Signup failed";
    console.error("POST /auth/signup error:", message);
    res.status(500).json({ error: message });
  }
});

// POST /auth/signin
router.post("/signin", async (req: Request, res: Response): Promise<void> => {
  const { email, password } = req.body;

  if (!email || !password) {
    res.status(400).json({ error: "Email and password are required" });
    return;
  }

  try {
    // Use disposable client so the admin client stays clean
    const authClient = createAuthClient();
    const { data, error } = await authClient.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      res.status(401).json({ error: error.message });
      return;
    }

    // Fetch profile
    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("*")
      .eq("id", data.user.id)
      .single();

    res.json({ user: profile, session: data.session });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Sign in failed";
    console.error("POST /auth/signin error:", message);
    res.status(500).json({ error: message });
  }
});

// POST /auth/refresh — silently refresh an expired access token
router.post("/refresh", async (req: Request, res: Response): Promise<void> => {
  const { refresh_token } = req.body;

  if (!refresh_token) {
    res.status(400).json({ error: "refresh_token is required" });
    return;
  }

  try {
    const authClient = createAuthClient();
    const { data, error } = await authClient.auth.refreshSession({
      refresh_token,
    });

    if (error || !data.session) {
      res.status(401).json({ error: "Invalid or expired refresh token" });
      return;
    }

    res.json({
      session: {
        access_token: data.session.access_token,
        refresh_token: data.session.refresh_token,
      },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Token refresh failed";
    console.error("POST /auth/refresh error:", message);
    res.status(500).json({ error: message });
  }
});

// POST /auth/signout
router.post(
  "/signout",
  authMiddleware,
  async (_req: AuthRequest, res: Response): Promise<void> => {
    // Sign-out is client-side (discard tokens). Nothing to do server-side.
    res.json({ message: "Signed out" });
  }
);

export default router;
