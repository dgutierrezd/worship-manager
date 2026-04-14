"use client";

import { useCallback, useRef, useState } from "react";
import {
  CheckCircle2,
  FolderOpen,
  Loader2,
  Music,
  Trash2,
  Upload,
  XCircle,
} from "lucide-react";
import type { StemKind } from "@/types";
import { Modal } from "@/components/ui/modal";
import { Button } from "@/components/ui/button";
import { songsApi } from "@/lib/api/songs";
import { errorMessage } from "@/lib/utils";
import { STEM_KINDS, guessKindFromFilename, labelFromFilename, stemKindLabel } from "./stem-meta";

// ── Types ──────────────────────────────────────────────────────────────────────

interface FileEntry {
  /** Stable client-side id for React keys */
  id: string;
  file: File;
  label: string;
  kind: StemKind;
}

type UploadStatus = "idle" | "uploading" | "done" | "error";

interface UploadState {
  status: UploadStatus;
  error?: string;
}

const ACCEPTED_AUDIO = ".mp3,.wav,.m4a,.aac,.ogg,.flac,.webm";
const ACCEPTED_TYPES = new Set([
  "audio/mpeg",
  "audio/wav",
  "audio/x-wav",
  "audio/mp4",
  "audio/m4a",
  "audio/aac",
  "audio/ogg",
  "audio/flac",
  "audio/webm",
  "audio/x-flac",
]);
const ACCEPTED_EXT = new Set([
  ".mp3", ".wav", ".m4a", ".aac", ".ogg", ".flac", ".webm",
]);

let idCounter = 0;
function nextId(): string {
  return `fe-${++idCounter}`;
}

function isAudioFile(f: File): boolean {
  if (ACCEPTED_TYPES.has(f.type)) return true;
  const dot = f.name.lastIndexOf(".");
  if (dot === -1) return false;
  return ACCEPTED_EXT.has(f.name.slice(dot).toLowerCase());
}

// ── Component ─────────────────────────────────────────────────────────────────

interface FolderUploadModalProps {
  open: boolean;
  onClose: () => void;
  songId: string;
  /** Called after all stems have been saved so the parent can refresh. */
  onComplete: () => void;
}

