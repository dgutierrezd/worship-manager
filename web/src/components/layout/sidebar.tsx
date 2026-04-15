"use client";

import Image from "next/image";
import { useTranslations } from "next-intl";
import { Link, usePathname, useRouter } from "@/i18n/navigation";
import {
  CalendarDays,
  Home,
  LogOut,
  Music2,
  Settings,
  Users,
  ListMusic,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/lib/stores/auth-store";
import { useBandStore } from "@/lib/stores/band-store";
import { BandAvatar } from "@/components/ui/band-avatar";
import { authApi } from "@/lib/api/auth";

const NAV_ITEMS = [
  { href: "/home", key: "home", icon: Home },
  { href: "/services", key: "services", icon: ListMusic },
  { href: "/songs", key: "songs", icon: Music2 },
  { href: "/rehearsals", key: "rehearsals", icon: CalendarDays },
  { href: "/members", key: "team", icon: Users },
  { href: "/settings", key: "settings", icon: Settings },
] as const;

export function Sidebar() {
  const t = useTranslations("nav");
  const tc = useTranslations("common");
  const pathname = usePathname();
  const profile = useAuthStore((s) => s.profile);
  const signOutStore = useAuthStore((s) => s.signOut);
  const currentBand = useBandStore((s) => s.currentBand);
  const router = useRouter();

  const handleSignOut = async () => {
    try {
      await authApi.signOut();
    } finally {
      signOutStore();
      router.replace("/login");
    }
  };

  return (
    <aside className="sticky top-0 flex h-screen w-64 shrink-0 flex-col bg-sidebar-gradient text-sidebar-fg">
      {/* Brand */}
      <Link
        href="/home"
        className="flex items-center gap-3 px-6 py-6 transition hover:opacity-90"
      >
        <div className="relative h-10 w-10 overflow-hidden rounded-2xl bg-white ring-1 ring-white/10 shadow-accentGlow">
          <Image
            src="/logo-mark.png"
            alt="Worship Manager"
            width={80}
            height={80}
            priority
            className="h-full w-full object-cover"
          />
        </div>
        <div className="leading-tight">
          <p className="font-display text-base font-semibold text-sidebar-fg">
            Worship
          </p>
          <p className="font-display text-base font-semibold text-accent">
            Manager
          </p>
        </div>
      </Link>

      {/* Current band card */}
      {currentBand && (
        <Link
          href="/home"
          className="group mx-4 mb-6 flex items-center gap-3 rounded-2xl border border-sidebar-divider bg-sidebar-panel/80 p-3 transition hover:border-accent/50 hover:bg-sidebar-panel"
        >
          <BandAvatar band={currentBand} size={40} />
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-semibold text-sidebar-fg">
              {currentBand.name}
            </p>
            {currentBand.church ? (
              <p className="truncate text-xs text-sidebar-muted">
                {currentBand.church}
              </p>
            ) : (
              <p className="truncate text-xs text-sidebar-muted">
                {currentBand.my_role === "leader" ? tc("leader") : tc("member")}
              </p>
            )}
          </div>
        </Link>
      )}

      {/* Nav */}
      <nav className="flex-1 space-y-1 px-3">
        {NAV_ITEMS.map((item) => {
          const active =
            pathname === item.href || pathname.startsWith(`${item.href}/`);
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "group relative flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition",
                active
                  ? "bg-white/5 text-sidebar-fg"
                  : "text-sidebar-muted hover:bg-white/5 hover:text-sidebar-fg",
              )}
            >
              {/* Active indicator pill */}
              <span
                aria-hidden
                className={cn(
                  "absolute left-0 top-1/2 h-6 w-1 -translate-y-1/2 rounded-r-full bg-accent transition-opacity",
                  active ? "opacity-100" : "opacity-0",
                )}
              />
              <Icon
                className={cn(
                  "h-4 w-4 transition",
                  active
                    ? "text-accent"
                    : "text-sidebar-muted group-hover:text-sidebar-fg",
                )}
              />
              {t(item.key)}
            </Link>
          );
        })}
      </nav>

      {/* Profile footer */}
      <div className="border-t border-sidebar-divider p-4">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-accent/20 text-sm font-semibold text-accent ring-1 ring-accent/30">
            {profile?.full_name?.[0] ?? "?"}
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-semibold text-sidebar-fg">
              {profile?.full_name ?? tc("signedIn")}
            </p>
            {profile?.instrument && (
              <p className="truncate text-xs text-sidebar-muted">
                {profile.instrument}
              </p>
            )}
          </div>
          <button
            type="button"
            aria-label={t("signOutAria")}
            onClick={handleSignOut}
            className="rounded-full p-1.5 text-sidebar-muted transition hover:bg-white/5 hover:text-danger"
          >
            <LogOut className="h-4 w-4" />
          </button>
        </div>
      </div>
    </aside>
  );
}
