"use client";

import { useState, useMemo } from "react";
import { Check, Loader2, Minus, UserCircle2, Users, X } from "lucide-react";
import { cn } from "@/lib/utils";
import type { AttendanceRSVP } from "@/lib/api/setlists";
import type { RSVPStatus } from "@/types";

interface AttendanceRosterProps {
  rsvps: AttendanceRSVP[] | undefined;
  isLoading: boolean;
}

type Filter = Exclude<RSVPStatus, "pending">;

const FILTERS: { value: Filter; label: string; icon: React.ReactNode; tone: "going" | "maybe" | "no" }[] = [
  { value: "going",     label: "Going",     icon: <Check className="h-3 w-3" />,  tone: "going" },
  { value: "maybe",     label: "Maybe",     icon: <Minus className="h-3 w-3" />,  tone: "maybe" },
  { value: "not_going", label: "Not going", icon: <X className="h-3 w-3" />,      tone: "no"    },
];

const TONE = {
  going: {
    sel: "bg-going text-white border-going",
    idle: "bg-going/10 text-going border-going/30 hover:bg-going/15",
    badge: "bg-white/25 text-white",
    badgeIdle: "bg-going/15 text-going",
  },
  maybe: {
    sel: "bg-maybe text-white border-maybe",
    idle: "bg-maybe/10 text-maybe border-maybe/30 hover:bg-maybe/15",
    badge: "bg-white/25 text-white",
    badgeIdle: "bg-maybe/15 text-maybe",
  },
  no: {
    sel: "bg-no text-white border-no",
    idle: "bg-no/10 text-no border-no/30 hover:bg-no/15",
    badge: "bg-white/25 text-white",
    badgeIdle: "bg-no/15 text-no",
  },
} as const;

export function AttendanceRoster({ rsvps, isLoading }: AttendanceRosterProps) {
  const [filter, setFilter] = useState<Filter>("going");

  const counts = useMemo(() => {
    const list = rsvps ?? [];
    return {
      going:     list.filter((r) => r.status === "going").length,
      maybe:     list.filter((r) => r.status === "maybe").length,
      not_going: list.filter((r) => r.status === "not_going").length,
    };
  }, [rsvps]);

  const visible = useMemo(() => {
    return (rsvps ?? [])
      .filter((r) => r.status === filter)
      .sort((a, b) =>
        (a.profiles?.full_name ?? "").localeCompare(b.profiles?.full_name ?? ""),
      );
  }, [rsvps, filter]);

  return (
    <section className="rounded-2xl border border-divider bg-surface p-6 shadow-card">
      <header className="mb-4 flex items-center gap-2">
        <Users className="h-4 w-4 text-accent" />
        <h2 className="font-display text-lg font-semibold text-primary">
          Attendance
        </h2>
        {isLoading && <Loader2 className="ml-1 h-4 w-4 animate-spin text-secondary" />}
      </header>

      <div className="mb-4 flex flex-wrap gap-2">
        {FILTERS.map((f) => {
          const isSel = filter === f.value;
          const t = TONE[f.tone];
          return (
            <button
              key={f.value}
              type="button"
              onClick={() => setFilter(f.value)}
              className={cn(
                "inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-semibold transition active:scale-95",
                isSel ? t.sel : t.idle,
              )}
            >
              {f.icon}
              {f.label}
              <span
                className={cn(
                  "ml-1 inline-flex h-5 min-w-5 items-center justify-center rounded-full px-1.5 text-[10px] font-bold",
                  isSel ? t.badge : t.badgeIdle,
                )}
              >
                {counts[f.value]}
              </span>
            </button>
          );
        })}
      </div>

      {visible.length === 0 ? (
        <div className="flex flex-col items-center gap-2 py-6 text-center">
          <UserCircle2 className="h-7 w-7 text-divider" />
          <p className="text-sm text-secondary">No responses yet</p>
        </div>
      ) : (
        <ul className="divide-y divide-divider">
          {visible.map((r) => (
            <li key={r.user_id} className="flex items-center gap-3 py-3">
              <Avatar name={r.profiles?.full_name} />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-primary">
                  {r.profiles?.full_name ?? "Member"}
                </p>
                {r.profiles?.instrument && (
                  <p className="truncate text-xs text-secondary">
                    {r.profiles.instrument}
                  </p>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

// MARK: - Avatar

function Avatar({ name }: { name: string | null | undefined }) {
  const palette = ["#3B5BFF", "#8B5CF6", "#10B981", "#F59E0B", "#EC4899", "#06B6D4"];
  const safe = name ?? "?";
  // Stable color per name
  let hash = 0;
  for (let i = 0; i < safe.length; i++) hash = (hash * 31 + safe.charCodeAt(i)) | 0;
  const color = palette[Math.abs(hash) % palette.length];
  const initial = safe.trim().charAt(0).toUpperCase() || "?";
  return (
    <span
      className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold text-white"
      style={{
        background: `linear-gradient(135deg, ${color}, ${color}cc)`,
      }}
    >
      {initial}
    </span>
  );
}
