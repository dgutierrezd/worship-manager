/**
 * Music theory helpers — mirrors the Nashville Number System logic in
 * iOS `ChordProgression.swift` / `Song.swift`.
 */

import type { ChordEntry, ChordProgression } from "@/types";

export const MUSICAL_KEYS = [
  "C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B",
] as const;

export type MusicalKey = (typeof MUSICAL_KEYS)[number];

/** Transpose a key string by `steps` semitones (wraps around chromatically). */
export function transposeKey(key: string, steps: number): string {
  const idx = MUSICAL_KEYS.indexOf(key as MusicalKey);
  if (idx === -1) return key;
  const next = (((idx + steps) % 12) + 12) % 12;
  return MUSICAL_KEYS[next] ?? key;
}

export type ChordQuality = "major" | "minor" | "diminished";

export function diatonicQuality(degree: number): ChordQuality {
  switch (degree) {
    case 1:
    case 4:
    case 5:
      return "major";
    case 2:
    case 3:
    case 6:
      return "minor";
    case 7:
      return "diminished";
    default:
      return "major";
  }
}

export function romanNumeral(degree: number): string {
  switch (degree) {
    case 1:
      return "I";
    case 2:
      return "ii";
    case 3:
      return "iii";
    case 4:
      return "IV";
    case 5:
      return "V";
    case 6:
      return "vi";
    case 7:
      return "vii°";
    default:
      return String(degree);
  }
}

/** Major-scale offsets in semitones (I ii iii IV V vi vii). */
const MAJOR_SCALE_OFFSETS = [0, 2, 4, 5, 7, 9, 11] as const;

/**
 * Resolve a chord entry into an absolute chord name for the given key.
 * When `key` is missing, returns the degree number as a fallback.
 */
export function chordName(entry: ChordEntry, key?: string | null): string {
  if (!key) return String(entry.degree);
  if (entry.degree < 1 || entry.degree > 7) return String(entry.degree);

  const offset = MAJOR_SCALE_OFFSETS[entry.degree - 1] ?? 0;
  const root = transposeKey(key, offset);

  const quality = diatonicQuality(entry.degree);
  const suffix =
    quality === "major" ? "" : quality === "minor" ? "m" : "dim";

  return `${root}${suffix}${entry.modifier ?? ""}`;
}

/** Parse the `chord_sheets.content` JSON string into a progression. */
export function parseChordProgression(
  json: string | null | undefined,
): ChordProgression | null {
  if (!json) return null;
  try {
    const parsed = JSON.parse(json);
    if (!parsed || typeof parsed !== "object" || !Array.isArray(parsed.sections)) {
      return null;
    }
    return parsed as ChordProgression;
  } catch {
    return null;
  }
}
