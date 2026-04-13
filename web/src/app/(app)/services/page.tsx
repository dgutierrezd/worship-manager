"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { CalendarPlus, Check, ListMusic, Plus } from "lucide-react";
import { cn } from "@/lib/utils";
import { useBandStore } from "@/lib/stores/band-store";
import { setlistsApi, type SetlistInput } from "@/lib/api/setlists";
import { songsApi } from "@/lib/api/songs";
import { PageHeader } from "@/components/ui/page-header";
import { Button } from "@/components/ui/button";
import { Input, Textarea } from "@/components/ui/input";
import { Modal } from "@/components/ui/modal";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/ui/empty-state";
import { SkeletonList } from "@/components/ui/skeleton";
import {
  errorMessage,
  formatShortDate,
  serviceTypeDisplay,
} from "@/lib/utils";
import type { ServiceType, Setlist } from "@/types";

const SERVICE_TYPES: { value: ServiceType; label: string }[] = [
  { value: "sunday_morning", label: "Sunday Morning" },
  { value: "sunday_evening", label: "Sunday Evening" },
  { value: "wednesday", label: "Wednesday" },
  { value: "special", label: "Special Event" },
];

export default function ServicesPage() {
  const band = useBandStore((s) => s.currentBand);
  const bandId = band?.id ?? "";
  const queryClient = useQueryClient();
  const [showCreate, setShowCreate] = useState(false);

  const query = useQuery({
    queryKey: ["setlists", bandId],
    queryFn: () => setlistsApi.list(bandId),
    enabled: !!bandId,
  });

  const songsQuery = useQuery({
    queryKey: ["songs", bandId],
    queryFn: () => songsApi.list(bandId),
    enabled: !!bandId,
  });

  /**
   * Creates the service AND attaches the user-picked songs (if any) to its
   * setlist in a single click. Uses sequential addSong calls because the
   * backend assigns sequential positions automatically — keeps the order
   * as the user picked them.
   */
  const createMutation = useMutation({
    mutationFn: async (args: {
      input: SetlistInput;
      songIds: string[];
    }) => {
      const created = await setlistsApi.create(bandId, args.input);
      for (const songId of args.songIds) {
        try {
          await setlistsApi.addSong(created.id, { song_id: songId });
        } catch {
          // best-effort — don't block service creation if one song fails
        }
      }
      return created;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["setlists", bandId] });
      setShowCreate(false);
    },
  });

  if (!band) return null;

  const upcoming = (query.data ?? []).filter(
    (s) => !s.date || new Date(s.date) >= startOfToday(),
  );
  const past = (query.data ?? []).filter(
    (s) => s.date && new Date(s.date) < startOfToday(),
  );

  return (
    <div className="animate-fade-in">
      <PageHeader
        eyebrow="Planning"
        title="Services"
        description="Plan every worship service with setlists, themes, and notes."
        actions={
          <Button variant="accent" onClick={() => setShowCreate(true)}>
            <Plus className="h-4 w-4" /> New service
          </Button>
        }
      />

      {query.isLoading ? (
        <SkeletonList count={4} />
      ) : !query.data || query.data.length === 0 ? (
        <EmptyState
          icon={ListMusic}
          title="No services yet"
          description="Create your first service to start planning setlists."
          action={
            <Button variant="accent" onClick={() => setShowCreate(true)}>
              <Plus className="h-4 w-4" /> New service
            </Button>
          }
        />
      ) : (
        <div className="space-y-10">
          {upcoming.length > 0 && (
            <ServiceGrid title="Upcoming" services={upcoming} />
          )}
          {past.length > 0 && (
            <ServiceGrid title="Past services" services={past} muted />
          )}
        </div>
      )}

      <CreateServiceModal
        open={showCreate}
        onClose={() => setShowCreate(false)}
        onSubmit={(data, songIds) =>
          createMutation.mutate({ input: data, songIds })
        }
        loading={createMutation.isPending}
        error={createMutation.error ? errorMessage(createMutation.error) : null}
        songs={songsQuery.data ?? []}
      />
    </div>
  );
}

function startOfToday(): Date {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

function ServiceGrid({
  title,
  services,
  muted = false,
}: {
  title: string;
  services: Setlist[];
  muted?: boolean;
}) {
  return (
    <section>
      <h2 className="section-title mb-4">{title}</h2>
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {services.map((s) => (
          <Link
            key={s.id}
            href={`/services/${s.id}`}
            className={`rounded-2xl border border-divider bg-surface p-5 shadow-card transition hover:-translate-y-0.5 hover:border-accent/40 ${muted ? "opacity-80" : ""}`}
          >
            <div className="flex items-center gap-2">
              <Badge variant={muted ? "muted" : "accent"}>
                {serviceTypeDisplay(s.service_type)}
              </Badge>
              {s.date && (
                <span className="text-xs font-semibold text-secondary">
                  {formatShortDate(s.date)}
                </span>
              )}
            </div>
            <p className="mt-3 font-display text-xl font-semibold text-primary">
              {s.name}
            </p>
            {s.theme && (
              <p className="mt-1 text-sm text-secondary">{s.theme}</p>
            )}
            {s.location && (
              <p className="mt-2 text-xs text-secondary">📍 {s.location}</p>
            )}
          </Link>
        ))}
      </div>
    </section>
  );
}

interface CreateModalProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (input: SetlistInput, songIds: string[]) => void;
  loading: boolean;
  error: string | null;
  songs: import("@/types").Song[];
}

