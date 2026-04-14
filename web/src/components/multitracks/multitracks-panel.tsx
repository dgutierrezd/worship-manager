"use client";

import { useState } from "react";
import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import {
  FolderOpen,
  Pause,
  Play,
  Plus,
  Rewind,
  Square,
  Trash2,
  Pencil,
  Waves,
} from "lucide-react";
import { songsApi, type StemInput } from "@/lib/api/songs";
import { errorMessage } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import type { SongStem, StemKind } from "@/types";
import { useMultitrackEngine } from "./use-multitrack-engine";
import {
  formatStemTime,
  stemKindIcon,
  stemKindLabel,
} from "./stem-meta";
import { AddStemModal } from "./add-stem-modal";
import { FolderUploadModal } from "./folder-upload-modal";

interface MultitracksPanelProps {
  songId: string;
}

export function MultitracksPanel({ songId }: MultitracksPanelProps) {
  const queryClient = useQueryClient();

  const stemsQuery = useQuery({
    queryKey: ["song-stems", songId],
    queryFn: () => songsApi.listStems(songId),
    enabled: !!songId,
  });

  const stems = stemsQuery.data ?? [];
  const engine = useMultitrackEngine(stems);

  const [showAdd, setShowAdd] = useState(false);
  const [showFolderUpload, setShowFolderUpload] = useState(false);
  const [editing, setEditing] = useState<SongStem | null>(null);

  const invalidateStems = () =>
    queryClient.invalidateQueries({ queryKey: ["song-stems", songId] });

  const addMutation = useMutation({
    mutationFn: (input: StemInput) => songsApi.addStem(songId, input),
    onSuccess: () => {
      invalidateStems();
      setShowAdd(false);
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({
      stemId,
      patch,
    }: {
      stemId: string;
      patch: { kind?: StemKind; label?: string; url?: string };
    }) => songsApi.updateStem(songId, stemId, patch),
    onSuccess: () => {
      invalidateStems();
      setEditing(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (stemId: string) => songsApi.removeStem(songId, stemId),
    onSuccess: () => invalidateStems(),
  });

  if (stemsQuery.isLoading) {
    return (
      <div className="space-y-3">
        <Skeleton className="h-24 w-full" />
        <Skeleton className="h-16 w-full" />
        <Skeleton className="h-16 w-full" />
      </div>
    );
  }

  return (
    <div className="space-y-5">
      {/* Transport bar — only visible when we have stems */}
      {stems.length > 0 && (
        <div className="rounded-3xl border border-divider bg-surface p-6 shadow-card">
          {engine.isLoading ? (
            <div className="space-y-2">
              <div className="h-2 w-full overflow-hidden rounded-full bg-surfaceMuted">
                <div
                  className="h-full bg-accent transition-all"
                  style={{ width: `${engine.loadingProgress * 100}%` }}
                />
              </div>
              <p className="text-center text-xs text-secondary">
                Loading tracks…
              </p>
            </div>
          ) : (
            <>
              <input
                type="range"
                min={0}
                max={Math.max(engine.duration, 0.01)}
                step={0.01}
                value={engine.currentTime}
                onChange={(e) => engine.seek(Number(e.target.value))}
                disabled={engine.duration <= 0}
                className="w-full accent-accent"
                aria-label="Playhead"
              />
              <div className="mt-1 flex justify-between font-mono text-xs text-secondary">
                <span>{formatStemTime(engine.currentTime)}</span>
                <span>{formatStemTime(engine.duration)}</span>
              </div>
              <div className="mt-4 flex items-center justify-center gap-6">
                <button
                  type="button"
                  onClick={() => engine.seek(0)}
                  className="rounded-full p-2 text-primary transition hover:bg-surfaceMuted"
                  aria-label="Rewind to start"
                >
                  <Rewind className="h-5 w-5" />
                </button>
                <button
                  type="button"
                  onClick={() =>
                    engine.isPlaying ? engine.pause() : engine.play()
                  }
                  className="flex h-14 w-14 items-center justify-center rounded-full bg-accent text-primary shadow-card transition hover:scale-105"
                  aria-label={engine.isPlaying ? "Pause" : "Play"}
                >
                  {engine.isPlaying ? (
                    <Pause className="h-7 w-7" fill="currentColor" />
                  ) : (
                    <Play className="h-7 w-7 pl-0.5" fill="currentColor" />
                  )}
                </button>
                <button
                  type="button"
                  onClick={() => engine.stop()}
                  className="rounded-full p-2 text-primary transition hover:bg-surfaceMuted"
                  aria-label="Stop"
                >
                  <Square className="h-5 w-5" fill="currentColor" />
                </button>
              </div>
            </>
          )}
          {engine.loadError && (
            <p className="mt-4 rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-xs text-danger">
              {engine.loadError}
            </p>
          )}
        </div>
      )}

      {/* Stem list */}
      {stems.length === 0 ? (
        <div className="flex flex-col items-center gap-3 rounded-3xl border border-dashed border-divider bg-surface/60 p-10 text-center">
          <Waves className="h-10 w-10 text-accent/60" />
          <p className="font-display text-lg font-semibold text-primary">
            No tracks yet
          </p>
          <p className="max-w-sm text-sm text-secondary">
            Add a streaming link to any stem so your band can play along with
            mute, solo, and per-track volume.
          </p>
          <div className="flex flex-wrap justify-center gap-2">
            <Button variant="accent" onClick={() => setShowAdd(true)}>
              <Plus className="h-4 w-4" /> Add track
            </Button>
            <Button variant="outline" onClick={() => setShowFolderUpload(true)}>
              <FolderOpen className="h-4 w-4" /> Upload folder
            </Button>
          </div>
        </div>
      ) : (
        <div className="space-y-2">
          {stems.map((stem) => (
            <StemRow
              key={stem.id}
              stem={stem}
              engine={engine}
              onEdit={() => setEditing(stem)}
              onDelete={() => {
                if (confirm(`Remove "${stem.label}" from this song?`)) {
                  deleteMutation.mutate(stem.id);
                }
              }}
            />
          ))}
        </div>
      )}

      {/* Add / upload buttons (shown when there's already at least one stem) */}
      {stems.length > 0 && (
        <div className="flex gap-2">
          <Button
            variant="outline"
            fullWidth
            onClick={() => setShowAdd(true)}
          >
            <Plus className="h-4 w-4" /> Add track
          </Button>
          <Button
            variant="outline"
            fullWidth
            onClick={() => setShowFolderUpload(true)}
          >
            <FolderOpen className="h-4 w-4" /> Upload folder
          </Button>
        </div>
      )}

      {deleteMutation.error && (
        <p className="rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
          {errorMessage(deleteMutation.error)}
        </p>
      )}

      <AddStemModal
        open={showAdd}
        onClose={() => setShowAdd(false)}
        onSubmit={(input) => addMutation.mutateAsync(input)}
        loading={addMutation.isPending}
        error={addMutation.error ? errorMessage(addMutation.error) : null}
      />

      <AddStemModal
        open={editing != null}
        onClose={() => setEditing(null)}
        existing={editing}
        onSubmit={(input) => {
          if (!editing) return Promise.resolve();
          const patch: { kind?: StemKind; label?: string; url?: string } = {};
          if (input.kind !== editing.kind) patch.kind = input.kind;
          if (input.label !== editing.label) patch.label = input.label;
          if (input.url !== editing.url) patch.url = input.url;
          if (Object.keys(patch).length === 0) {
            setEditing(null);
            return Promise.resolve();
          }
          return updateMutation.mutateAsync({ stemId: editing.id, patch });
        }}
        loading={updateMutation.isPending}
        error={updateMutation.error ? errorMessage(updateMutation.error) : null}
      />

      <FolderUploadModal
        open={showFolderUpload}
        onClose={() => setShowFolderUpload(false)}
        songId={songId}
        onComplete={() => {
          invalidateStems();
          setShowFolderUpload(false);
        }}
      />
    </div>
  );
}

// ---------- Stem row ----------

interface StemRowProps {
  stem: SongStem;
  engine: ReturnType<typeof useMultitrackEngine>;
  onEdit: () => void;
  onDelete: () => void;
}

function StemRow({ stem, engine, onEdit, onDelete }: StemRowProps) {
  const Icon = stemKindIcon(stem.kind);
  const isMuted = engine.muted.has(stem.id);
  const isSoloed = engine.soloed.has(stem.id);
  const volume = engine.getVolume(stem.id);

  return (
    <div
      className={`flex flex-col gap-3 rounded-2xl border bg-surface p-4 shadow-card transition ${
        isSoloed ? "border-accent" : "border-divider"
      }`}
    >
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-accentMuted text-accent">
          <Icon className="h-5 w-5" />
        </div>

        <div className="min-w-0 flex-1">
          <p className="truncate font-display text-base font-semibold text-primary">
            {stem.label}
          </p>
          <p className="text-xs text-secondary">{stemKindLabel(stem.kind)}</p>
        </div>

        <button
          type="button"
          onClick={() => engine.toggleMute(stem.id)}
          className={`h-9 w-9 rounded-lg border text-xs font-bold transition ${
            isMuted
              ? "border-danger/40 bg-danger/10 text-danger"
              : "border-divider bg-surfaceMuted text-primary hover:border-primary/40"
          }`}
          aria-label="Mute"
          aria-pressed={isMuted}
        >
          M
        </button>
        <button
          type="button"
          onClick={() => engine.toggleSolo(stem.id)}
          className={`h-9 w-9 rounded-lg border text-xs font-bold transition ${
            isSoloed
              ? "border-accent bg-accent/15 text-accent"
              : "border-divider bg-surfaceMuted text-primary hover:border-primary/40"
          }`}
          aria-label="Solo"
          aria-pressed={isSoloed}
        >
          S
        </button>

        <div className="flex items-center gap-1">
          <button
            type="button"
            onClick={onEdit}
            className="rounded-md p-1.5 text-secondary transition hover:bg-surfaceMuted hover:text-primary"
            aria-label="Edit track"
          >
            <Pencil className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={onDelete}
            className="rounded-md p-1.5 text-secondary transition hover:bg-danger/10 hover:text-danger"
            aria-label="Delete track"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      </div>

      <input
        type="range"
        min={0}
        max={1}
        step={0.01}
        value={volume}
        onChange={(e) => engine.setVolume(stem.id, Number(e.target.value))}
        className="w-full accent-accent"
        aria-label={`${stem.label} volume`}
      />
    </div>
  );
}
