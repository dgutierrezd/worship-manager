"use client";

import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Check,
  ChevronDown,
  ChevronUp,
  Pencil,
  Plus,
  Save,
  Trash2,
  X,
} from "lucide-react";
import { songsApi } from "@/lib/api/songs";
import {
  chordName,
  parseChordProgression,
  romanNumeral,
} from "@/lib/music";
import { cn, errorMessage } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type {
  ChordEntry,
  ChordProgression,
  ChordSection,
  ChordSheet,
} from "@/types";

/**
 * Chord sheet editor — build Nashville-number progressions section by section.
 * Mirrors iOS `ChordsEditorView`:
 *   • add/remove sections with preset names
 *   • add chord entries with degree picker, modifier, and "pass chord" toggle
 *   • reorder entries via ↑/↓
 *   • saves to `POST /songs/:id/chords` (new) or `PUT /chords/:id` (existing)
 */

interface ChordSheetEditorProps {
  songId: string;
  baseKey?: string | null;
  onDone: () => void;
}

const SECTION_PRESETS = [
  "Intro",
  "Verse",
  "Pre-Chorus",
  "Chorus",
  "Bridge",
  "Instrumental",
  "Outro",
  "Tag",
];

const MODIFIER_OPTIONS = [
  { value: "", label: "maj" },
  { value: "m", label: "m" },
  { value: "7", label: "7" },
  { value: "maj7", label: "maj7" },
  { value: "m7", label: "m7" },
  { value: "sus2", label: "sus2" },
  { value: "sus4", label: "sus4" },
  { value: "add9", label: "add9" },
  { value: "dim", label: "dim" },
  { value: "aug", label: "aug" },
];

