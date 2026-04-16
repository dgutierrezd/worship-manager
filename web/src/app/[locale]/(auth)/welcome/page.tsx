import Image from "next/image";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { Button } from "@/components/ui/button";
import {
  Music2,
  CalendarHeart,
  Users2,
  Sparkles,
  FileMusic,
  CalendarCheck,
  Headphones,
  ArrowRight,
  CheckCircle2,
  Bell,
  KeyRound,
  Hash,
} from "lucide-react";

// ─── Feature cards ──────────────────────────────────────────────────────────

const FEATURES = [
  { key: "library", icon: Music2, color: "text-accent bg-accent/15" },
  { key: "chords", icon: Hash, color: "text-violet-400 bg-violet-500/15" },
  {
    key: "services",
    icon: CalendarHeart,
    color: "text-rose-400 bg-rose-500/15",
  },
  {
    key: "rehearsals",
    icon: CalendarCheck,
    color: "text-emerald-400 bg-emerald-500/15",
  },
  { key: "team", icon: Users2, color: "text-amber-400 bg-amber-500/15" },
  {
    key: "multitracks",
    icon: Headphones,
    color: "text-sky-400 bg-sky-500/15",
  },
] as const;

// ─── Mock UI cards for feature spotlights ───────────────────────────────────

function SongLibraryMock() {
  const songs = [
    { title: "Way Maker", key: "G", tempo: "72 BPM" },
    { title: "Goodness of God", key: "A", tempo: "68 BPM" },
    { title: "Build My Life", key: "D", tempo: "76 BPM" },
    { title: "What a Beautiful Name", key: "Bb", tempo: "67 BPM" },
  ];
  return (
    <div className="w-full overflow-hidden rounded-2xl border border-white/10 bg-white/5 shadow-elevated">
      <div className="flex items-center gap-2 border-b border-white/10 px-4 py-3">
        <div className="flex gap-1.5">
          <span className="h-3 w-3 rounded-full bg-white/15" />
          <span className="h-3 w-3 rounded-full bg-white/15" />
          <span className="h-3 w-3 rounded-full bg-white/15" />
        </div>
        <span className="ml-2 text-xs text-sidebar-muted">Song Library</span>
      </div>
      <div className="divide-y divide-white/5 p-3">
        {songs.map((s) => (
          <div
            key={s.title}
            className="flex items-center justify-between py-2.5 px-1"
          >
            <div className="flex items-center gap-3">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-accent/20">
                <Music2 className="h-3.5 w-3.5 text-accent" />
              </div>
              <span className="text-sm font-medium text-sidebar-fg">
                {s.title}
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span className="rounded-md bg-accent/20 px-2 py-0.5 font-mono text-xs font-semibold text-accent">
                {s.key}
              </span>
              <span className="text-xs text-sidebar-muted">{s.tempo}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function SetlistMock() {
  const songs = [
    { pos: 1, title: "Holy Forever", key: "G" },
    { pos: 2, title: "King of Kings", key: "D" },
    { pos: 3, title: "What a Beautiful Name", key: "Bb" },
    { pos: 4, title: "Graves Into Gardens", key: "E" },
  ];
  return (
    <div className="w-full overflow-hidden rounded-2xl border border-white/10 bg-white/5 shadow-elevated">
      <div className="flex items-center gap-2 border-b border-white/10 px-4 py-3">
        <div className="flex gap-1.5">
          <span className="h-3 w-3 rounded-full bg-white/15" />
          <span className="h-3 w-3 rounded-full bg-white/15" />
          <span className="h-3 w-3 rounded-full bg-white/15" />
        </div>
        <span className="ml-2 text-xs text-sidebar-muted">
          Sunday Morning · Jun 22
        </span>
      </div>
      <div className="space-y-1.5 p-3">
        {songs.map((s) => (
          <div
            key={s.pos}
            className="flex items-center gap-3 rounded-xl bg-white/5 px-3 py-2.5 transition hover:bg-white/10"
          >
            <span className="flex h-6 w-6 items-center justify-center rounded-md bg-accent/15 font-mono text-xs font-bold text-accent">
              {s.pos}
            </span>
            <span className="flex-1 text-sm font-medium text-sidebar-fg">
              {s.title}
            </span>
            <span className="rounded-md border border-white/10 px-2 py-0.5 font-mono text-xs text-sidebar-muted">
              {s.key}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

function RehearsalMock() {
  const members = [
    { name: "Sarah K.", status: "going", instrument: "Vocals" },
    { name: "James R.", status: "going", instrument: "Guitar" },
    { name: "Maria L.", status: "maybe", instrument: "Keys" },
    { name: "David C.", status: "not_going", instrument: "Bass" },
  ];
  const statusColors: Record<string, string> = {
    going: "bg-emerald-500/20 text-emerald-400",
    maybe: "bg-amber-500/20 text-amber-400",
    not_going: "bg-rose-500/20 text-rose-400",
  };
  const statusLabel: Record<string, string> = {
    going: "Going",
    maybe: "Maybe",
    not_going: "Can't go",
  };
  return (
    <div className="w-full overflow-hidden rounded-2xl border border-white/10 bg-white/5 shadow-elevated">
      <div className="flex items-center gap-2 border-b border-white/10 px-4 py-3">
        <div className="flex gap-1.5">
          <span className="h-3 w-3 rounded-full bg-white/15" />
          <span className="h-3 w-3 rounded-full bg-white/15" />
          <span className="h-3 w-3 rounded-full bg-white/15" />
        </div>
        <span className="ml-2 text-xs text-sidebar-muted">
          Thursday Rehearsal · 7 PM
        </span>
      </div>
      <div className="divide-y divide-white/5 p-3">
        {members.map((m) => (
          <div
            key={m.name}
            className="flex items-center justify-between py-2.5 px-1"
          >
            <div className="flex items-center gap-3">
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-white/10 font-semibold text-xs text-sidebar-fg">
                {m.name[0]}
              </div>
              <div>
                <p className="text-sm font-medium text-sidebar-fg">{m.name}</p>
                <p className="text-xs text-sidebar-muted">{m.instrument}</p>
              </div>
            </div>
            <span
              className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${statusColors[m.status]}`}
            >
              {statusLabel[m.status]}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Main component ──────────────────────────────────────────────────────────

export default function WelcomePage() {
  const t = useTranslations("welcome");

  return (
    <div className="relative z-10 mx-auto w-full max-w-5xl animate-fade-in px-2">
      {/* ── HERO ─────────────────────────────────────────────────────────── */}
      <section className="flex flex-col items-center text-center">
        {/* Badge */}
        <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/5 px-4 py-1.5 text-xs font-semibold uppercase tracking-widest text-sidebar-muted backdrop-blur">
          <Sparkles className="h-3.5 w-3.5 text-accent" />
          {t("badge")}
        </div>

        {/* Logo mark */}
        <div className="mb-8 h-20 w-20 overflow-hidden rounded-3xl bg-white ring-1 ring-white/20 shadow-accentGlow">
          <Image
            src="/logo-mark.png"
            alt="Worship Manager"
            width={160}
            height={160}
            priority
            className="h-full w-full object-cover"
          />
        </div>

        <h1 className="font-display text-5xl font-semibold tracking-tight text-white md:text-6xl lg:text-7xl">
          {t("heroTitle")}{" "}
          <span className="text-accent">{t("heroTitleAccent")}</span>
        </h1>
        <p className="mt-6 max-w-2xl text-base text-sidebar-muted md:text-lg leading-relaxed">
          {t("heroDescription")}
        </p>

        <div className="mt-10 flex flex-col items-center gap-3 sm:flex-row">
          <Link href="/signup">
            <Button variant="accent" size="lg" className="min-w-48 gap-2">
              {t("createAccount")}
              <ArrowRight className="h-4 w-4" />
            </Button>
          </Link>
          <Link href="/login">
            <Button
              variant="outline"
              size="lg"
              className="min-w-48 border-white/20 bg-white/5 text-sidebar-fg hover:border-accent/50 hover:bg-white/10 hover:text-white"
            >
              {t("signIn")}
            </Button>
          </Link>
        </div>

        {/* Trust row */}
        <div className="mt-8 flex items-center gap-6 text-xs text-sidebar-muted">
          {(["free", "noCard", "ios"] as const).map((k) => (
            <span key={k} className="flex items-center gap-1.5">
              <CheckCircle2 className="h-3.5 w-3.5 text-accent" />
              {t(`trust.${k}`)}
            </span>
          ))}
        </div>
      </section>

      {/* ── FEATURES GRID ────────────────────────────────────────────────── */}
      <section className="mt-24">
        <div className="mb-12 text-center">
          <p className="mb-3 text-xs font-semibold uppercase tracking-widest text-accent">
            {t("featuresEyebrow")}
          </p>
          <h2 className="font-display text-3xl font-semibold tracking-tight text-white md:text-4xl">
            {t("featuresTitle")}
          </h2>
          <p className="mt-4 text-sidebar-muted md:text-base max-w-xl mx-auto">
            {t("featuresSubtitle")}
          </p>
        </div>

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map(({ key, icon: Icon, color }) => (
            <div
              key={key}
              className="group rounded-2xl border border-white/10 bg-white/5 p-6 text-left backdrop-blur transition hover:border-accent/40 hover:bg-white/[0.08]"
            >
              <div
                className={`mb-4 flex h-10 w-10 items-center justify-center rounded-xl ${color}`}
              >
                <Icon className="h-5 w-5" />
              </div>
              <p className="font-semibold text-sidebar-fg">
                {t(`features.${key}.title`)}
              </p>
              <p className="mt-2 text-sm leading-relaxed text-sidebar-muted">
                {t(`features.${key}.description`)}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* ── FEATURE SPOTLIGHTS ───────────────────────────────────────────── */}
      <section className="mt-28 space-y-24">
        {/* Spotlight 1 — Song library */}
        <div className="grid items-center gap-12 lg:grid-cols-2">
          <div>
            <div className="mb-3 inline-flex items-center gap-2 rounded-full bg-accent/15 px-3 py-1 text-xs font-semibold text-accent">
              <Music2 className="h-3.5 w-3.5" />
              {t("spotlight1.eyebrow")}
            </div>
            <h3 className="font-display text-3xl font-semibold tracking-tight text-white">
              {t("spotlight1.title")}
            </h3>
            <p className="mt-4 leading-relaxed text-sidebar-muted">
              {t("spotlight1.description")}
            </p>
            <ul className="mt-6 space-y-3">
              {(["a", "b", "c"] as const).map((k) => (
                <li key={k} className="flex items-start gap-3 text-sm">
                  <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-accent" />
                  <span className="text-sidebar-muted">
                    {t(`spotlight1.bullets.${k}`)}
                  </span>
                </li>
              ))}
            </ul>
          </div>
          <SongLibraryMock />
        </div>

        {/* Spotlight 2 — Services & setlists */}
        <div className="grid items-center gap-12 lg:grid-cols-2">
          <div className="order-last lg:order-first">
            <SetlistMock />
          </div>
          <div>
            <div className="mb-3 inline-flex items-center gap-2 rounded-full bg-rose-500/15 px-3 py-1 text-xs font-semibold text-rose-400">
              <CalendarHeart className="h-3.5 w-3.5" />
              {t("spotlight2.eyebrow")}
            </div>
            <h3 className="font-display text-3xl font-semibold tracking-tight text-white">
              {t("spotlight2.title")}
            </h3>
            <p className="mt-4 leading-relaxed text-sidebar-muted">
              {t("spotlight2.description")}
            </p>
            <ul className="mt-6 space-y-3">
              {(["a", "b", "c"] as const).map((k) => (
                <li key={k} className="flex items-start gap-3 text-sm">
                  <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-accent" />
                  <span className="text-sidebar-muted">
                    {t(`spotlight2.bullets.${k}`)}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Spotlight 3 — Team & rehearsals */}
        <div className="grid items-center gap-12 lg:grid-cols-2">
          <div>
            <div className="mb-3 inline-flex items-center gap-2 rounded-full bg-emerald-500/15 px-3 py-1 text-xs font-semibold text-emerald-400">
              <Bell className="h-3.5 w-3.5" />
              {t("spotlight3.eyebrow")}
            </div>
            <h3 className="font-display text-3xl font-semibold tracking-tight text-white">
              {t("spotlight3.title")}
            </h3>
            <p className="mt-4 leading-relaxed text-sidebar-muted">
              {t("spotlight3.description")}
            </p>
            <ul className="mt-6 space-y-3">
              {(["a", "b", "c"] as const).map((k) => (
                <li key={k} className="flex items-start gap-3 text-sm">
                  <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-accent" />
                  <span className="text-sidebar-muted">
                    {t(`spotlight3.bullets.${k}`)}
                  </span>
                </li>
              ))}
            </ul>
          </div>
          <RehearsalMock />
        </div>
      </section>

      {/* ── HOW IT WORKS ─────────────────────────────────────────────────── */}
      <section className="mt-28">
        <div className="mb-14 text-center">
          <p className="mb-3 text-xs font-semibold uppercase tracking-widest text-accent">
            {t("howItWorks.eyebrow")}
          </p>
          <h2 className="font-display text-3xl font-semibold tracking-tight text-white md:text-4xl">
            {t("howItWorks.title")}
          </h2>
          <p className="mt-4 text-sidebar-muted max-w-xl mx-auto">
            {t("howItWorks.subtitle")}
          </p>
        </div>

        <div className="relative grid gap-8 md:grid-cols-3">
          {/* connector line */}
          <div className="absolute left-0 right-0 top-8 hidden h-px bg-gradient-to-r from-transparent via-white/10 to-transparent md:block" />

          {(["step1", "step2", "step3"] as const).map((step, i) => (
            <div key={step} className="relative flex flex-col items-center text-center">
              <div className="relative mb-6 flex h-16 w-16 items-center justify-center rounded-2xl border border-white/10 bg-white/5 shadow-elevated">
                <span className="font-display text-2xl font-bold text-accent">
                  {String(i + 1).padStart(2, "0")}
                </span>
              </div>
              <h4 className="font-semibold text-sidebar-fg">
                {t(`howItWorks.${step}.title`)}
              </h4>
              <p className="mt-2 text-sm leading-relaxed text-sidebar-muted">
                {t(`howItWorks.${step}.description`)}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* ── EXTRAS ROW ───────────────────────────────────────────────────── */}
      <section className="mt-24">
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {(
            [
              {
                icon: KeyRound,
                color: "text-violet-400",
                bg: "bg-violet-500/10",
                key: "extra1",
              },
              {
                icon: FileMusic,
                color: "text-rose-400",
                bg: "bg-rose-500/10",
                key: "extra2",
              },
              {
                icon: Headphones,
                color: "text-sky-400",
                bg: "bg-sky-500/10",
                key: "extra3",
              },
              {
                icon: Bell,
                color: "text-amber-400",
                bg: "bg-amber-500/10",
                key: "extra4",
              },
            ] as const
          ).map(({ icon: Icon, color, bg, key }) => (
            <div
              key={key}
              className="rounded-2xl border border-white/10 bg-white/5 p-5 text-center backdrop-blur transition hover:border-accent/30 hover:bg-white/[0.08]"
            >
              <div
                className={`mx-auto mb-3 flex h-10 w-10 items-center justify-center rounded-xl ${bg}`}
              >
                <Icon className={`h-5 w-5 ${color}`} />
              </div>
              <p className="text-sm font-semibold text-sidebar-fg">
                {t(`extras.${key}.title`)}
              </p>
              <p className="mt-1 text-xs leading-relaxed text-sidebar-muted">
                {t(`extras.${key}.description`)}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* ── BOTTOM CTA ───────────────────────────────────────────────────── */}
      <section className="mt-24 mb-12">
        <div className="relative overflow-hidden rounded-3xl border border-white/10 bg-white/5 px-8 py-14 text-center backdrop-blur">
          {/* accent glow blob */}
          <div className="pointer-events-none absolute left-1/2 top-0 h-64 w-64 -translate-x-1/2 -translate-y-1/2 rounded-full bg-accent/25 blur-3xl" />

          <div className="relative z-10">
            <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/5 px-4 py-1.5 text-xs font-semibold uppercase tracking-widest text-sidebar-muted">
              <Sparkles className="h-3.5 w-3.5 text-accent" />
              {t("cta.eyebrow")}
            </div>
            <h2 className="font-display text-3xl font-semibold tracking-tight text-white md:text-4xl">
              {t("cta.title")}
            </h2>
            <p className="mt-4 text-sidebar-muted max-w-lg mx-auto">
              {t("cta.description")}
            </p>
            <div className="mt-8 flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
              <Link href="/signup">
                <Button variant="accent" size="lg" className="min-w-48 gap-2">
                  {t("cta.button")}
                  <ArrowRight className="h-4 w-4" />
                </Button>
              </Link>
              <Link href="/login">
                <Button
                  variant="outline"
                  size="lg"
                  className="min-w-48 border-white/20 bg-white/5 text-sidebar-fg hover:border-accent/50 hover:bg-white/10 hover:text-white"
                >
                  {t("signIn")}
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
