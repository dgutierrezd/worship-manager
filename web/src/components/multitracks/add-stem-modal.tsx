"use client";

import { useEffect, useState } from "react";
import { ClipboardPaste, HelpCircle } from "lucide-react";
import type { SongStem, StemKind } from "@/types";
import { Modal } from "@/components/ui/modal";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { STEM_KINDS, stemKindLabel } from "./stem-meta";

interface AddStemModalProps {
  open: boolean;
  onClose: () => void;
  /** Existing stem to edit, or `null` / `undefined` for create mode. */
  existing?: SongStem | null;
  onSubmit: (input: {
    kind: StemKind;
    label: string;
    url: string;
  }) => Promise<unknown> | void;
  loading?: boolean;
  error?: string | null;
}

export function AddStemModal({
  open,
  onClose,
  existing,
  onSubmit,
  loading = false,
  error,
}: AddStemModalProps) {
  const [kind, setKind] = useState<StemKind>("drums");
  const [label, setLabel] = useState("");
  const [url, setUrl] = useState("");
  const [showHelp, setShowHelp] = useState(false);

  // Prefill when opening in edit mode
  useEffect(() => {
    if (open) {
      setKind(existing?.kind ?? "drums");
      setLabel(existing?.label ?? "");
      setUrl(existing?.url ?? "");
      setShowHelp(false);
    }
  }, [open, existing]);

  const canSave =
    label.trim().length > 0 && url.trim().length > 0 && isValidUrl(url.trim());

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!canSave) return;
    await onSubmit({ kind, label: label.trim(), url: url.trim() });
  };

  const handlePaste = async () => {
    try {
      const text = await navigator.clipboard.readText();
      if (text) setUrl(text);
    } catch {
      // User denied clipboard access — no-op
    }
  };

  return (
    <>
      <Modal
        open={open}
        onClose={onClose}
        title={existing ? "Edit track" : "Add track"}
        description="Worship Manager doesn't host your audio. Paste a direct streaming link."
        size="md"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="stem-kind" className="label">
              Instrument
            </label>
            <select
              id="stem-kind"
              value={kind}
              onChange={(e) => setKind(e.target.value as StemKind)}
              className="input"
            >
              {STEM_KINDS.map((k) => (
                <option key={k} value={k}>
                  {stemKindLabel(k)}
                </option>
              ))}
            </select>
          </div>

          <Input
            name="label"
            label="Label"
            placeholder="e.g. Electric Gtr L"
            value={label}
            onChange={(e) => setLabel(e.target.value)}
            required
          />

          <div>
            <label htmlFor="stem-url" className="label">
              Streaming URL
            </label>
            <div className="flex gap-2">
              <input
                id="stem-url"
                type="url"
                inputMode="url"
                autoComplete="off"
                placeholder="https://..."
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                className="input font-mono"
              />
              <button
                type="button"
                onClick={handlePaste}
                className="inline-flex h-10 shrink-0 items-center gap-1.5 rounded-full border border-divider bg-surface px-3 text-xs font-medium text-secondary transition hover:border-accent/40 hover:text-primary"
                aria-label="Paste from clipboard"
              >
                <ClipboardPaste className="h-3.5 w-3.5" /> Paste
              </button>
            </div>
            <p className="mt-2 text-xs text-secondary">
              Dropbox, Google Drive, OneDrive, or any direct web link.{" "}
              <button
                type="button"
                onClick={() => setShowHelp(true)}
                className="inline-flex items-center gap-1 text-accent hover:underline"
              >
                <HelpCircle className="h-3 w-3" />
                How to get a direct link
              </button>
            </p>
          </div>

          {error && (
            <p className="rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
              {error}
            </p>
          )}

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancel
            </Button>
            <Button
              type="submit"
              variant="accent"
              loading={loading}
              disabled={!canSave}
            >
              {existing ? "Save changes" : "Add track"}
            </Button>
          </div>
        </form>
      </Modal>

      <Modal
        open={showHelp}
        onClose={() => setShowHelp(false)}
        title="How to get a direct streaming link"
        description="Worship Manager doesn't host your audio. Upload your stems to any cloud you already use, then paste a direct link here."
        size="md"
      >
        <div className="space-y-4">
          <HelpBlock
            title="Dropbox"
            steps={[
              "Right-click the file → Copy link",
              "Paste here — we'll automatically convert ?dl=0 to ?raw=1 so it streams directly.",
            ]}
          />
          <HelpBlock
            title="Google Drive"
            steps={[
              "Share the file: Anyone with the link",
              "Copy the file ID from the share URL",
              "Paste this format: https://drive.google.com/uc?export=download&id=FILE_ID",
              "Note: Google Drive may block CORS in the browser. If playback fails, use Dropbox instead.",
            ]}
          />
          <HelpBlock
            title="OneDrive"
            steps={[
              "Right-click → Share → Copy link",
              "Paste here — we append ?download=1 automatically.",
            ]}
          />
          <HelpBlock
            title="Any direct web host"
            steps={[
              "Cloudinary, Bunny CDN, S3, your own server…",
              "If the URL ends in .mp3, .m4a, .wav, .aac, or .ogg, just paste it.",
              "The host must send CORS headers (Access-Control-Allow-Origin) for the browser to stream it.",
            ]}
          />
          <p className="text-xs text-secondary">
            iCloud public links return a webpage, not the file, so they don't
            work. Use Dropbox or Drive instead.
          </p>
          <div className="flex justify-end pt-2">
            <Button variant="ghost" onClick={() => setShowHelp(false)}>
              Close
            </Button>
          </div>
        </div>
      </Modal>
    </>
  );
}

function HelpBlock({ title, steps }: { title: string; steps: string[] }) {
  return (
    <div className="rounded-2xl border border-divider bg-surfaceMuted/50 p-4">
      <p className="font-display text-sm font-semibold text-primary">{title}</p>
      <ol className="mt-2 space-y-1 text-xs text-secondary">
        {steps.map((step, i) => (
          <li key={i} className="flex gap-2">
            <span className="text-accent">{i + 1}.</span>
            <span>{step}</span>
          </li>
        ))}
      </ol>
    </div>
  );
}

function isValidUrl(value: string): boolean {
  try {
    // eslint-disable-next-line no-new
    new URL(value);
    return true;
  } catch {
    return false;
  }
}