export function ChordSheetEditor({
  songId,
  baseKey,
  onDone,
}: ChordSheetEditorProps) {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ["chords", songId],
    queryFn: () => songsApi.listChords(songId),
  });

  const existingSheet: ChordSheet | undefined = query.data?.[0];
  const initial = parseChordProgression(existingSheet?.content) ?? {
    sections: [],
  };

  const [progression, setProgression] = useState<ChordProgression>(initial);
  const [error, setError] = useState<string | null>(null);
  const [hydrated, setHydrated] = useState(false);

  // Hydrate local state once from the server response.
  useEffect(() => {
    if (hydrated || !query.data) return;
    const next = parseChordProgression(existingSheet?.content);
    if (next) setProgression(next);
    setHydrated(true);
  }, [query.data, hydrated, existingSheet?.content]);

  const saveMutation = useMutation({
    mutationFn: async () => {
      const content = JSON.stringify(progression);
      if (existingSheet) {
        return songsApi.updateChordSheet(existingSheet.id, { content });
      }
      return songsApi.createChordSheet(songId, {
        content,
        title: "Chord Sheet",
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["chords", songId] });
      onDone();
    },
    onError: (err) => setError(errorMessage(err)),
  });

  const addSection = (name: string) => {
    setProgression({
      sections: [
        ...progression.sections,
        { id: uuid(), name, chords: [] },
      ],
    });
  };

  const removeSection = (id: string) => {
    setProgression({
      sections: progression.sections.filter((s) => s.id !== id),
    });
  };

  const renameSection = (id: string, name: string) => {
    setProgression({
      sections: progression.sections.map((s) =>
        s.id === id ? { ...s, name } : s,
      ),
    });
  };

  const updateSectionChords = (id: string, chords: ChordEntry[]) => {
    setProgression({
      sections: progression.sections.map((s) =>
        s.id === id ? { ...s, chords } : s,
      ),
    });
  };

  if (query.isLoading) {
    return <div className="skeleton h-40 rounded-2xl" />;
  }

  return (
    <div className="space-y-5">
      {/* Toolbar */}
      <div className="sticky top-0 z-10 -mx-6 flex items-center justify-between gap-2 border-b border-divider bg-background/80 px-6 py-3 backdrop-blur">
        <p className="text-xs font-semibold uppercase tracking-widest text-accent">
          Editing chord sheet
        </p>
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="sm" onClick={onDone}>
            <X className="h-4 w-4" /> Cancel
          </Button>
          <Button
            variant="accent"
            size="sm"
            loading={saveMutation.isPending}
            onClick={() => saveMutation.mutate()}
          >
            <Save className="h-4 w-4" /> Save
          </Button>
        </div>
      </div>

      {error && (
        <p className="rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
          {error}
        </p>
      )}

      {/* Sections */}
      <div className="space-y-4">
        {progression.sections.map((section) => (
          <SectionEditor
            key={section.id}
            section={section}
            baseKey={baseKey ?? null}
            onRename={(name) => renameSection(section.id, name)}
            onRemove={() => removeSection(section.id)}
            onChange={(chords) => updateSectionChords(section.id, chords)}
          />
        ))}
      </div>

      {/* Add-section picker */}
      <div className="rounded-2xl border border-dashed border-divider bg-surface/60 p-5">
        <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-secondary">
          Add section
        </p>
        <div className="flex flex-wrap gap-2">
          {SECTION_PRESETS.map((name) => (
            <button
              key={name}
              type="button"
              onClick={() => addSection(name)}
              className="rounded-full border border-divider bg-surface px-4 py-1.5 text-xs font-semibold text-primary transition hover:border-accent/50 hover:bg-accentMuted/40"
            >
              <Plus className="mr-1 inline h-3 w-3" />
              {name}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

/* --------------------------- Section editor --------------------------- */

interface SectionEditorProps {
  section: ChordSection;
  baseKey: string | null;
  onRename: (name: string) => void;
  onRemove: () => void;
  onChange: (chords: ChordEntry[]) => void;
}

function SectionEditor({
  section,
  baseKey,
  onRename,
  onRemove,
  onChange,
}: SectionEditorProps) {
  const [renaming, setRenaming] = useState(false);
  const [editingIndex, setEditingIndex] = useState<number | null>(null);

  const addChord = () => {
    const newEntry: ChordEntry = {
      id: uuid(),
      degree: 1,
      isPass: false,
      modifier: null,
    };
    onChange([...section.chords, newEntry]);
    setEditingIndex(section.chords.length);
  };

  const updateChord = (idx: number, patch: Partial<ChordEntry>) => {
    onChange(
      section.chords.map((c, i) => (i === idx ? { ...c, ...patch } : c)),
    );
  };

  const removeChord = (idx: number) => {
    onChange(section.chords.filter((_, i) => i !== idx));
    if (editingIndex === idx) setEditingIndex(null);
  };

  const moveChord = (idx: number, dir: -1 | 1) => {
    const next = [...section.chords];
    const target = idx + dir;
    if (target < 0 || target >= next.length) return;
    const a = next[idx]!;
    const b = next[target]!;
    next[idx] = b;
    next[target] = a;
    onChange(next);
  };

  return (
    <section className="rounded-2xl border border-divider bg-surface p-5 shadow-card">
      <header className="mb-4 flex items-center justify-between gap-2">
        {renaming ? (
          <Input
            autoFocus
            value={section.name}
            onChange={(e) => onRename(e.target.value)}
            onBlur={() => setRenaming(false)}
            onKeyDown={(e) => {
              if (e.key === "Enter") setRenaming(false);
            }}
            className="max-w-xs"
          />
        ) : (
          <button
            type="button"
            onClick={() => setRenaming(true)}
            className="group flex items-center gap-2"
          >
            <h3 className="font-display text-lg font-semibold text-primary">
              {section.name}
            </h3>
            <Pencil className="h-3.5 w-3.5 text-secondary opacity-0 transition group-hover:opacity-100" />
          </button>
        )}
        <button
          type="button"
          onClick={onRemove}
          aria-label="Remove section"
          className="rounded-full p-1.5 text-secondary transition hover:bg-danger/10 hover:text-danger"
        >
          <Trash2 className="h-4 w-4" />
        </button>
      </header>

      {section.chords.length === 0 ? (
        <p className="mb-3 text-sm italic text-secondary">No chords yet.</p>
      ) : (
        <div className="mb-3 flex flex-wrap items-center gap-2">
          {section.chords.map((chord, idx) => (
            <div key={chord.id} className="relative">
              <ChordChipEditable
                chord={chord}
                baseKey={baseKey}
                isEditing={editingIndex === idx}
                onClick={() => setEditingIndex(idx)}
              />
              {editingIndex === idx && (
                <ChordPopover
                  chord={chord}
                  onChange={(patch) => updateChord(idx, patch)}
                  onRemove={() => removeChord(idx)}
                  onMoveLeft={() => moveChord(idx, -1)}
                  onMoveRight={() => moveChord(idx, 1)}
                  onClose={() => setEditingIndex(null)}
                />
              )}
            </div>
          ))}
        </div>
      )}

      <button
        type="button"
        onClick={addChord}
        className="inline-flex items-center gap-1 rounded-full border border-dashed border-divider px-3 py-1.5 text-xs font-semibold text-secondary transition hover:border-accent/50 hover:text-accent"
      >
        <Plus className="h-3 w-3" /> Add chord
      </button>
    </section>
  );
}

/* ----------------------------- Chord chip ----------------------------- */

interface ChordChipEditableProps {
  chord: ChordEntry;
  baseKey: string | null;
  isEditing: boolean;
  onClick: () => void;
}

function ChordChipEditable({
  chord,
  baseKey,
  isEditing,
  onClick,
}: ChordChipEditableProps) {
  const label = baseKey
    ? chordName(chord, baseKey)
    : romanNumeral(chord.degree) + (chord.modifier ?? "");
  const isPass = !!chord.isPass;

  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "inline-flex items-center justify-center rounded-xl border font-mono font-semibold transition",
        isPass
          ? "border-divider bg-surfaceMuted px-3 py-1.5 text-xs text-secondary"
          : "border-accent/40 bg-accent/10 px-4 py-2 text-base text-primary",
        isEditing && "ring-2 ring-accent ring-offset-2 ring-offset-surface",
      )}
    >
      {label}
    </button>
  );
}

/* ----------------------------- Chord popover ----------------------------- */

interface ChordPopoverProps {
  chord: ChordEntry;
  onChange: (patch: Partial<ChordEntry>) => void;
  onRemove: () => void;
  onMoveLeft: () => void;
  onMoveRight: () => void;
  onClose: () => void;
}

function ChordPopover({
  chord,
  onChange,
  onRemove,
  onMoveLeft,
  onMoveRight,
  onClose,
}: ChordPopoverProps) {
  return (
    <div className="absolute left-0 top-full z-20 mt-2 w-72 rounded-2xl border border-divider bg-surface p-4 shadow-elevated">
      {/* Degree picker */}
      <p className="label">Degree</p>
      <div className="mb-3 grid grid-cols-7 gap-1">
        {[1, 2, 3, 4, 5, 6, 7].map((d) => (
          <button
            key={d}
            type="button"
            onClick={() => onChange({ degree: d })}
            className={cn(
              "flex h-8 items-center justify-center rounded-lg border text-xs font-semibold transition",
              chord.degree === d
                ? "border-accent bg-accent text-white"
                : "border-divider bg-surface text-primary hover:border-accent/40",
            )}
          >
            {romanNumeral(d)}
          </button>
        ))}
      </div>

      {/* Modifier */}
      <p className="label">Modifier</p>
      <div className="mb-3 flex flex-wrap gap-1">
        {MODIFIER_OPTIONS.map((opt) => {
          const active = (chord.modifier ?? "") === opt.value;
          return (
            <button
              key={opt.value || "maj"}
              type="button"
              onClick={() => onChange({ modifier: opt.value || null })}
              className={cn(
                "rounded-full border px-2.5 py-1 text-[11px] font-semibold transition",
                active
                  ? "border-accent bg-accent/15 text-accent"
                  : "border-divider bg-surface text-secondary hover:border-accent/40",
              )}
            >
              {opt.label}
            </button>
          );
        })}
      </div>

      {/* Pass toggle */}
      <label className="mb-4 flex items-center gap-2 text-xs font-medium text-secondary">
        <input
          type="checkbox"
          checked={!!chord.isPass}
          onChange={(e) => onChange({ isPass: e.target.checked })}
          className="h-3.5 w-3.5 accent-accent"
        />
        Pass chord (shorter / softer)
      </label>

      {/* Actions */}
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-1">
          <button
            type="button"
            onClick={onMoveLeft}
            aria-label="Move left"
            className="rounded-full p-1.5 text-secondary hover:bg-surfaceMuted hover:text-primary"
          >
            <ChevronUp className="h-4 w-4 -rotate-90" />
          </button>
          <button
            type="button"
            onClick={onMoveRight}
            aria-label="Move right"
            className="rounded-full p-1.5 text-secondary hover:bg-surfaceMuted hover:text-primary"
          >
            <ChevronDown className="h-4 w-4 -rotate-90" />
          </button>
          <button
            type="button"
            onClick={onRemove}
            aria-label="Remove chord"
            className="rounded-full p-1.5 text-secondary hover:bg-danger/10 hover:text-danger"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="inline-flex items-center gap-1 rounded-full bg-primary px-3 py-1.5 text-[11px] font-semibold text-white"
        >
          <Check className="h-3 w-3" /> Done
        </button>
      </div>
    </div>
  );
}

/* ------------------------------ utilities ------------------------------ */

function uuid(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID();
  }
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}
