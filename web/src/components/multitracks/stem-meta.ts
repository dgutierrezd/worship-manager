import type { StemKind } from "@/types";
import {
  Drum,
  Guitar,
  Mic,
  Music,
  Music2,
  Music4,
  Piano,
  Radio,
  Waves,
  type LucideIcon,
} from "lucide-react";

export const STEM_KINDS: StemKind[] = [
  "click",
  "guide",
  "drums",
  "bass",
  "keys",
  "pad",
  "vocal",
  "guitar",
  "other",
];

export function stemKindLabel(kind: StemKind): string {
  switch (kind) {
    case "click":
      return "Click";
    case "guide":
      return "Guide";
    case "drums":
      return "Drums";
    case "bass":
      return "Bass";
    case "keys":
      return "Keys";
    case "pad":
      return "Pad";
    case "vocal":
      return "Vocal";
    case "guitar":
      return "Guitar";
    default:
      return "Other";
  }
}

export function stemKindIcon(kind: StemKind): LucideIcon {
  switch (kind) {
    case "click":
      return Radio;
    case "guide":
      return Waves;
    case "drums":
      return Drum;
    case "bass":
      return Music4;
    case "keys":
      return Piano;
    case "pad":
      return Music2;
    case "vocal":
      return Mic;
    case "guitar":
      return Guitar;
    default:
      return Music;
  }
}

/**
 * Default kind for every uploaded file — the user picks the real instrument
 * manually in the folder-upload UI before confirming.
 */
export function guessKindFromFilename(_filename: string): StemKind {
  return "other";
}

/**
 * Strip the file extension and replace dashes/underscores with spaces to get a
 * human-readable default label.
 */
export function labelFromFilename(filename: string): string {
  return filename
    .replace(/\.[^.]+$/, "")
    .replace(/[-_]+/g, " ")
    .trim();
}

export function formatStemTime(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds < 0) return "0:00";
  const total = Math.floor(seconds);
  const m = Math.floor(total / 60);
  const s = total % 60;
  return `${m}:${s.toString().padStart(2, "0")}`;
}