function CreateServiceModal({
  open,
  onClose,
  onSubmit,
  loading,
  error,
  songs,
}: CreateModalProps) {
  const [form, setForm] = useState({
    name: "",
    date: "",
    time: "",
    service_type: "" as ServiceType | "",
    location: "",
    theme: "",
    notes: "",
  });
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [songSearch, setSongSearch] = useState("");

  const filteredSongs = useMemo(() => {
    if (!songSearch.trim()) return songs;
    const q = songSearch.toLowerCase();
    return songs.filter(
      (s) =>
        s.title.toLowerCase().includes(q) ||
        s.artist?.toLowerCase().includes(q),
    );
  }, [songs, songSearch]);

  const toggle = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Preserve the order songs appear in the (alphabetical) list
    const orderedIds = songs
      .filter((s) => selectedIds.has(s.id))
      .map((s) => s.id);
    onSubmit(
      {
        name: form.name.trim(),
        date: form.date || null,
        time: form.time || null,
        service_type: (form.service_type || null) as ServiceType | null,
        location: form.location.trim() || null,
        theme: form.theme.trim() || null,
        notes: form.notes.trim() || null,
      },
      orderedIds,
    );
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="New service"
      description="Create a service plan. You can add songs and assign roles later."
      size="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          name="name"
          label="Service name"
          required
          placeholder="e.g. Sunday Morning Worship"
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
        />
        <div className="grid grid-cols-2 gap-3">
          <Input
            name="date"
            type="date"
            label="Date"
            value={form.date}
            onChange={(e) => setForm({ ...form, date: e.target.value })}
          />
          <Input
            name="time"
            type="time"
            label="Time"
            value={form.time}
            onChange={(e) => setForm({ ...form, time: e.target.value })}
          />
        </div>
        <div>
          <label htmlFor="service_type" className="label">
            Service type
          </label>
          <select
            id="service_type"
            value={form.service_type}
            onChange={(e) =>
              setForm({
                ...form,
                service_type: e.target.value as ServiceType | "",
              })
            }
            className="input"
          >
            <option value="">—</option>
            {SERVICE_TYPES.map((t) => (
              <option key={t.value} value={t.value}>
                {t.label}
              </option>
            ))}
          </select>
        </div>
        <Input
          name="location"
          label="Location"
          value={form.location}
          onChange={(e) => setForm({ ...form, location: e.target.value })}
        />
        <Input
          name="theme"
          label="Theme"
          value={form.theme}
          onChange={(e) => setForm({ ...form, theme: e.target.value })}
        />
        <Textarea
          name="notes"
          label="Notes"
          value={form.notes}
          onChange={(e) => setForm({ ...form, notes: e.target.value })}
        />

        {/* Setlist songs (optional) — pick songs to attach now */}
        <div className="rounded-2xl border border-divider bg-surface p-4">
          <div className="mb-2 flex items-center justify-between">
            <label className="label mb-0">Setlist (optional)</label>
            {selectedIds.size > 0 && (
              <span className="text-xs font-semibold text-accent">
                {selectedIds.size} selected
              </span>
            )}
          </div>
          {songs.length === 0 ? (
            <p className="text-sm text-secondary">
              Your library is empty. Add songs first, then build the setlist on
              the service detail page.
            </p>
          ) : (
            <>
              <input
                type="search"
                placeholder="Search songs…"
                value={songSearch}
                onChange={(e) => setSongSearch(e.target.value)}
                className="input mb-3"
              />
              <div className="max-h-56 space-y-1 overflow-y-auto">
                {filteredSongs.map((song) => {
                  const checked = selectedIds.has(song.id);
                  return (
                    <button
                      key={song.id}
                      type="button"
                      onClick={() => toggle(song.id)}
                      className={cn(
                        "flex w-full items-center justify-between rounded-lg border px-3 py-2 text-left transition",
                        checked
                          ? "border-accent bg-accent/10"
                          : "border-divider bg-surface hover:border-accent/40",
                      )}
                    >
                      <div className="flex min-w-0 items-center gap-3">
                        <span
                          className={cn(
                            "flex h-5 w-5 shrink-0 items-center justify-center rounded-full border",
                            checked
                              ? "border-accent bg-accent text-white"
                              : "border-divider",
                          )}
                        >
                          {checked && <Check className="h-3 w-3" />}
                        </span>
                        <div className="min-w-0">
                          <p className="truncate text-sm font-semibold text-primary">
                            {song.title}
                          </p>
                          {song.artist && (
                            <p className="truncate text-xs text-secondary">
                              {song.artist}
                            </p>
                          )}
                        </div>
                      </div>
                      {song.default_key && (
                        <Badge variant="muted">{song.default_key}</Badge>
                      )}
                    </button>
                  );
                })}
              </div>
            </>
          )}
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
            disabled={!form.name.trim()}
          >
            <CalendarPlus className="h-4 w-4" /> Create
          </Button>
        </div>
      </form>
    </Modal>
  );
}
