"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  CalendarDays,
  Check,
  ChevronDown,
  ChevronUp,
  Minus,
  Pencil,
  Plus,
  Trash2,
  X,
} from "lucide-react";
import { useBandStore } from "@/lib/stores/band-store";
import { rehearsalsApi, type RehearsalInput } from "@/lib/api/rehearsals";
import { AttendanceRoster } from "@/components/attendance-roster";
import { setlistsApi } from "@/lib/api/setlists";
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
  formatTime,
  parseISODate,
} from "@/lib/utils";
import type { Rehearsal, RSVPStatus } from "@/types";
import { cn } from "@/lib/utils";

export default function RehearsalsPage() {
  const band = useBandStore((s) => s.currentBand);
  const bandId = band?.id ?? "";
  const queryClient = useQueryClient();
  const [showCreate, setShowCreate] = useState(false);
  const [editing, setEditing] = useState<Rehearsal | null>(null);

  const query = useQuery({
    queryKey: ["rehearsals", bandId],
    queryFn: () => rehearsalsApi.list(bandId),
    enabled: !!bandId,
  });

  const setlistsQuery = useQuery({
    queryKey: ["setlists", bandId],
    queryFn: () => setlistsApi.list(bandId),
    enabled: !!bandId,
  });

  const createMutation = useMutation({
    mutationFn: (input: RehearsalInput) => rehearsalsApi.create(bandId, input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["rehearsals", bandId] });
      setShowCreate(false);
    },
  });

  const rsvpMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: RSVPStatus }) =>
      rehearsalsApi.rsvp(id, status),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ["rehearsals", bandId] }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => rehearsalsApi.remove(id),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ["rehearsals", bandId] }),
  });

  const updateMutation = useMutation({
    mutationFn: ({
      id,
      input,
    }: {
      id: string;
      input: Partial<RehearsalInput>;
    }) => rehearsalsApi.update(id, input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["rehearsals", bandId] });
      setEditing(null);
    },
  });

  if (!band) return null;

  const now = Date.now();
  const upcoming = (query.data ?? []).filter(
    (r) => new Date(r.scheduled_at).getTime() >= now,
  );
  const past = (query.data ?? []).filter(
    (r) => new Date(r.scheduled_at).getTime() < now,
  );

  return (
    <div className="animate-fade-in">
      <PageHeader
        eyebrow="Schedule"
        title="Rehearsals"
        description="Schedule rehearsals and track who's coming."
        actions={
          <Button variant="accent" onClick={() => setShowCreate(true)}>
            <Plus className="h-4 w-4" /> New rehearsal
          </Button>
        }
      />

      {query.isLoading ? (
        <SkeletonList count={4} />
      ) : !query.data || query.data.length === 0 ? (
        <EmptyState
          icon={CalendarDays}
          title="No rehearsals scheduled"
          description="Create your first rehearsal to start coordinating your team."
          action={
            <Button variant="accent" onClick={() => setShowCreate(true)}>
              <Plus className="h-4 w-4" /> New rehearsal
            </Button>
          }
        />
      ) : (
        <div className="space-y-10">
          {upcoming.length > 0 && (
            <RehearsalList
              title="Upcoming"
              rehearsals={upcoming}
              onRSVP={(id, status) => rsvpMutation.mutate({ id, status })}
              onEdit={(r) => setEditing(r)}
              onDelete={(r) => {
                if (confirm(`Delete "${r.title}"?`)) {
                  deleteMutation.mutate(r.id);
                }
              }}
            />
          )}
          {past.length > 0 && (
            <RehearsalList
              title="Past rehearsals"
              rehearsals={past}
              muted
              onEdit={(r) => setEditing(r)}
              onDelete={(r) => {
                if (confirm(`Delete "${r.title}"?`)) {
                  deleteMutation.mutate(r.id);
                }
              }}
            />
          )}
        </div>
      )}

      <RehearsalFormModal
        open={showCreate}
        onClose={() => setShowCreate(false)}
        setlists={setlistsQuery.data ?? []}
        onSubmit={(data) => createMutation.mutate(data)}
        loading={createMutation.isPending}
        error={createMutation.error ? errorMessage(createMutation.error) : null}
      />

      {editing && (
        <RehearsalFormModal
          open={!!editing}
          onClose={() => setEditing(null)}
          setlists={setlistsQuery.data ?? []}
          initial={editing}
          onSubmit={(data) =>
            updateMutation.mutate({ id: editing.id, input: data })
          }
          loading={updateMutation.isPending}
          error={
            updateMutation.error ? errorMessage(updateMutation.error) : null
          }
        />
      )}
    </div>
  );
}

