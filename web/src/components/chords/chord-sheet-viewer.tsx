"use client";

import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Hash, Minus, Music4, Plus } from "lucide-react";
import { songsApi } from "@/lib/api/songs";
import {
  chordName,
  parseChordProgression,
  romanNumeral,
  transposeKey,
} from "@/lib/music";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import type { ChordEntry, ChordSection, ChordSheet } from "@/types";

interface ChordSheetViewerProps {
  songId: string;
  baseKey?: string | null;
}

/**
 * Renders the most recent chord sheet for a song.
 *
 * Features:
 * - Chromatic transpose (+/- semitones) with a Nashville-number fallback
 * - Sections displayed as cards (Verse / Chorus / Bridge / …)
 * - Pass chords render smaller & de-emphasized, matching iOS
 * - Handles the empty and loading states gracefully
 */
export function ChordSheetViewer({ songId, baseKey }: ChordSheetViewerProps) {
  const [steps, setSteps] = useState(0);
  const [useNashville, setUseNashville] = useState(false);

  const query = useQuery({
    queryKey: ["chords", songId],
    queryFn: () => songsApi.listChords(songId),
  });

  const sheet: ChordSheet | undefined = query.data?.[0];
  const progression = useMemo(
    () => parseChordProgression(sheet?.content),
    [sheet?.content],
  );

  const displayKey = baseKey ? transposeKey(baseKey, steps) : null;

  if (query.isLoading) {
    return (
      <div className="space-y-3">
        <Skeleton className="h-24 w-full" />
        <Skeleton className="h-24 w-full" />
      </div>
    );
  }

  if (query.isError) {
    return (
      <div className="rounded-2xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
        Couldn&apos;t load chord sheet.
      </div>
    );
  }

  if (!progression || progression.sections.length === 0) {
    return (
      <div className="flex items-center gap-3 rounded-2xl border border-dashed border-divider bg-surface/70 p-6 text-secondary">
        <Music4 className="h-5 w-5 text-accent" />
        <p className="text-sm">
          No chord sheet yet. Create one in the iOS app and it&apos;ll appear
          here instantly.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      {/* Toolbar */}
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-divider bg-surface p-4 shadow-card">
        <div className="flex items-center gap-2">
          <span className="text-xs font-semibold uppercase tracking-wider text-secondary">
            Key
          </span>
          <div className="flex items-center gap-1">
            <button
              type="button"
              aria-label="Transpose down"
              onClick={() => setSteps((s) => s - 1)}
              disabled={useNashville || !baseKey}
              className="flex h-8 w-8 items-center justify-center rounded-full border border-divider bg-surface text-secondary transition hover:border-accent/40 hover:text-primary disabled:cursor-not-allowed disabled:opacity-40"
            >
              <Minus className="h-4 w-4" />
            </button>
            <div className="min-w-14 rounded-full bg-accent/15 px-3 py-1 text-center font-mono text-sm font-semibold text-accent">
              {useNashville ? "1–7" : (displayKey ?? "—")}
            </div>
            <button
              type="button"
              aria-label="Transpose up"
              onClick={() => setSteps((s) => s + 1)}
              disabled={useNashville || !baseKey}
              className="flex h-8 w-8 items-center justify-center rounded-full border border-divider bg-surface text-secondary transition hover:border-accent/40 hover:text-primary disabled:cursor-not-allowed disabled:opacity-40"
            >
              <Plus className="h-4 w-4" />
            </button>
            {steps !== 0 && !useNashville && (
              <button
                type="button"
                onClick={() => setSteps(0)}
                className="ml-1 text-xs font-semibold text-secondary hover:text-primary"
              >
                Reset
              </button>
            )}
          </div>
        </div>

        <button
          type="button"
          onClick={() => setUseNashville((v) => !v)}
          className={cn(
            "inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-semibold transition",
            useNashville
              ? "border-accent bg-accent/15 text-accent"
              : "border-divider bg-surface text-secondary hover:border-accent/40 hover:text-primary",
          )}
        >
          <Hash className="h-3.5 w-3.5" />
          Nashville numbers
        </button>
      </div>

      {/* Sections */}
      <div className="space-y-4">
        {progression.sections.map((section, idx) => (
          <SectionCard
            key={section.id ?? `${section.name}-${idx}`}
            section={section}
            displayKey={useNashville ? null : displayKey}
          />
        ))}
      </div>

      {sheet?.title && (
        <p className="text-center text-xs text-secondary">
          From chord sheet: <span className="font-semibold">{sheet.title}</span>
          {sheet.instrument ? ` · ${sheet.instrument}` : ""}
        </p>
      )}
    </div>
  );
}

/* ---------------------------- Sub-components ---------------------------- */

function SectionCard({
  section,
  displayKey,
}: {
  section: ChordSection;
  displayKey: string | null;
}) {
  return (
    <article className="rounded-2xl border border-divider bg-surface p-5 shadow-card">
      <header className="mb-4 flex items-center justify-between">
        <h3 className="font-display text-lg font-semibold text-primary">
          {section.name}
        </h3>
        <span className="text-xs font-semibold uppercase tracking-wider text-secondary">
          {section.chords.length}{" "}
          {section.chords.length === 1 ? "chord" : "chords"}
        </span>
      </header>

      {section.chords.length === 0 ? (
        <p className="text-sm italic text-secondary">No chords yet.</p>
      ) : (
        <div className="flex flex-wrap gap-2">
          {section.chords.map((chord, i) => (
            <ChordChip
              key={chord.id ?? `${section.id}-${i}`}
              chord={chord}
              displayKey={displayKey}
            />
          ))}
        </div>
      )}
    </article>
  );
}

function ChordChip({
  chord,
  displayKey,
}: {
  chord: ChordEntry;
  displayKey: string | null;
}) {
  const label = displayKey
    ? chordName(chord, displayKey)
    : romanNumeral(chord.degree) + (chord.modifier ?? "");

  const isPass = !!chord.isPass;

  return (
    <span
      className={cn(
        "inline-flex items-center justify-center rounded-xl border font-mono font-semibold transition",
        isPass
          ? "border-divider bg-surfaceMuted px-3 py-1.5 text-xs text-secondary"
          : "border-accent/40 bg-accent/10 px-4 py-2 text-base text-primary",
      )}
      title={
        displayKey
          ? `${romanNumeral(chord.degree)}${chord.modifier ?? ""}`
          : undefined
      }
    >
      {label}
    </span>
  );
}
