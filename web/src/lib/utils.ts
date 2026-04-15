import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * Tailwind-aware className merger. Used by every UI primitive to cleanly
 * combine base styles with caller overrides.
 */
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

/** Format a duration in seconds as "m:ss". Returns empty string if null. */
export function formatDuration(seconds?: number | null): string {
  if (!seconds || seconds <= 0) return "";
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${String(s).padStart(2, "0")}`;
}

/** Uppercase ISO-8601 helper that gracefully handles null input. */
export function parseISODate(iso?: string | null): Date | null {
  if (!iso) return null;
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? null : d;
}

/** Human-readable date, e.g. "Sun, Apr 14". */
export function formatShortDate(iso?: string | null): string {
  const d = parseISODate(iso);
  if (!d) return "";
  return d.toLocaleDateString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric",
  });
}

/** Human-readable time, e.g. "7:30 PM". */
export function formatTime(iso?: string | null): string {
  const d = parseISODate(iso);
  if (!d) return "";
  return d.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit",
  });
}

/** Pretty service-type label mirroring iOS `Setlist.serviceTypeDisplay`. */
export function serviceTypeDisplay(type?: string | null): string {
  switch (type) {
    case "sunday_morning":
      return "Sunday Morning";
    case "sunday_evening":
      return "Sunday Evening";
    case "wednesday":
      return "Wednesday";
    case "special":
      return "Special Event";
    default:
      return "Service";
  }
}

/** Guard an unknown error value into a readable string. */
export function errorMessage(err: unknown): string {
  if (err instanceof Error) return err.message;
  if (typeof err === "string") return err;
  return "Something went wrong";
}
