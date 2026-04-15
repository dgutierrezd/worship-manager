"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, ExternalLink, Pencil, Trash2 } from "lucide-react";
import { songsApi } from "@/lib/api/songs";
import { useBandStore } from "@/lib/stores/band-store";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { formatDuration, errorMessage } from "@/lib/utils";
import { MultitracksPanel } from "@/components/multitracks/multitracks-panel";
import { ChordSheetViewer } from "@/components/chords/chord-sheet-viewer";
import { ChordSheetEditor } from "@/components/chords/chord-sheet-editor";
import { EditSongModal } from "@/components/songs/edit-song-modal";

export default function SongDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const band = useBandStore((s) => s.currentBand);
  const bandId = band?.id ?? "";
  const queryClient = useQueryClient();

  const [editMode, setEditMode] = useState(false);
  const [showEdit, setShowEdit] = useState(false);

  const songsQuery = useQuery({
    queryKey: ["songs", bandId],
    queryFn: () => songsApi.list(bandId),
    enabled: !!bandId,
  });

  const song = songsQuery.data?.find((s) => s.id === id);

  const deleteMutation = useMutation({
    mutationFn: () => songsApi.remove(bandId, id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["songs", bandId] });
      router.replace("/songs");
    },
  });

  if (songsQuery.isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-1/3" />
        <Skeleton className="h-4 w-1/2" />
        <Skeleton className="h-32 w-full" />
      </div>
    );
  }

  if (!song) {
    return (
      <div>
        <Link href="/songs" className="btn-ghost">
          <ArrowLeft className="h-4 w-4" /> Back to songs
        </Link>
        <p className="mt-8 text-center text-secondary">Song not found.</p>
      </div>
    );
  }

  const handleDelete = () => {
    if (confirm(`Delete "${song.title}"? This cannot be undone.`)) {
      deleteMutation.mutate();
    }
  };

  return (
    <div className="animate-fade-in">
      <Link href="/songs" className="btn-ghost mb-6 inline-flex">
        <ArrowLeft className="h-4 w-4" /> Back to songs
      </Link>

      <header className="flex flex-col gap-4 rounded-3xl border border-divider bg-surface p-8 shadow-card md:flex-row md:items-start md:justify-between">
        <div className="min-w-0 flex-1">
          <div className="mb-3 flex items-center gap-2">
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
          <h1 className="font-display text-4xl font-semibold text-primary">
            {song.title}
          </h1>
          {song.artist && (
            <p className="mt-2 text-lg text-secondary">{song.artist}</p>
          )}
          {song.tags && song.tags.length > 0 && (
            <div className="mt-3 flex flex-wrap gap-1.5">
              {song.tags.map((tag) => (
                <span
                  key={tag}
                  className="rounded-full border border-divider bg-surfaceMuted px-2.5 py-0.5 text-xs font-medium text-secondary"
                >
                  #{tag}
                </span>
              ))}
            </div>
          )}
          <div className="mt-4 flex flex-wrap gap-2">
            {song.youtube_url && (
              <a
                href={song.youtube_url}
                target="_blank"
                rel="noreferrer"
                className="btn-ghost border border-divider"
              >
                <ExternalLink className="h-4 w-4" /> YouTube
              </a>
            )}
            {song.spotify_url && (
              <a
                href={song.spotify_url}
                target="_blank"
                rel="noreferrer"
                className="btn-ghost border border-divider"
              >
                <ExternalLink className="h-4 w-4" /> Spotify
              </a>
            )}
          </div>
        </div>
        <div className="flex flex-col gap-2 md:items-end">
          <Button variant="outline" onClick={() => setShowEdit(true)}>
            <Pencil className="h-4 w-4" /> Edit
          </Button>
          <Button
            variant="danger"
            onClick={handleDelete}
            loading={deleteMutation.isPending}
          >
            <Trash2 className="h-4 w-4" /> Delete
          </Button>
        </div>
      </header>

      {deleteMutation.error && (
        <p className="mt-4 rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
          {errorMessage(deleteMutation.error)}
        </p>
      )}

      <section className="mt-8">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="section-title">Chords</h2>
          {!editMode && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => setEditMode(true)}
            >
              <Pencil className="h-3.5 w-3.5" /> Edit chords
            </Button>
          )}
        </div>
        {editMode ? (
          <ChordSheetEditor
            songId={song.id}
            baseKey={song.default_key}
            onDone={() => setEditMode(false)}
          />
        ) : (
          <ChordSheetViewer songId={song.id} baseKey={song.default_key} />
        )}
      </section>

      <section className="mt-8">
        <h2 className="section-title mb-3">Tracks</h2>
        <MultitracksPanel songId={song.id} />
      </section>

      {song.lyrics && (
        <section className="mt-8">
          <h2 className="section-title mb-3">Lyrics</h2>
          <div className="whitespace-pre-wrap rounded-2xl border border-divider bg-surface p-6 font-mono text-sm text-primary shadow-card">
            {song.lyrics}
          </div>
        </section>
      )}

      {song.notes && (
        <section className="mt-8">
          <h2 className="section-title mb-3">Notes</h2>
          <div className="whitespace-pre-wrap rounded-2xl border border-divider bg-surface p-6 text-sm text-primary shadow-card">
            {song.notes}
          </div>
        </section>
      )}

      <EditSongModal
        open={showEdit}
        onClose={() => setShowEdit(false)}
        song={song}
        bandId={bandId}
      />
    </div>
  );
}
