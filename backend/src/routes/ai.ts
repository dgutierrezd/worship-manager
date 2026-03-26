import { Router, Response } from "express";
import { authMiddleware, AuthRequest } from "../middleware/auth.middleware";

const router = Router();

const CLAUDE_ENDPOINT = "https://api.anthropic.com/v1/messages";
const CLAUDE_MODEL    = "claude-sonnet-4-20250514";
const MAX_TOKENS      = 4096;

const SYSTEM_PROMPT = `You are an expert worship music librarian. \
For every request you receive, respond ONLY with a valid JSON object — \
no markdown fences, no prose, no extra keys. \
Use exactly the schema the user specifies.`;

function buildUserMessage(names: string[]): string {
  const numbered = names.map((n, i) => `  ${i + 1}. ${n}`).join("\n");

  return `Look up the following worship songs and return a JSON object with this exact structure:

{
  "results": [
    {
      "found": true,
      "title": "Song Title As Commonly Known",
      "artist": "Original artist or songwriter",
      "default_key": "G",
      "tempo_bpm": 72,
      "duration_sec": 210,
      "lyrics": "First verse and chorus text (max 250 words)",
      "theme": "Single worship theme word (e.g. Grace, Praise, Hope, Surrender)",
      "youtube_url": "https://www.youtube.com/watch?v=VALID_ID",
      "spotify_url": "https://open.spotify.com/track/VALID_ID",
      "chord_sections": [
        {
          "name": "Verse",
          "chords": [
            { "degree": 1, "modifier": null },
            { "degree": 4, "modifier": null },
            { "degree": 5, "modifier": null },
            { "degree": 1, "modifier": null }
          ]
        },
        {
          "name": "Chorus",
          "chords": [
            { "degree": 4, "modifier": null },
            { "degree": 1, "modifier": null },
            { "degree": 5, "modifier": null },
            { "degree": 6, "modifier": "m" }
          ]
        }
      ]
    }
  ]
}

Songs to look up:
${numbered}

RULES:
1. Return exactly one result object per song, in the same order as the input list.
2. "found": true if you have reliable data; false if unrecognised — set all other fields to null when found is false, except "title" which keeps the input name.
3. "chord_sections" uses the Nashville Number System:
   - "degree" is an integer 1–7 representing the scale degree.
   - "modifier" is null (major), "m" (minor), "7" (dominant 7), "maj7" (major 7), "sus2", "sus4", "aug", "dim", "add9" — no other values.
   - Include at least Verse and Chorus for known songs; add Pre-Chorus, Bridge, Outro as available.
   - Each section needs at least 4 chord entries.
4. "default_key" must be a valid key signature string (e.g. "G", "A", "Bb", "F#", "Cm").
5. "tempo_bpm" and "duration_sec" must be integers, not strings.
6. "lyrics" — include the first full verse and chorus only; newlines are allowed.
7. "youtube_url" and "spotify_url" — use real, publicly accessible URLs only. If you are not confident in the URL, set the field to null.
8. "theme" — a single capitalised English word.
9. Output ONLY the JSON object. No markdown, no code fences, no explanation text.`;
}

// POST /ai/song-lookup
// Body: { names: string[] }   (max 10 names)
// Returns the raw Claude JSON response — parsing is done on the iOS client.
router.post(
  "/song-lookup",
  authMiddleware,
  async (req: AuthRequest, res: Response): Promise<void> => {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      res.status(503).json({ error: "AI service not configured" });
      return;
    }

    const { names } = req.body as { names?: unknown };

    if (!Array.isArray(names) || names.length === 0) {
      res.status(400).json({ error: "names must be a non-empty array of strings" });
      return;
    }

    const songNames: string[] = names
      .slice(0, 10)
      .map((n) => String(n).trim())
      .filter((n) => n.length > 0);

    if (songNames.length === 0) {
      res.status(400).json({ error: "names must contain at least one non-empty string" });
      return;
    }

    const payload = {
      model:      CLAUDE_MODEL,
      max_tokens: MAX_TOKENS,
      system:     SYSTEM_PROMPT,
      messages: [
        { role: "user", content: buildUserMessage(songNames) },
      ],
    };

    const claudeRes = await fetch(CLAUDE_ENDPOINT, {
      method:  "POST",
      headers: {
        "x-api-key":         apiKey,
        "anthropic-version": "2023-06-01",
        "content-type":      "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!claudeRes.ok) {
      const errBody = await claudeRes.text();
      console.error(`Claude API error ${claudeRes.status}:`, errBody);
      res.status(502).json({
        error: `Claude API returned ${claudeRes.status}`,
        detail: errBody,
      });
      return;
    }

    const envelope = (await claudeRes.json()) as {
      content: Array<{ type: string; text?: string }>;
    };

    const text = envelope.content.find((b) => b.type === "text")?.text ?? "";

    if (!text) {
      res.status(502).json({ error: "Claude returned an empty response" });
      return;
    }

    // Forward the raw text so the iOS client can decode it into AISongResult[]
    res.json({ result: text });
  }
);

export default router;
