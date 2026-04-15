"use client";

import { useTransition } from "react";
import { useLocale, useTranslations } from "next-intl";
import { usePathname, useRouter } from "@/i18n/navigation";
import { routing, type Locale } from "@/i18n/routing";
import { cn } from "@/lib/utils";

/**
 * Segmented control that switches the active UI language. Uses the
 * locale-aware router so the current route is preserved across languages.
 * The chosen locale is persisted in the `NEXT_LOCALE` cookie by next-intl
 * automatically, so subsequent visits remember the pick.
 */
export function LocaleSwitcher() {
  const t = useTranslations("settings.language");
  const locale = useLocale() as Locale;
  const router = useRouter();
  const pathname = usePathname();
  const [isPending, startTransition] = useTransition();

  const onSelect = (next: Locale) => {
    if (next === locale) return;
    startTransition(() => {
      router.replace(pathname, { locale: next });
    });
  };

  return (
    <div
      role="radiogroup"
      aria-label={t("title")}
      className="inline-flex rounded-xl border border-divider bg-surfaceMuted p-1"
    >
      {routing.locales.map((l) => {
        const active = l === locale;
        const label = l === "es" ? t("spanish") : t("english");
        return (
          <button
            key={l}
            type="button"
            role="radio"
            aria-checked={active}
            disabled={isPending}
            onClick={() => onSelect(l)}
            className={cn(
              "min-w-[6rem] rounded-lg px-4 py-1.5 text-sm font-semibold transition",
              active
                ? "bg-surface text-primary shadow-sm"
                : "text-secondary hover:text-primary",
              isPending && "opacity-60",
            )}
          >
            {label}
          </button>
        );
      })}
    </div>
  );
}
