"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input, Textarea } from "@/components/ui/input";
import { Modal } from "@/components/ui/modal";
import { songsApi, type SongInput } from "@/lib/api/songs";
import { errorMessage } from "@/lib/utils";
import type { Song } from "@/types";

const MUSICAL_KEYS = [
  "", "C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B",
] as const;

interface EditSongModalProps {
  open: boolean;
  onClose: () => void;
  song: Song;
  bandId: string;
}

/**
 * Full song edit — parity with iOS `EditSongView`. Every optional field can
 * be toggled on/off via empty strings; null is sent for cleared values.
 */
export function EditSongModal({
  open,
  onClose,
  song,
  bandId,
}: EditSongModalProps) {
  const queryClient = useQueryClient();

  const [form, setForm] = useState({
    title: song.title,
    artist: song.artist ?? "",
    default_key: song.default_key ?? "",
    tempo_bpm: song.tempo_bpm?.toString() ?? "",
    duration_min: song.duration_sec
      ? Math.floor(song.duration_sec / 60).toString()
      : "",
    duration_sec: song.duration_sec ? (song.duration_sec % 60).toString() : "",
    theme: song.theme ?? "",
    tags: song.tags?.join(", ") ?? "",
    youtube_url: song.youtube_url ?? "",
    spotify_url: song.spotify_url ?? "",
    notes: song.notes ?? "",
    lyrics: song.lyrics ?? "",
  });

  const mutation = useMutation({
    mutationFn: (input: Partial<SongInput>) =>
      songsApi.update(bandId, song.id, input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["songs", bandId] });
      onClose();
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const minutes = parseInt(form.duration_min) || 0;
    const seconds = parseInt(form.duration_sec) || 0;
    const totalSec = minutes * 60 + seconds;

    mutation.mutate({
      title: form.title.trim(),
      artist: form.artist.trim() || null,
      default_key: form.default_key || null,
      tempo_bpm: form.tempo_bpm ? Number(form.tempo_bpm) : null,
      duration_sec: totalSec > 0 ? totalSec : null,
      theme: form.theme.trim() || null,
      tags: form.tags.trim()
        ? form.tags.split(",").map((t) => t.trim()).filter(Boolean)
        : null,
      youtube_url: form.youtube_url.trim() || null,
      spotify_url: form.spotify_url.trim() || null,
      notes: form.notes.trim() || null,
      lyrics: form.lyrics.trim() || null,
    });
  };

  return (
    <Modal open={open} onClose={onClose} title="Edit song" size="lg">
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          name="title"
          label="Title"
          required
          value={form.title}
          onChange={(e) => setForm({ ...form, title: e.target.value })}
        />
        <Input
          name="artist"
          label="Artist"
          value={form.artist}
          onChange={(e) => setForm({ ...form, artist: e.target.value })}
        />

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label htmlFor="default_key" className="label">
              Default key
            </label>
            <select
              id="default_key"
              value={form.default_key}
              onChange={(e) => setForm({ ...form, default_key: e.target.value })}
              className="input"
            >
              {MUSICAL_KEYS.map((k) => (
                <option key={k || "none"} value={k}>
                  {k || "None"}
                </option>
              ))}
            </select>
          </div>
          <Input
            name="tempo_bpm"
            label="Tempo (BPM)"
            type="number"
            min={20}
            max={300}
            value={form.tempo_bpm}
            onChange={(e) => setForm({ ...form, tempo_bpm: e.target.value })}
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <Input
            name="duration_min"
            label="Duration (min)"
            type="number"
            min={0}
            max={30}
            value={form.duration_min}
            onChange={(e) => setForm({ ...form, duration_min: e.target.value })}
          />
          <Input
            name="duration_sec"
            label="Duration (sec)"
            type="number"
            min={0}
            max={59}
            value={form.duration_sec}
            onChange={(e) => setForm({ ...form, duration_sec: e.target.value })}
          />
        </div>

        <Input
          name="theme"
          label="Theme"
          placeholder="Grace, Praise, Hope…"
          value={form.theme}
          onChange={(e) => setForm({ ...form, theme: e.target.value })}
        />
        <Input
          name="tags"
          label="Tags"
          placeholder="comma, separated, tags"
          value={form.tags}
          onChange={(e) => setForm({ ...form, tags: e.target.value })}
        />

        <Input
          name="youtube_url"
          label="YouTube URL"
          type="url"
          value={form.youtube_url}
          onChange={(e) => setForm({ ...form, youtube_url: e.target.value })}
        />
        <Input
          name="spotify_url"
          label="Spotify URL"
          type="url"
          value={form.spotify_url}
          onChange={(e) => setForm({ ...form, spotify_url: e.target.value })}
        />

        <Textarea
          name="notes"
          label="Notes"
          rows={3}
          value={form.notes}
          onChange={(e) => setForm({ ...form, notes: e.target.value })}
        />
        <Textarea
          name="lyrics"
          label="Lyrics"
          rows={6}
          value={form.lyrics}
          onChange={(e) => setForm({ ...form, lyrics: e.target.value })}
        />

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
            type="submit"
            variant="accent"
            loading={mutation.isPending}
            disabled={!form.title.trim()}
          >
            Save changes
          </Button>
        </div>
      </form>
    </Modal>
  );
}