interface RehearsalListProps {
  title: string;
  rehearsals: Rehearsal[];
  muted?: boolean;
  onRSVP?: (id: string, status: RSVPStatus) => void;
  onEdit?: (r: Rehearsal) => void;
  onDelete?: (r: Rehearsal) => void;
}

function RehearsalList({
  title,
  rehearsals,
  muted = false,
  onRSVP,
  onEdit,
  onDelete,
}: RehearsalListProps) {
  return (
    <section>
      <h2 className="section-title mb-4">{title}</h2>
      <div className="space-y-3">
        {rehearsals.map((r) => (
          <RehearsalCard
            key={r.id}
            rehearsal={r}
            muted={muted}
            onRSVP={onRSVP}
            onEdit={onEdit}
            onDelete={onDelete}
          />
        ))}
      </div>
    </section>
  );
}

interface RehearsalCardProps {
  rehearsal: Rehearsal;
  muted?: boolean;
  onRSVP?: (id: string, status: RSVPStatus) => void;
  onEdit?: (r: Rehearsal) => void;
  onDelete?: (r: Rehearsal) => void;
}

function RehearsalCard({
  rehearsal: r,
  muted,
  onRSVP,
  onEdit,
  onDelete,
}: RehearsalCardProps) {
  const [showRoster, setShowRoster] = useState(false);

  // Lazy-load roster only when expanded
  const rosterQuery = useQuery({
    queryKey: ["rehearsal-rsvps", r.id],
    queryFn: () => rehearsalsApi.rsvps(r.id),
    enabled: showRoster,
  });

  // Compact attendance summary (always visible) — counts derive from the
  // roster query if it's been opened, otherwise from a lightweight fetch.
  const summaryQuery = useQuery({
    queryKey: ["rehearsal-rsvps-summary", r.id],
    queryFn: () => rehearsalsApi.rsvps(r.id),
  });
  const summary = summaryQuery.data ?? rosterQuery.data ?? [];
  const counts = {
    going: summary.filter((s) => s.status === "going").length,
    maybe: summary.filter((s) => s.status === "maybe").length,
    no: summary.filter((s) => s.status === "not_going").length,
  };

  return (
    <article
      className={cn(
        "rounded-2xl border border-divider bg-surface p-5 shadow-card",
        muted && "opacity-80",
      )}
    >
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <Badge variant={muted ? "muted" : "accent"}>
              {formatShortDate(r.scheduled_at)}
            </Badge>
            <span className="text-xs font-semibold text-secondary">
              {formatTime(r.scheduled_at)}
            </span>
          </div>
          <h3 className="mt-2 font-display text-xl font-semibold text-primary">
            {r.title}
          </h3>
          {r.location && (
            <p className="mt-1 text-sm text-secondary">📍 {r.location}</p>
          )}
          {r.setlists?.name && (
            <p className="mt-1 text-xs text-secondary">
              Setlist: {r.setlists.name}
            </p>
          )}

          {/* Compact attendance summary */}
          <div className="mt-3 flex flex-wrap items-center gap-1.5">
            <SummaryChip color="going" count={counts.going} />
            <SummaryChip color="maybe" count={counts.maybe} />
            <SummaryChip color="no"    count={counts.no} />
            <button
              type="button"
              onClick={() => setShowRoster((v) => !v)}
              className="ml-2 inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-semibold text-secondary transition hover:text-accent"
            >
              {showRoster ? (
                <>Hide <ChevronUp className="h-3 w-3" /></>
              ) : (
                <>See who <ChevronDown className="h-3 w-3" /></>
              )}
            </button>
          </div>
        </div>
        <div className="flex flex-wrap items-center gap-2">
                {onRSVP && (
                  <>
                    <RSVPButton
                      onClick={() => onRSVP(r.id, "going")}
                      label="Going"
                      icon={<Check className="h-4 w-4" />}
                      color="text-going"
                    />
                    <RSVPButton
                      onClick={() => onRSVP(r.id, "maybe")}
                      label="Maybe"
                      icon={<Minus className="h-4 w-4" />}
                      color="text-maybe"
                    />
                    <RSVPButton
                      onClick={() => onRSVP(r.id, "not_going")}
                      label="No"
                      icon={<X className="h-4 w-4" />}
                      color="text-no"
                    />
                  </>
                )}
                {onEdit && (
                  <button
                    type="button"
                    aria-label="Edit rehearsal"
                    onClick={() => onEdit(r)}
                    className="rounded-full p-2 text-secondary transition hover:bg-surfaceMuted hover:text-primary"
                  >
                    <Pencil className="h-4 w-4" />
                  </button>
                )}
                {onDelete && (
                  <button
                    type="button"
                    aria-label="Delete rehearsal"
                    onClick={() => onDelete(r)}
                    className="rounded-full p-2 text-secondary transition hover:bg-danger/10 hover:text-danger"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                )}
              </div>
      </div>

      {showRoster && (
        <div className="mt-4">
          <AttendanceRoster rsvps={rosterQuery.data} isLoading={rosterQuery.isLoading} />
        </div>
      )}
    </article>
  );
}

