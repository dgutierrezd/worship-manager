"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ListPlus, Music2, Plus, Search } from "lucide-react";
import { useBandStore } from "@/lib/stores/band-store";
import { songsApi, type SongInput } from "@/lib/api/songs";
import { PageHeader } from "@/components/ui/page-header";
import { Button } from "@/components/ui/button";
import { Input, Textarea } from "@/components/ui/input";
import { Modal } from "@/components/ui/modal";
import { EmptyState } from "@/components/ui/empty-state";
import { SkeletonList } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { BulkAddModal } from "@/components/songs/bulk-add-modal";
import { errorMessage, formatDuration } from "@/lib/utils";

const MUSICAL_KEYS = [
  "C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B",
] as const;

export default function SongsPage() {
  const band = useBandStore((s) => s.currentBand);
  const bandId = band?.id ?? "";
  const queryClient = useQueryClient();

  const [search, setSearch] = useState("");
  const [showAdd, setShowAdd] = useState(false);
  const [showBulk, setShowBulk] = useState(false);

  const query = useQuery({
    queryKey: ["songs", bandId],
    queryFn: () => songsApi.list(bandId),
    enabled: !!bandId,
  });

  const filtered = useMemo(() => {
    const list = query.data ?? [];
    if (!search.trim()) return list;
    const needle = search.toLowerCase();
    return list.filter(
      (s) =>
        s.title.toLowerCase().includes(needle) ||
        s.artist?.toLowerCase().includes(needle),
    );
  }, [query.data, search]);

  const addMutation = useMutation({
    mutationFn: (input: SongInput) => songsApi.create(bandId, input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["songs", bandId] });
      setShowAdd(false);
    },
  });

  if (!band) return null;

  return (
    <div className="animate-fade-in">
      <PageHeader
        eyebrow="Library"
        title="Songs"
        description="Every song your team plays — chords, keys, tempo, and notes."
        actions={
          <>
            <Button variant="outline" onClick={() => setShowBulk(true)}>
              <ListPlus className="h-4 w-4" /> Add many
            </Button>
            <Button variant="accent" onClick={() => setShowAdd(true)}>
              <Plus className="h-4 w-4" /> Add song
            </Button>
          </>
        }
      />

      <div className="mb-6 flex items-center gap-3">
        <div className="relative flex-1">
          <Search className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-secondary" />
          <input
            type="search"
            placeholder="Search songs or artists..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input pl-11"
          />
        </div>
      </div>

      {query.isLoading ? (
        <SkeletonList count={6} />
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={Music2}
          title={search ? "No songs found" : "No songs yet"}
          description={
            search
              ? "Try a different search term."
              : "Add your first song to the library."
          }
          action={
            !search ? (
              <Button variant="accent" onClick={() => setShowAdd(true)}>
                <Plus className="h-4 w-4" /> Add song
              </Button>
            ) : undefined
          }
        />
      ) : (
        <div className="grid gap-3 md:grid-cols-2">
          {filtered.map((song) => (
            <Link
              key={song.id}
              href={`/songs/${song.id}`}
              className="group flex items-center justify-between gap-4 rounded-2xl border border-divider bg-surface p-5 shadow-card transition hover:-translate-y-0.5 hover:border-accent/40"
            >
              <div className="min-w-0">
                <p className="truncate font-display text-lg font-semibold text-primary">
                  {song.title}
                </p>
                {song.artist && (
                  <p className="truncate text-sm text-secondary">
                    {song.artist}
                  </p>
                )}
                <div className="mt-2 flex flex-wrap items-center gap-2">
                  {song.default_key && (
                    <Badge variant="accent">Key {song.default_key}</Badge>
                  )}
                  {song.tempo_bpm && (
                    <Badge variant="muted">{song.tempo_bpm} BPM</Badge>
                  )}
                  {formatDuration(song.duration_sec) && (
                    <Badge variant="muted">
                      {formatDuration(song.duration_sec)}
                    </Badge>
                  )}
                </div>
              </div>
              <Music2 className="h-5 w-5 text-secondary transition group-hover:text-accent" />
            </Link>
          ))}
        </div>
      )}

      <AddSongModal
        open={showAdd}
        onClose={() => setShowAdd(false)}
        onSubmit={(data) => addMutation.mutate(data)}
        loading={addMutation.isPending}
        error={addMutation.error ? errorMessage(addMutation.error) : null}
      />

      <BulkAddModal
        open={showBulk}
        onClose={() => setShowBulk(false)}
        bandId={bandId}
      />
    </div>
  );
}

interface AddSongModalProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (input: SongInput) => void;
  loading: boolean;
  error: string | null;
}

function AddSongModal({
  open,
  onClose,
  onSubmit,
  loading,
  error,
}: AddSongModalProps) {
  const [form, setForm] = useState({
    title: "",
    artist: "",
    default_key: "",
    tempo_bpm: "",
    notes: "",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({
      title: form.title.trim(),
      artist: form.artist.trim() || null,
      default_key: form.default_key || null,
      tempo_bpm: form.tempo_bpm ? Number(form.tempo_bpm) : null,
      notes: form.notes.trim() || null,
    });
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Add song"
      description="Create a new entry in your band's song library."
      size="md"
    >
      <form id="add-song-form" onSubmit={handleSubmit} className="space-y-4">
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
              <option value="">—</option>
              {MUSICAL_KEYS.map((k) => (
                <option key={k} value={k}>
                  {k}
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
        <Textarea
          name="notes"
          label="Notes"
          value={form.notes}
          onChange={(e) => setForm({ ...form, notes: e.target.value })}
        />
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
            disabled={!form.title.trim()}
          >
            Add song
          </Button>
        </div>
      </form>
    </Modal>
  );
}