export function FolderUploadModal({
  open,
  onClose,
  songId,
  onComplete,
}: FolderUploadModalProps) {
  const folderInputRef = useRef<HTMLInputElement>(null);
  const filesInputRef = useRef<HTMLInputElement>(null);

  const [entries, setEntries] = useState<FileEntry[]>([]);
  const [uploadStates, setUploadStates] = useState<Record<string, UploadState>>({});
  const [isUploading, setIsUploading] = useState(false);
  const [globalError, setGlobalError] = useState<string | null>(null);
  const [isDragging, setIsDragging] = useState(false);

  const allDone =
    entries.length > 0 &&
    entries.every((e) => uploadStates[e.id]?.status === "done");

  // ── Helpers ──────────────────────────────────────────────────────────────────

  function addFiles(files: FileList | File[]) {
    const arr = Array.from(files).filter(isAudioFile);
    if (arr.length === 0) return;

    setEntries((prev) => {
      const existing = new Set(prev.map((e) => e.file.name + e.file.size));
      const fresh: FileEntry[] = arr
        .filter((f) => !existing.has(f.name + f.size))
        .map((f) => ({
          id: nextId(),
          file: f,
          label: labelFromFilename(f.name),
          kind: guessKindFromFilename(f.name),
        }));
      return [...prev, ...fresh];
    });
    setGlobalError(null);
  }

  function removeEntry(id: string) {
    setEntries((prev) => prev.filter((e) => e.id !== id));
    setUploadStates((prev) => {
      const next = { ...prev };
      delete next[id];
      return next;
    });
  }

  function updateLabel(id: string, label: string) {
    setEntries((prev) =>
      prev.map((e) => (e.id === id ? { ...e, label } : e)),
    );
  }

  function updateKind(id: string, kind: StemKind) {
    setEntries((prev) =>
      prev.map((e) => (e.id === id ? { ...e, kind } : e)),
    );
  }

  function setStatus(id: string, state: UploadState) {
    setUploadStates((prev) => ({ ...prev, [id]: state }));
  }

  // ── Drag & drop ──────────────────────────────────────────────────────────────

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    if (!e.currentTarget.contains(e.relatedTarget as Node)) {
      setIsDragging(false);
    }
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);

    const droppedFiles = e.dataTransfer.files;
    if (droppedFiles.length > 0) {
      addFiles(droppedFiles);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ── Upload ───────────────────────────────────────────────────────────────────

  async function handleUpload() {
    if (entries.length === 0 || isUploading) return;
    setIsUploading(true);
    setGlobalError(null);

    // Only upload entries that haven't succeeded yet
    const pending = entries.filter((e) => uploadStates[e.id]?.status !== "done");

    // 1. Get signed upload URLs from our backend
    let uploadData: Awaited<ReturnType<typeof songsApi.getUploadUrls>>;
    try {
      uploadData = await songsApi.getUploadUrls(
        songId,
        pending.map((e) => ({ name: e.file.name, size: e.file.size })),
      );
    } catch (err) {
      setGlobalError(errorMessage(err));
      setIsUploading(false);
      return;
    }

    // 2. Upload each file directly to Supabase Storage + register stem
    for (let i = 0; i < pending.length; i++) {
      const entry = pending[i];
      const slot = uploadData.uploads[i];

      if (!entry) continue;

      if (!slot) {
        setStatus(entry.id, { status: "error", error: "No upload slot returned" });
        continue;
      }

      setStatus(entry.id, { status: "uploading" });

      try {
        // PUT file directly to Supabase Storage signed URL
        const putRes = await fetch(slot.upload_url, {
          method: "PUT",
          headers: { "Content-Type": entry.file.type || "audio/mpeg" },
          body: entry.file,
        });

        if (!putRes.ok) {
          const text = await putRes.text().catch(() => putRes.statusText);
          throw new Error(`Storage upload failed: ${text}`);
        }

        // Register stem in the database with the public URL
        await songsApi.addStem(songId, {
          kind: entry.kind,
          label: entry.label.trim() || labelFromFilename(entry.file.name),
          url: slot.public_url,
        });

        setStatus(entry.id, { status: "done" });
      } catch (err) {
        setStatus(entry.id, {
          status: "error",
          error: errorMessage(err),
        });
      }
    }

    setIsUploading(false);

    // If everything is done, notify parent after a brief pause so user sees the ✓
    const finalStates = { ...uploadStates };
    pending.forEach((e, i) => {
      finalStates[e.id] = uploadStates[e.id] ?? { status: "idle" };
    });

    const successCount = pending.filter(
      (e) => uploadStates[e.id]?.status === "done",
    ).length;
    if (successCount > 0) {
      onComplete();
    }
  }

  // ── Reset on close ───────────────────────────────────────────────────────────

  function handleClose() {
    if (isUploading) return;
    setEntries([]);
    setUploadStates({});
    setGlobalError(null);
    onClose();
  }

  // ── Status counts ────────────────────────────────────────────────────────────

  const doneCount = entries.filter((e) => uploadStates[e.id]?.status === "done").length;
  const errorCount = entries.filter((e) => uploadStates[e.id]?.status === "error").length;

  // ── Render ───────────────────────────────────────────────────────────────────

  return (
    <Modal
      open={open}
      onClose={handleClose}
      title="Upload folder"
      description="Select a folder or audio files — each file becomes a track. Labels and instruments are auto-detected from filenames and can be adjusted before uploading."
      size="lg"
    >
      <div className="space-y-5">
        {/* Drop zone / picker buttons */}
        {!allDone && (
          <div
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
            className={`flex flex-col items-center gap-4 rounded-2xl border-2 border-dashed p-8 text-center transition ${
              isDragging
                ? "border-accent bg-accentMuted/30"
                : "border-divider bg-surfaceMuted/30 hover:border-accent/40"
            }`}
          >
            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-accentMuted text-accent">
              <FolderOpen className="h-7 w-7" />
            </div>
            <div>
              <p className="font-display text-base font-semibold text-primary">
                Drop audio files here
              </p>
              <p className="mt-1 text-sm text-secondary">
                MP3, WAV, M4A, AAC, OGG, FLAC, WEBM
              </p>
            </div>
            <div className="flex flex-wrap justify-center gap-2">
              {/* Folder picker — webkitdirectory lets user choose a whole folder */}
              <Button
                type="button"
                variant="accent"
                size="sm"
                onClick={() => folderInputRef.current?.click()}
                disabled={isUploading}
              >
                <FolderOpen className="h-4 w-4" /> Choose folder
              </Button>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => filesInputRef.current?.click()}
                disabled={isUploading}
              >
                <Music className="h-4 w-4" /> Select files
              </Button>
            </div>

            {/* Hidden folder input */}
            <input
              ref={folderInputRef}
              type="file"
              className="hidden"
              // @ts-expect-error — webkitdirectory is non-standard but universally supported
              webkitdirectory=""
              multiple
              accept={ACCEPTED_AUDIO}
              onChange={(e) => {
                if (e.target.files) addFiles(e.target.files);
                e.target.value = "";
              }}
            />

            {/* Hidden individual-files input */}
            <input
              ref={filesInputRef}
              type="file"
              className="hidden"
              multiple
              accept={ACCEPTED_AUDIO}
              onChange={(e) => {
                if (e.target.files) addFiles(e.target.files);
                e.target.value = "";
              }}
            />
          </div>
        )}

        {/* File list */}
        {entries.length > 0 && (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <p className="text-sm font-semibold text-primary">
                {entries.length} file{entries.length !== 1 ? "s" : ""} queued
                {doneCount > 0 && (
                  <span className="ml-2 text-success">
                    · {doneCount} uploaded
                  </span>
                )}
                {errorCount > 0 && (
                  <span className="ml-2 text-danger">
                    · {errorCount} failed
                  </span>
                )}
              </p>
              {!isUploading && !allDone && (
                <button
                  type="button"
                  onClick={() => {
                    setEntries([]);
                    setUploadStates({});
                  }}
                  className="text-xs text-secondary hover:text-danger transition"
                >
                  Clear all
                </button>
              )}
            </div>

            <div className="max-h-72 overflow-y-auto space-y-2 pr-1">
              {entries.map((entry) => {
                const state = uploadStates[entry.id];
                return (
                  <FileRow
                    key={entry.id}
                    entry={entry}
                    state={state}
                    disabled={isUploading || state?.status === "done"}
                    onLabelChange={(v) => updateLabel(entry.id, v)}
                    onKindChange={(v) => updateKind(entry.id, v)}
                    onRemove={() => removeEntry(entry.id)}
                  />
                );
              })}
            </div>
          </div>
        )}

        {/* Global error */}
        {globalError && (
          <p className="rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
            {globalError}
          </p>
        )}

        {/* All-done banner */}
        {allDone && (
          <div className="flex items-center gap-3 rounded-2xl border border-success/30 bg-success/10 px-4 py-3">
            <CheckCircle2 className="h-5 w-5 shrink-0 text-success" />
            <p className="text-sm font-semibold text-success">
              All tracks uploaded successfully!
            </p>
          </div>
        )}

        {/* Actions */}
        <div className="flex justify-end gap-2 pt-1">
          <Button
            type="button"
            variant="ghost"
            onClick={handleClose}
            disabled={isUploading}
          >
            {allDone ? "Close" : "Cancel"}
          </Button>
          {!allDone && (
            <Button
              type="button"
              variant="accent"
              loading={isUploading}
              disabled={
                entries.length === 0 ||
                isUploading ||
                entries.every((e) => uploadStates[e.id]?.status === "done")
              }
              onClick={handleUpload}
            >
              <Upload className="h-4 w-4" />
              {isUploading
                ? `Uploading…`
                : `Upload ${entries.filter((e) => uploadStates[e.id]?.status !== "done").length || entries.length} track${entries.length !== 1 ? "s" : ""}`}
            </Button>
          )}
        </div>
      </div>
    </Modal>
  );
}