// MARK: - Attendance summary chip

function SummaryChip({ color, count }: { color: "going" | "maybe" | "no"; count: number }) {
  const map = {
    going: "bg-going/10 text-going border-going/30",
    maybe: "bg-maybe/10 text-maybe border-maybe/30",
    no:    "bg-no/10 text-no border-no/30",
  } as const;
  const label = { going: "going", maybe: "maybe", no: "not going" }[color];
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] font-semibold",
        map[color],
      )}
    >
      {count} {label}
    </span>
  );
}

function RSVPButton({
  onClick,
  label,
  icon,
  color,
}: {
  onClick: () => void;
  label: string;
  icon: React.ReactNode;
  color: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "inline-flex items-center gap-1 rounded-full border border-divider bg-surface px-3 py-1.5 text-xs font-semibold transition hover:border-accent/40",
        color,
      )}
    >
      {icon}
      {label}
    </button>
  );
}

interface RehearsalFormModalProps {
  open: boolean;
  onClose: () => void;
  setlists: import("@/types").Setlist[];
  onSubmit: (input: RehearsalInput) => void;
  loading: boolean;
  error: string | null;
  /** When provided, the modal opens in "edit" mode. */
  initial?: Rehearsal;
}

function RehearsalFormModal({
  open,
  onClose,
  setlists,
  onSubmit,
  loading,
  error,
  initial,
}: RehearsalFormModalProps) {
  const initialDate = initial
    ? new Date(initial.scheduled_at).toISOString().slice(0, 10)
    : "";
  const initialTime = initial
    ? new Date(initial.scheduled_at).toTimeString().slice(0, 5)
    : "";

  const [form, setForm] = useState({
    title: initial?.title ?? "",
    date: initialDate,
    time: initialTime,
    location: initial?.location ?? "",
    setlist_id: initial?.setlist_id ?? "",
    notes: initial?.notes ?? "",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.date || !form.time) return;
    const scheduled_at = parseISODate(`${form.date}T${form.time}`)?.toISOString();
    if (!scheduled_at) return;
    onSubmit({
      title: form.title.trim(),
      scheduled_at,
      location: form.location.trim() || null,
      setlist_id: form.setlist_id || null,
      notes: form.notes.trim() || null,
    });
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={initial ? "Edit rehearsal" : "New rehearsal"}
      description={
        initial
          ? "Update the rehearsal details."
          : "Everyone in your band will get a push notification."
      }
      size="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          name="title"
          label="Title"
          required
          placeholder="e.g. Thursday Practice"
          value={form.title}
          onChange={(e) => setForm({ ...form, title: e.target.value })}
        />
        <div className="grid grid-cols-2 gap-3">
          <Input
            name="date"
            type="date"
            label="Date"
            required
            value={form.date}
            onChange={(e) => setForm({ ...form, date: e.target.value })}
          />
          <Input
            name="time"
            type="time"
            label="Time"
            required
            value={form.time}
            onChange={(e) => setForm({ ...form, time: e.target.value })}
          />
        </div>
        <Input
          name="location"
          label="Location"
          value={form.location}
          onChange={(e) => setForm({ ...form, location: e.target.value })}
        />
        <div>
          <label htmlFor="setlist_id" className="label">
            Linked setlist (optional)
          </label>
          <select
            id="setlist_id"
            value={form.setlist_id}
            onChange={(e) => setForm({ ...form, setlist_id: e.target.value })}
            className="input"
          >
            <option value="">—</option>
            {setlists.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
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
            disabled={!form.title.trim() || !form.date || !form.time}
          >
            {initial ? "Save changes" : "Create"}
          </Button>
        </div>
      </form>
    </Modal>
  );
}
