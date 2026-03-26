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
//
// Design decisions:
//   • response_format: json_object forces the model to emit valid JSON — no markdown fences,
//     no prose. Requires a JSON *object* at root, so we use { "songs": [...] }.
//   • Positional-alignment rule prevents the model from reordering, skipping, or merging.
//   • A curated reference list anchors the model to real worship songs and prevents
//     hallucination ("10,000 Reasons" is NOT by Elevation Worship, etc.).
//   • A single complete worked example shows the exact schema once, concisely.
//   • Temperature 0.1 keeps output deterministic and factual.

const SYSTEM_PROMPT = `You are a Christian worship music database. Given a numbered list of song names, you return verified song metadata.

OUTPUT FORMAT
Return a JSON object with a single key "songs" whose value is an array — one element per input song, in the exact same order.

MANDATORY RULES
1. The "songs" array must have EXACTLY the same number of elements as the input list, in the same order. Never skip, merge, or reorder.
2. Each element's position in the output matches the same position in the input. Song #1 in → Song #1 out.
3. Use the user's title exactly as typed (do not silently rename it).
4. Set "found": true only when you are confident you recognise the specific song. Otherwise "found": false.
5. When found=false, still populate "title" with the user's original title; set all other fields to null or [].
6. All unknown string fields must be null — never an empty string "".
7. "chord_sections" must always be an array: [] when unknown.
8. The modifier in each chord must be a string or null — never an object or number.

WELL-KNOWN WORSHIP SONGS (use this for grounding — do not invent data for songs not on this list unless you are certain):
- "10,000 Reasons" / "10,000 Reasons (Bless the Lord)" → Matt Redman, G, 73 BPM
- "Good Good Father" → Chris Tomlin / Housefires, A, 68 BPM
- "What A Beautiful Name" → Hillsong Worship, D, 68 BPM
- "Way Maker" → Sinach, Bb, 80 BPM
- "Oceans (Where Feet May Fail)" → Hillsong United, D, 58 BPM
- "Reckless Love" → Cory Asbury, G, 72 BPM
- "Build My Life" → Pat Barrett, G, 72 BPM
- "Great Are You Lord" → All Sons & Daughters, G, 72 BPM
- "Do It Again" → Elevation Worship, Bb, 72 BPM
- "Graves Into Gardens" → Elevation Worship, G, 74 BPM
- "Goodness of God" → Bethel Music / Jenn Johnson, C, 67 BPM
- "Battle Belongs" → Phil Wickham, G, 140 BPM
- "Living Hope" → Phil Wickham, G, 136 BPM
- "Holy Spirit" → Bryan & Katie Torwalt, G, 72 BPM
- "King of My Heart" → Bethel Music, G, 74 BPM
- "Ever Be" → Bethel Music / Aaron Shust, A, 68 BPM
- "Come As You Are" → Crowder, G, 74 BPM
- "No Longer Slaves" → Bethel Music / Jonathan David & Melissa Helser, Bb, 62 BPM
- "O Come To The Altar" → Elevation Worship, G, 62 BPM
- "Tremble" → Mosaic MSC, Ab, 76 BPM
- "Same God" → Elevation Worship, G, 72 BPM
- "Canvas And Clay" → Pat Barrett, G, 68 BPM
- "Glorious Day" → Passion / Crowder, G, 130 BPM
- "House Of The Lord" → Phil Wickham, C, 132 BPM
- "Great Things" → Phil Wickham, G, 130 BPM
- "Raise A Hallelujah" → Bethel Music, G, 120 BPM
- "Amazing Grace (My Chains Are Gone)" → Chris Tomlin, G, 68 BPM
- "How Great Is Our God" → Chris Tomlin, G, 76 BPM
- "God Of Wonders" → Third Day / Marc Byrd, D, 80 BPM
- "Here I Am To Worship" → Tim Hughes / Hillsong, E, 72 BPM

CHORD FIELDS
- "degree": integer 1-7 using Nashville Number System (1=I tonic, 4=IV subdominant, 5=V dominant, 6=vi minor)
- "modifier": string or null. Use null for the natural diatonic chord. Examples of valid modifiers: "m", "7", "maj7", "sus2", "sus4", "add9", "dim". Do NOT use "m" on degree 2, 3, or 6 — those are already naturally minor.
- Common worship progressions: 1-4-5, 1-5-6-4, 1-4-6-5, 1-6-4-5, 4-1-5-6

VALID default_key VALUES: C, C#, D, Eb, E, F, F#, G, Ab, A, Bb, B
VALID theme VALUES: Praise, Worship, Communion, Thanksgiving, Christmas, Easter, Advent, Healing

WORKED EXAMPLE
Input: ["10,000 Reasons"]
Output:
{
  "songs": [
    {
      "found": true,
      "title": "10,000 Reasons",
      "artist": "Matt Redman",
      "default_key": "G",
      "tempo_bpm": 73,
      "duration_sec": 290,
      "lyrics": "Bless the Lord oh my soul\\nOh my soul\\nWorship His holy name\\nSing like never before\\nOh my soul\\nI'll worship Your holy name\\n\\nThe sun comes up it's a new day dawning\\nIt's time to sing Your song again\\nWhatever may pass and whatever lies before me\\nLet me be singing when the evening comes",
      "theme": "Worship",
      "youtube_url": "https://www.youtube.com/watch?v=DGIXT7ce9MA",
      "spotify_url": "https://open.spotify.com/track/1YBxST3JQMFQ3xVzADCeOY",
      "chord_sections": [
        {
          "name": "Chorus",
          "chords": [
            { "degree": 1, "modifier": null },
            { "degree": 4, "modifier": null },
            { "degree": 5, "modifier": null },
            { "degree": 1, "modifier": null }
          ]
        },
        {
          "name": "Verse",
          "chords": [
            { "degree": 1, "modifier": null },
            { "degree": 5, "modifier": null },
            { "degree": 6, "modifier": null },
            { "degree": 4, "modifier": null }
          ]
        }
      ]
    }
  ]
}`;

// MARK: - lookupSongs

export async function lookupSongs(names: string[]): Promise<AISongResult[]> {
  // Number each song so the model has an unambiguous positional anchor
  const numbered = names
    .map((n, i) => `${i + 1}. "${n}"`)
    .join("\n");

  const userMessage = `Return data for these ${names.length} worship song${names.length === 1 ? "" : "s"}:\n${numbered}`;

  const completion = await groq.chat.completions.create({
    model: "llama-3.3-70b-versatile",
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "user", content: userMessage },
    ],
    response_format: { type: "json_object" },
    temperature: 0.1,
    max_tokens: 8192,
  });

  const raw = completion.choices[0]?.message?.content ?? '{"songs":[]}';

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error(`AI returned invalid JSON: ${raw.slice(0, 200)}`);
  }

  // Extract the songs array from the { "songs": [...] } wrapper
  if (
    typeof parsed === "object" &&
    parsed !== null &&
    "songs" in parsed &&
    Array.isArray((parsed as Record<string, unknown>).songs)
  ) {
    return (parsed as { songs: AISongResult[] }).songs;
  }

  // Fallback: if the model ignored the wrapper and returned a bare array
  if (Array.isArray(parsed)) {
    return parsed as AISongResult[];
  }

  throw new Error("AI response did not contain a songs array");
}
