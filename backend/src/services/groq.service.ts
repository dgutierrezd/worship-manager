import Groq from "groq-sdk";

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// MARK: - Types

export interface AISongResult {
  found: boolean;
  title: string;
  artist: string | null;
  default_key: string | null;
  tempo_bpm: number | null;
  duration_sec: number | null;
  lyrics: string | null;
  theme: string | null;
  youtube_url: string | null;
  spotify_url: string | null;
  chord_sections: AIChordSection[];
}

export interface AIChordSection {
  name: string;
  chords: AIChordEntry[];
}

export interface AIChordEntry {
  degree: number;
  modifier: string | null;
}

// MARK: - System Prompt

const SYSTEM_PROMPT = `You are a worship music expert database. Given a list of song names, return a JSON array with one object per song.

Each object MUST have these exact fields:
{
  "found": true or false,
  "title": "exact song title string",
  "artist": "artist or band name string, or null",
  "default_key": "musical key string e.g. G, C, D, Eb, F, Ab, A, Bb, E, F# — or null",
  "tempo_bpm": integer beats-per-minute or null,
  "duration_sec": integer total seconds or null,
  "lyrics": "full song lyrics as a string or null",
  "theme": "worship theme string e.g. Praise, Worship, Communion, Thanksgiving, Advent — or null",
  "youtube_url": "official YouTube URL string or null",
  "spotify_url": "Spotify track URL string or null",
  "chord_sections": [
    {
      "name": "section name e.g. Verse 1, Chorus, Bridge, Pre-Chorus, Intro, Outro",
      "chords": [
        { "degree": 1, "modifier": null },
        { "degree": 4, "modifier": null },
        { "degree": 5, "modifier": null },
        { "degree": 6, "modifier": "m" }
      ]
    }
  ]
}

Chord degree rules (Nashville Number System):
- Degrees are integers 1 through 7
- 1=tonic, 2=supertonic, 3=mediant, 4=subdominant, 5=dominant, 6=submediant, 7=leading tone
- modifier examples: null for plain major, "m" for minor, "7" for dominant 7th, "maj7" for major 7th, "sus2", "sus4", "add9", "dim"
- chord_sections should capture all distinct song sections with their chord progressions

If a song is not recognized, set found=false and use null for all optional fields and an empty array for chord_sections.

CRITICAL: Your entire response must be a valid JSON array only. No markdown, no code fences (no \`\`\`), no explanation text — just the raw JSON array starting with [ and ending with ].`;

// MARK: - lookupSongs

export async function lookupSongs(names: string[]): Promise<AISongResult[]> {
  const userMessage = `Return song data for these worship songs: ${names
    .map((n) => `"${n}"`)
    .join(", ")}`;

  const completion = await groq.chat.completions.create({
    model: "llama-3.3-70b-versatile",
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "user", content: userMessage },
    ],
    temperature: 0.2,
    max_tokens: 8192,
  });

  const raw = completion.choices[0]?.message?.content ?? "[]";

  // Strip any accidental markdown code fences the model may have added
  const clean = raw
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```\s*$/i, "")
    .trim();

  let parsed: unknown;
  try {
    parsed = JSON.parse(clean);
  } catch {
    throw new Error(`AI returned invalid JSON: ${clean.slice(0, 200)}`);
  }

  if (!Array.isArray(parsed)) {
    throw new Error("AI response was not a JSON array");
  }

  return parsed as AISongResult[];
}
