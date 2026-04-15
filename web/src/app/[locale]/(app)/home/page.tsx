"use client";

import { useQuery } from "@tanstack/react-query";
import { useTranslations } from "next-intl";
import {
  ArrowRight,
  CalendarDays,
  ListMusic,
  Music2,
  Users,
} from "lucide-react";
import { Link } from "@/i18n/navigation";
import { useBandStore } from "@/lib/stores/band-store";
import { songsApi } from "@/lib/api/songs";
import { setlistsApi } from "@/lib/api/setlists";
import { rehearsalsApi } from "@/lib/api/rehearsals";
import { BandAvatar } from "@/components/ui/band-avatar";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { formatShortDate, formatTime } from "@/lib/utils";

const QUICK_LINKS = [
  {
    href: "/services",
    key: "services",
    icon: ListMusic,
    color: "bg-accent/15 text-accent ring-1 ring-accent/20",
  },
  {
    href: "/songs",
    key: "songs",
    icon: Music2,
    color: "bg-primary/10 text-primary ring-1 ring-primary/15",
  },
  {
    href: "/rehearsals",
    key: "schedule",
    icon: CalendarDays,
    color: "bg-success/12 text-success ring-1 ring-success/25",
  },
  {
    href: "/members",
    key: "team",
    icon: Users,
    color: "bg-warning/15 text-warning ring-1 ring-warning/25",
  },
] as const;

