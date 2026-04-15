import Image from "next/image";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { Button } from "@/components/ui/button";
import { Music2, CalendarHeart, Users2, Sparkles } from "lucide-react";

const FEATURES = [
  { key: "library", icon: Music2 },
  { key: "services", icon: CalendarHeart },
  { key: "team", icon: Users2 },
] as const;

export default function WelcomePage() {
  const t = useTranslations("welcome");

  return (
    <div className="relative z-10 mx-auto flex max-w-3xl flex-col items-center text-center animate-fade-in">
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

      <h1 className="font-display text-5xl font-semibold tracking-tight text-white md:text-6xl">
        {t("heroTitle")}{" "}
        <span className="text-accent">{t("heroTitleAccent")}</span>
      </h1>
      <p className="mt-5 max-w-xl text-base text-sidebar-muted md:text-lg">
        {t("heroDescription")}
      </p>

      <div className="mt-10 flex flex-col items-center gap-3 sm:flex-row">
        <Link href="/signup">
          <Button variant="accent" size="lg" className="min-w-44">
            {t("createAccount")}
          </Button>
        </Link>
        <Link href="/login">
          <Button
            variant="outline"
            size="lg"
            className="min-w-44 border-white/20 bg-white/5 text-sidebar-fg hover:border-accent/50 hover:bg-white/10 hover:text-white"
          >
            {t("signIn")}
          </Button>
        </Link>
      </div>

      {/* Feature trio */}
      <div className="mt-20 grid w-full gap-4 sm:grid-cols-3">
        {FEATURES.map(({ key, icon: Icon }) => (
          <div
            key={key}
            className="rounded-2xl border border-white/10 bg-white/5 p-5 text-left backdrop-blur transition hover:border-accent/40 hover:bg-white/10"
          >
            <div className="mb-3 flex h-9 w-9 items-center justify-center rounded-xl bg-accent/20 text-accent">
              <Icon className="h-4 w-4" />
            </div>
            <p className="font-semibold text-sidebar-fg">
              {t(`features.${key}.title`)}
            </p>
            <p className="mt-1 text-sm text-sidebar-muted">
              {t(`features.${key}.description`)}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}
