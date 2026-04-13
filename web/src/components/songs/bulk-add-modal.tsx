"use client";

import { useMemo, useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { CheckCircle2, ListPlus, Music } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Modal } from "@/components/ui/modal";
import { songsApi, type BulkSongInput } from "@/lib/api/songs";
import { errorMessage } from "@/lib/utils";

interface BulkAddModalProps {
  open: boolean;
  onClose: () => void;
  bandId: string;
}

/**
 * Paste a list of songs (one per line). Each line is parsed as
 * `Title - Artist` (or `Title — Artist`, `Title – Artist`, `Title by Artist`),
 * or just `Title`. Empty lines are ignored. Submits in a single bulk POST.
 */
export function BulkAddModal({ open, onClose, bandId }: BulkAddModalProps) {
  const queryClient = useQueryClient();
  const [raw, setRaw] = useState("");
  const [addedCount, setAddedCount] = useState<number | null>(null);

  const parsed = useMemo(() => parseBulk(raw), [raw]);
  const validCount = parsed.filter((p) => p.title.length > 0).length;

  const mutation = useMutation({
    mutationFn: (songs: BulkSongInput[]) => songsApi.bulkCreate(bandId, songs),
    onSuccess: (res) => {
      queryClient.invalidateQueries({ queryKey: ["songs", bandId] });
      setAddedCount(res.songs.length);
      // Auto-close after a brief confirmation
      setTimeout(() => {
        setRaw("");
        setAddedCount(null);
        onClose();
      }, 900);
    },
  });

  const handleSubmit = () => {
    const payload = parsed
      .filter((p) => p.title.length > 0)
      .map((p) => ({ title: p.title, artist: p.artist || null }));
    if (payload.length === 0) return;
    mutation.mutate(payload);
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Add many songs"
      description="Paste a list of songs — one per line. Optionally include the artist after a dash."
      size="lg"
    >
      <div className="space-y-5">
        {/* Hint card */}
        <div className="rounded-2xl border border-accent/20 bg-accent/5 p-4">
          <p className="text-sm font-semibold text-primary">
            One song per line. Examples:
          </p>
          <pre className="mt-2 whitespace-pre rounded-lg bg-surface p-3 text-xs text-secondary">
            {"Goodness of God - Bethel\nWay Maker — Sinach\nBuild My Life"}
          </pre>
        </div>

        {/* Editor */}
        <div>
          <label htmlFor="bulk-songs" className="label">
            Songs
          </label>
          <textarea
            id="bulk-songs"
            value={raw}
            onChange={(e) => setRaw(e.target.value)}
            rows={10}
            placeholder={"Goodness of God - Bethel\nWay Maker - Sinach\n…"}
            className="input resize-y font-mono text-sm"
          />
        </div>

        {/* Preview */}
        {parsed.length > 0 && (
          <div>
            <div className="mb-2 flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-wide text-secondary">
                Preview
              </p>
              <span className="text-xs font-semibold text-accent">
                {validCount} song{validCount === 1 ? "" : "s"}
              </span>
            </div>
            <ul className="max-h-64 overflow-y-auto divide-y divide-divider rounded-xl border border-divider bg-surface">
              {parsed.map((p, i) => (
                <li
                  key={i}
                  className="flex items-center gap-3 px-3 py-2 text-sm"
                >
                  <Music
                    className={`h-4 w-4 shrink-0 ${
                      p.title ? "text-accent" : "text-divider"
                    }`}
                  />
                  <div className="min-w-0 flex-1">
                    <p
                      className={`truncate font-medium ${
                        p.title ? "text-primary" : "text-secondary italic"
                      }`}
                    >
                      {p.title || "(empty line)"}
                    </p>
                    {p.artist && (
                      <p className="truncate text-xs text-secondary">
                        {p.artist}
                      </p>
                    )}
                  </div>
                </li>
              ))}
            </ul>
          </div>
        )}

        {addedCount !== null && (
          <p className="flex items-center gap-2 rounded-xl border border-going/30 bg-going/10 px-4 py-3 text-sm text-going">
            <CheckCircle2 className="h-4 w-4" /> Added {addedCount} songs
          </p>
        )}
        {mutation.error && (
          <p className="rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
            {errorMessage(mutation.error)}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            type="button"
            variant="accent"
            onClick={handleSubmit}
            loading={mutation.isPending}
            disabled={validCount === 0}
          >
            <ListPlus className="h-4 w-4" /> Add {validCount > 0 ? validCount : ""}{" "}
            song{validCount === 1 ? "" : "s"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}

// MARK: - Parsing

interface ParsedLine {
  title: string;
  artist: string;
}

function parseBulk(text: string): ParsedLine[] {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .map(parseLine);
}

const SEPARATORS = [" — ", " – ", " - ", " by "];

function parseLine(line: string): ParsedLine {
  for (const sep of SEPARATORS) {
    const idx = line.toLowerCase().indexOf(sep.toLowerCase());
    if (idx > 0) {
      return {
        title: line.slice(0, idx).trim(),
        artist: line.slice(idx + sep.length).trim(),
      };
    }
  }
  return { title: line, artist: "" };
}