// ── FileRow ───────────────────────────────────────────────────────────────────

interface FileRowProps {
  entry: FileEntry;
  state: UploadState | undefined;
  disabled: boolean;
  onLabelChange: (v: string) => void;
  onKindChange: (v: StemKind) => void;
  onRemove: () => void;
}

function FileRow({
  entry,
  state,
  disabled,
  onLabelChange,
  onKindChange,
  onRemove,
}: FileRowProps) {
  const statusIcon =
    state?.status === "done" ? (
      <CheckCircle2 className="h-5 w-5 shrink-0 text-success" />
    ) : state?.status === "uploading" ? (
      <Loader2 className="h-5 w-5 shrink-0 animate-spin text-accent" />
    ) : state?.status === "error" ? (
      <XCircle className="h-5 w-5 shrink-0 text-danger" />
    ) : null;

  return (
    <div
      className={`rounded-2xl border bg-surface p-3 transition ${
        state?.status === "done"
          ? "border-success/30 bg-success/5"
          : state?.status === "error"
            ? "border-danger/30 bg-danger/5"
            : "border-divider"
      }`}
    >
      <div className="flex items-center gap-2">
        {/* Status icon or remove button */}
        <div className="flex h-8 w-8 shrink-0 items-center justify-center">
          {statusIcon ?? (
            <button
              type="button"
              onClick={onRemove}
              disabled={disabled}
              className="rounded-md p-1 text-secondary transition hover:bg-danger/10 hover:text-danger disabled:opacity-40"
              aria-label="Remove file"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          )}
        </div>

        {/* Filename (read-only, truncated) */}
        <p
          className="min-w-0 flex-1 truncate font-mono text-xs text-secondary"
          title={entry.file.name}
        >
          {entry.file.name}
        </p>

        {/* File size */}
        <span className="shrink-0 text-xs text-secondary">
          {formatBytes(entry.file.size)}
        </span>
      </div>

      {/* Editable label + kind — hidden once done */}
      {state?.status !== "done" && (
        <div className="mt-2 flex gap-2">
          <input
            type="text"
            value={entry.label}
            onChange={(e) => onLabelChange(e.target.value)}
            placeholder="Label"
            disabled={disabled}
            className="input min-w-0 flex-1 text-sm disabled:opacity-60"
            aria-label="Track label"
          />
          <select
            value={entry.kind}
            onChange={(e) => onKindChange(e.target.value as StemKind)}
            disabled={disabled}
            className="input w-28 shrink-0 text-sm disabled:opacity-60"
            aria-label="Instrument"
          >
            {STEM_KINDS.map((k) => (
              <option key={k} value={k}>
                {stemKindLabel(k)}
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Error message */}
      {state?.status === "error" && state.error && (
        <p className="mt-1.5 text-xs text-danger">{state.error}</p>
      )}
    </div>
  );
}

// ── Utils ─────────────────────────────────────────────────────────────────────

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}
