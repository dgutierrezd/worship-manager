"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  ArrowLeft,
  Check,
  ChevronDown,
  ChevronUp,
  Minus,
  Music2,
  Pencil,
  Plus,
  Trash2,
  X,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { RSVPStatus } from "@/types";
import { useBandStore } from "@/lib/stores/band-store";
import { setlistsApi } from "@/lib/api/setlists";
import { songsApi } from "@/lib/api/songs";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/ui/empty-state";
import { Modal } from "@/components/ui/modal";
import { SkeletonList } from "@/components/ui/skeleton";
import { EditServiceModal } from "@/components/services/edit-service-modal";
import { AttendanceRoster } from "@/components/attendance-roster";
import {
  errorMessage,
  formatShortDate,
  serviceTypeDisplay,
} from "@/lib/utils";

export default function ServiceDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const band = useBandStore((s) => s.currentBand);
  const bandId = band?.id ?? "";
  const queryClient = useQueryClient();

  const [addOpen, setAddOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);

  const setlistsQuery = useQuery({
    queryKey: ["setlists", bandId],
    queryFn: () => setlistsApi.list(bandId),
    enabled: !!bandId,
  });

  const songsInSetlistQuery = useQuery({
    queryKey: ["setlist-songs", id],
    queryFn: () => setlistsApi.listSongs(id),
  });

  const songsQuery = useQuery({
    queryKey: ["songs", bandId],
    queryFn: () => songsApi.list(bandId),
    enabled: !!bandId,
  });

  const setlist = setlistsQuery.data?.find((s) => s.id === id);

  // Service RSVPs (current user)
  const myRsvpsQuery = useQuery({
    queryKey: ["setlist-rsvps-mine", bandId],
    queryFn: () => setlistsApi.myRsvps(bandId),
    enabled: !!bandId,
  });

  const myRsvpStatus: RSVPStatus | undefined = myRsvpsQuery.data?.find(
    (r) => r.setlist_id === id,
  )?.status;

  const rosterQuery = useQuery({
    queryKey: ["setlist-rsvps", id],
    queryFn: () => setlistsApi.rsvps(id),
  });

  const rsvpMutation = useMutation({
    mutationFn: (status: RSVPStatus) => setlistsApi.rsvp(id, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["setlist-rsvps-mine", bandId] });
      queryClient.invalidateQueries({ queryKey: ["setlist-rsvps", id] });
    },
  });

  const addSongMutation = useMutation({
    mutationFn: (songId: string) =>
      setlistsApi.addSong(id, { song_id: songId }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["setlist-songs", id] });
      setAddOpen(false);
    },
  });

  const removeSongMutation = useMutation({
    mutationFn: (songId: string) => setlistsApi.removeSong(id, songId),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ["setlist-songs", id] }),
  });

  const reorderMutation = useMutation({
    mutationFn: (positions: { id: string; position: number }[]) =>
      setlistsApi.reorder(id, positions),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ["setlist-songs", id] }),
  });

  const moveSong = (idx: number, dir: -1 | 1) => {
    const songs = songsInSetlistQuery.data;
    if (!songs) return;
    const target = idx + dir;
    if (target < 0 || target >= songs.length) return;
    const a = songs[idx];
    const b = songs[target];
    if (!a || !b) return;
    reorderMutation.mutate([
      { id: a.id, position: b.position },
      { id: b.id, position: a.position },
    ]);
  };

  const deleteSetlistMutation = useMutation({
    mutationFn: () => setlistsApi.remove(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["setlists", bandId] });
      router.replace("/services");
    },
  });

  if (setlistsQuery.isLoading) {
    return <SkeletonList count={3} />;
  }
  if (!setlist) {
    return (
      <div>
        <Link href="/services" className="btn-ghost">
          <ArrowLeft className="h-4 w-4" /> Back to services
        </Link>
        <p className="mt-8 text-center text-secondary">Service not found.</p>
      </div>
    );
  }

  const setlistSongIds = new Set(
    (songsInSetlistQuery.data ?? []).map((s) => s.song_id),
  );
  const availableSongs = (songsQuery.data ?? []).filter(
    (s) => !setlistSongIds.has(s.id),
  );

  const handleDelete = () => {
    if (confirm(`Delete "${setlist.name}"? This cannot be undone.`)) {
      deleteSetlistMutation.mutate();
    }
  };

  return (
    <div className="animate-fade-in">
      <Link href="/services" className="btn-ghost mb-6 inline-flex">
        <ArrowLeft className="h-4 w-4" /> Back to services
      </Link>

      <header className="rounded-3xl border border-divider bg-surface p-8 shadow-card">
        <div className="flex items-start justify-between gap-4">
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <Badge variant="accent">
                {serviceTypeDisplay(setlist.service_type)}
              </Badge>
              {setlist.date && (
                <span className="text-sm font-semibold text-secondary">
                  {formatShortDate(setlist.date)}
                </span>
              )}
            </div>
            <h1 className="mt-3 font-display text-4xl font-semibold text-primary">
              {setlist.name}
            </h1>
            {setlist.theme && (
              <p className="mt-2 text-base text-secondary">{setlist.theme}</p>
            )}
            {setlist.location && (
              <p className="mt-1 text-sm text-secondary">
                📍 {setlist.location}
              </p>
            )}
          </div>
          <div className="flex flex-col gap-2 md:items-end">
            <Button variant="outline" onClick={() => setEditOpen(true)}>
              <Pencil className="h-4 w-4" /> Edit
            </Button>
            <Button
              variant="danger"
              onClick={handleDelete}
              loading={deleteSetlistMutation.isPending}
            >
              <Trash2 className="h-4 w-4" /> Delete
            </Button>
          </div>
        </div>
        {setlist.notes && (
          <p className="mt-6 whitespace-pre-wrap rounded-2xl bg-surfaceMuted p-4 text-sm text-primary">
            {setlist.notes}
          </p>
        )}

        {/* RSVP — same UX as rehearsals */}
        <div className="mt-6 border-t border-divider pt-4">
          <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-secondary">
            Will you attend?
          </p>
          <div className="flex flex-wrap gap-2">
            <RsvpPill
              label="Going"
              icon={<Check className="h-4 w-4" />}
              tone="going"
              selected={myRsvpStatus === "going"}
              onClick={() => rsvpMutation.mutate("going")}
            />
            <RsvpPill
              label="Maybe"
              icon={<Minus className="h-4 w-4" />}
              tone="maybe"
              selected={myRsvpStatus === "maybe"}
              onClick={() => rsvpMutation.mutate("maybe")}
            />
            <RsvpPill
              label="Not going"
              icon={<X className="h-4 w-4" />}
              tone="no"
              selected={myRsvpStatus === "not_going"}
              onClick={() => rsvpMutation.mutate("not_going")}
            />
          </div>
        </div>
      </header>

      <section className="mt-8">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="section-title">Setlist</h2>
          <Button variant="accent" size="sm" onClick={() => setAddOpen(true)}>
            <Plus className="h-4 w-4" /> Add song
          </Button>
        </div>

        {songsInSetlistQuery.isLoading ? (
          <SkeletonList count={3} />
        ) : !songsInSetlistQuery.data ||
          songsInSetlistQuery.data.length === 0 ? (
          <EmptyState
            icon={Music2}
            title="No songs in this setlist yet"
            description="Add songs from your library to build out this service."
            action={
              <Button variant="accent" onClick={() => setAddOpen(true)}>
                <Plus className="h-4 w-4" /> Add song
              </Button>
            }
          />
        ) : (
          <ol className="space-y-2">
            {songsInSetlistQuery.data.map((entry, index) => (
              <li
                key={entry.id}
                className="flex items-center justify-between gap-4 rounded-2xl border border-divider bg-surface p-4 shadow-card"
              >
                <div className="flex min-w-0 items-center gap-4">
                  <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-accent/15 font-display text-sm font-semibold text-accent">
                    {index + 1}
                  </span>
                  <div className="min-w-0">
                    <p className="truncate font-semibold text-primary">
                      {entry.songs?.title ?? "Unknown song"}
                    </p>
                    {entry.songs?.artist && (
                      <p className="truncate text-xs text-secondary">
                        {entry.songs.artist}
                      </p>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {(entry.key_override || entry.songs?.default_key) && (
                    <Badge variant="accent">
                      {entry.key_override ?? entry.songs?.default_key}
                    </Badge>
                  )}
                  <div className="flex items-center">
                    <button
                      type="button"
                      aria-label="Move up"
                      disabled={index === 0 || reorderMutation.isPending}
                      onClick={() => moveSong(index, -1)}
                      className="rounded-full p-1.5 text-secondary transition hover:bg-surfaceMuted hover:text-primary disabled:cursor-not-allowed disabled:opacity-30"
                    >
                      <ChevronUp className="h-4 w-4" />
                    </button>
                    <button
                      type="button"
                      aria-label="Move down"
                      disabled={
                        !songsInSetlistQuery.data ||
                        index === songsInSetlistQuery.data.length - 1 ||
                        reorderMutation.isPending
                      }
                      onClick={() => moveSong(index, 1)}
                      className="rounded-full p-1.5 text-secondary transition hover:bg-surfaceMuted hover:text-primary disabled:cursor-not-allowed disabled:opacity-30"
                    >
                      <ChevronDown className="h-4 w-4" />
                    </button>
                  </div>
                  <button
                    type="button"
                    aria-label="Remove song"
                    onClick={() =>
                      entry.song_id && removeSongMutation.mutate(entry.song_id)
                    }
                    className="rounded-full p-1.5 text-secondary transition hover:bg-danger/10 hover:text-danger"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </li>
            ))}
          </ol>
        )}
      </section>

      <section className="mt-8">
        <AttendanceRoster
          rsvps={rosterQuery.data}
          isLoading={rosterQuery.isLoading}
        />
      </section>

      <AddOrCreateSongModal
        open={addOpen}
        onClose={() => setAddOpen(false)}
        bandId={bandId}
        availableSongs={availableSongs}
        onPick={(songId) => addSongMutation.mutate(songId)}
        addInFlight={addSongMutation.isPending}
        addError={
          addSongMutation.error ? errorMessage(addSongMutation.error) : null
        }
      />

      <EditServiceModal
        open={editOpen}
        onClose={() => setEditOpen(false)}
        setlist={setlist}
        bandId={bandId}
      />
    </div>
  );
}

// MARK: - Add or Create Song Modal
//
// Lets the user pick from existing songs OR create a brand-new song
// (title + optional artist) inline and add it to this setlist in one step.

interface AddOrCreateSongModalProps {
  open: boolean;
  onClose: () => void;
  bandId: string;
  availableSongs: import("@/types").Song[];
  onPick: (songId: string) => void;
  addInFlight: boolean;
  addError: string | null;
}

function AddOrCreateSongModal({
  open,
  onClose,
  bandId,
  availableSongs,
  onPick,
  addInFlight,
  addError,
}: AddOrCreateSongModalProps) {
  const params = useParams<{ id: string }>();
  const setlistId = params.id;
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [inlineArtist, setInlineArtist] = useState("");

  const trimmed = search.trim();
  const filtered = trimmed
    ? availableSongs.filter(
        (s) =>
          s.title.toLowerCase().includes(trimmed.toLowerCase()) ||
          s.artist?.toLowerCase().includes(trimmed.toLowerCase()),
      )
    : availableSongs;

  // Show inline create whenever there's a typed query and no exact title match
  const showInlineCreate =
    trimmed.length > 0 &&
    !availableSongs.some(
      (s) => s.title.toLowerCase() === trimmed.toLowerCase(),
    );

  const createAndAddMutation = useMutation({
    mutationFn: async () => {
      const created = await songsApi.create(bandId, {
        title: trimmed,
        artist: inlineArtist.trim() || null,
      });
      await setlistsApi.addSong(setlistId, { song_id: created.id });
      return created;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["songs", bandId] });
      queryClient.invalidateQueries({ queryKey: ["setlist-songs", setlistId] });
      setSearch("");
      setInlineArtist("");
      onClose();
    },
  });

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Add a song"
      description="Pick from your library, or create a new song right here."
      size="md"
    >
      <div className="space-y-4">
        <input
          type="search"
          placeholder="Search or type a new song title…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="input"
          autoFocus
        />

        {showInlineCreate && (
          <div className="rounded-2xl border border-accent/30 bg-accent/5 p-4">
            <p className="text-sm font-semibold text-primary">
              Create new song
            </p>
            <p className="mt-1 text-xs text-secondary">
              <span className="font-semibold text-primary">
                &quot;{trimmed}&quot;
              </span>{" "}
              isn&apos;t in your library yet — add it now.
            </p>
            <input
              type="text"
              placeholder="Artist (optional)"
              value={inlineArtist}
              onChange={(e) => setInlineArtist(e.target.value)}
              className="input mt-3"
            />
            {createAndAddMutation.error && (
              <p className="mt-2 text-xs text-danger">
                {errorMessage(createAndAddMutation.error)}
              </p>
            )}
            <Button
              variant="accent"
              className="mt-3 w-full"
              onClick={() => createAndAddMutation.mutate()}
              loading={createAndAddMutation.isPending}
            >
              <Plus className="h-4 w-4" /> Create &amp; add to setlist
            </Button>
          </div>
        )}

        {addError && (
          <p className="rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
            {addError}
          </p>
        )}

        {filtered.length === 0 ? (
          !showInlineCreate && (
            <p className="text-sm text-secondary">
              {availableSongs.length === 0
                ? "All songs in your library are already in this setlist."
                : "No songs match your search."}
            </p>
          )
        ) : (
          <div className="space-y-2">
            <p className="text-xs font-semibold uppercase tracking-wide text-secondary">
              Your library
            </p>
            {filtered.map((song) => (
              <button
                key={song.id}
                type="button"
                onClick={() => onPick(song.id)}
                disabled={addInFlight}
                className="flex w-full items-center justify-between rounded-xl border border-divider bg-surface p-4 text-left transition hover:border-accent/40"
              >
                <div className="min-w-0">
                  <p className="truncate font-semibold text-primary">
                    {song.title}
                  </p>
                  {song.artist && (
                    <p className="truncate text-xs text-secondary">
                      {song.artist}
                    </p>
                  )}
                </div>
                {song.default_key && (
                  <Badge variant="accent">{song.default_key}</Badge>
                )}
              </button>
            ))}
          </div>
        )}
      </div>
    </Modal>
  );
}

// MARK: - RSVP Pill (service)

function RsvpPill({
  label,
  icon,
  tone,
  selected,
  onClick,
}: {
  label: string;
  icon: React.ReactNode;
  tone: "going" | "maybe" | "no";
  selected: boolean;
  onClick: () => void;
}) {
  // Tailwind classes are not dynamically composable, so we map here.
  const map = {
    going: {
      bg: selected ? "bg-going text-white" : "bg-going/10 text-going",
      border: selected ? "border-going" : "border-going/30",
    },
    maybe: {
      bg: selected ? "bg-maybe text-white" : "bg-maybe/10 text-maybe",
      border: selected ? "border-maybe" : "border-maybe/30",
    },
    no: {
      bg: selected ? "bg-no text-white" : "bg-no/10 text-no",
      border: selected ? "border-no" : "border-no/30",
    },
  } as const;
  const c = map[tone];

  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full border px-4 py-2 text-sm font-semibold transition active:scale-95",
        c.bg,
        c.border,
        selected && "shadow-card",
      )}
    >
      {icon}
      {label}
    </button>
  );
}