export default function HomePage() {
  const t = useTranslations("home");
  const tc = useTranslations("common");
  const band = useBandStore((s) => s.currentBand);
  const bandId = band?.id ?? "";

  const songsQuery = useQuery({
    queryKey: ["songs", bandId],
    queryFn: () => songsApi.list(bandId),
    enabled: !!bandId,
  });

  const setlistsQuery = useQuery({
    queryKey: ["setlists", bandId],
    queryFn: () => setlistsApi.list(bandId),
    enabled: !!bandId,
  });

  const rehearsalsQuery = useQuery({
    queryKey: ["rehearsals", bandId],
    queryFn: () => rehearsalsApi.list(bandId),
    enabled: !!bandId,
  });

  if (!band) return null;

  const upcomingServices = (setlistsQuery.data ?? [])
    .filter((s) => !!s.date)
    .slice(0, 3);

  const nextRehearsal = (rehearsalsQuery.data ?? []).find(
    (r) => new Date(r.scheduled_at).getTime() >= Date.now(),
  );

  const recentSongs = (songsQuery.data ?? []).slice(0, 12);

  return (
    <div className="space-y-10 animate-fade-in">
      {/* Band header */}
      <section className="relative overflow-hidden rounded-3xl bg-sidebar-gradient p-8 text-sidebar-fg shadow-elevated noise">
        <div
          aria-hidden
          className="pointer-events-none absolute -right-24 -top-24 h-80 w-80 rounded-full bg-accent/25 blur-3xl"
        />
        <div
          aria-hidden
          className="pointer-events-none absolute -bottom-32 left-20 h-72 w-72 rounded-full bg-[rgb(99_102_241_/_0.25)] blur-3xl"
        />
        <div className="relative flex flex-col gap-5 md:flex-row md:items-center">
          <BandAvatar band={band} size={84} className="shrink-0 shadow-elevated" />
          <div className="flex-1">
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-accent">
              {band.my_role === "leader" ? tc("leader") : tc("member")}
            </p>
            <h1 className="mt-1 font-display text-4xl font-semibold tracking-tight text-white md:text-5xl">
              {band.name}
            </h1>
            {band.church && (
              <p className="mt-1 text-sm text-sidebar-muted">{band.church}</p>
            )}
            <div className="mt-5 flex flex-wrap gap-3 text-sm">
              <Stat
                label={t("stats.services")}
                value={setlistsQuery.data?.length ?? 0}
                loading={setlistsQuery.isLoading}
              />
              <Stat
                label={t("stats.songs")}
                value={songsQuery.data?.length ?? 0}
                loading={songsQuery.isLoading}
              />
              <Stat
                label={t("stats.rehearsals")}
                value={rehearsalsQuery.data?.length ?? 0}
                loading={rehearsalsQuery.isLoading}
              />
            </div>
          </div>
        </div>
      </section>

      {/* Quick access */}
      <section>
        <h2 className="section-title mb-4">{t("quickAccessTitle")}</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {QUICK_LINKS.map(({ href, key, icon: Icon, color }) => (
            <Link
              key={href}
              href={href}
              className="group relative overflow-hidden rounded-2xl border border-divider bg-surface p-5 shadow-card transition-all duration-300 hover:-translate-y-1 hover:border-accent/40 hover:shadow-elevated"
            >
              <div
                className={`mb-3 flex h-10 w-10 items-center justify-center rounded-xl ${color}`}
              >
                <Icon className="h-5 w-5" />
              </div>
              <p className="font-display text-lg font-semibold text-primary">
                {t(`quickLinks.${key}.label`)}
              </p>
              <p className="mt-0.5 text-sm text-secondary">
                {t(`quickLinks.${key}.description`)}
              </p>
              <ArrowRight className="mt-4 h-4 w-4 text-secondary transition-transform duration-300 group-hover:translate-x-1 group-hover:text-accent" />
            </Link>
          ))}
        </div>
      </section>

      {/* Next rehearsal */}
      {nextRehearsal && (
        <section>
          <h2 className="section-title mb-4">{t("nextRehearsal")}</h2>
          <Link
            href="/rehearsals"
            className="block rounded-2xl border border-divider bg-surface p-6 shadow-card transition hover:border-accent/40"
          >
            <div className="flex items-start justify-between gap-4">
              <div>
                <Badge variant="accent">
                  {formatShortDate(nextRehearsal.scheduled_at)}
                </Badge>
                <h3 className="mt-2 font-display text-xl font-semibold text-primary">
                  {nextRehearsal.title}
                </h3>
                <p className="mt-1 text-sm text-secondary">
                  {formatTime(nextRehearsal.scheduled_at)}
                  {nextRehearsal.location ? ` · ${nextRehearsal.location}` : ""}
                </p>
              </div>
              <CalendarDays className="h-6 w-6 text-accent" />
            </div>
          </Link>
        </section>
      )}

      {/* Upcoming services */}
      {upcomingServices.length > 0 && (
        <section>
          <div className="mb-4 flex items-center justify-between">
            <h2 className="section-title">{t("upcomingServices")}</h2>
            <Link
              href="/services"
              className="text-sm font-semibold text-accent hover:underline"
            >
              {tc("viewAll")}
            </Link>
          </div>
          <div className="grid gap-4 md:grid-cols-3">
            {upcomingServices.map((s) => (
              <Link
                key={s.id}
                href={`/services/${s.id}`}
                className="rounded-2xl border border-divider bg-surface p-5 shadow-card transition hover:-translate-y-0.5 hover:border-accent/40"
              >
                <Badge variant="accent">{formatShortDate(s.date)}</Badge>
                <p className="mt-3 font-display text-lg font-semibold text-primary">
                  {s.name}
                </p>
                {s.theme && (
                  <p className="mt-1 text-sm text-secondary">{s.theme}</p>
                )}
              </Link>
            ))}
          </div>
        </section>
      )}

      {/* Recent songs */}
      {recentSongs.length > 0 && (
        <section>
          <div className="mb-4 flex items-center justify-between">
            <h2 className="section-title">{t("recentSongs")}</h2>
            <Link
              href="/songs"
              className="text-sm font-semibold text-accent hover:underline"
            >
              {tc("viewAll")}
            </Link>
          </div>
          <div className="flex flex-wrap gap-2">
            {recentSongs.map((song) => (
              <Link
                key={song.id}
                href={`/songs/${song.id}`}
                className="rounded-full border border-divider bg-surface px-4 py-2 text-sm font-medium text-primary transition hover:border-accent/50 hover:text-accent"
              >
                {song.title}
                {song.default_key && (
                  <span className="ml-2 text-xs text-accent">
                    {song.default_key}
                  </span>
                )}
              </Link>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}

function Stat({
  label,
  value,
  loading,
}: {
  label: string;
  value: number;
  loading: boolean;
}) {
  return (
    <div className="rounded-xl border border-white/10 bg-white/5 px-4 py-2 backdrop-blur">
      {loading ? (
        <Skeleton className="h-5 w-10" />
      ) : (
        <p className="font-display text-xl font-semibold text-white">{value}</p>
      )}
      <p className="text-[10px] font-semibold uppercase tracking-widest text-sidebar-muted">
        {label}
      </p>
    </div>
  );
}
