import { defineRouting } from "next-intl/routing";

/**
 * Locale configuration shared by the middleware, the `[locale]` segment,
 * and any component that needs locale-aware navigation.
 *
 * Spanish is the primary language of the product; new visitors default
 * to Spanish regardless of the `accept-language` header. Users can
 * switch from Settings → Language (see `LocaleSwitcher`).
 */
export const routing = defineRouting({
  locales: ["es", "en"] as const,
  defaultLocale: "es",
  // Strategy:
  //  - "as-needed": the default locale (/es) has NO prefix → "/" shows Spanish,
  //     "/en" shows English. This keeps clean URLs for the primary audience.
  localePrefix: "as-needed",
  // Honour the user's last pick by cookie; if none, stick to defaultLocale
  // instead of guessing from the browser. This is what the user asked for:
  // "Spanish is the main language; they can opt in to English."
  localeDetection: false,
});

export type Locale = (typeof routing.locales)[number];
