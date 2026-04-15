import type { Metadata, Viewport } from "next";
import { Inter, JetBrains_Mono, Space_Grotesk } from "next/font/google";
import { NextIntlClientProvider, hasLocale } from "next-intl";
import { notFound } from "next/navigation";
import { Providers } from "../providers";
import { routing } from "@/i18n/routing";
import "../globals.css";

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-sans",
});

const spaceGrotesk = Space_Grotesk({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-display",
});

const jetbrains = JetBrains_Mono({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-mono",
});

export const metadata: Metadata = {
  title: {
    default: "Worship Manager",
    template: "%s · Worship Manager",
  },
  description:
    "Plan services, manage your song library, and coordinate your worship team.",
  applicationName: "Worship Manager",
  authors: [{ name: "Worship Manager" }],
  openGraph: {
    title: "Worship Manager",
    description:
      "Plan services, manage your song library, and coordinate your worship team.",
    siteName: "Worship Manager",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Worship Manager",
    description:
      "Plan services, manage your song library, and coordinate your worship team.",
  },
};

export const viewport: Viewport = {
  themeColor: "#0B1B3B",
  colorScheme: "light",
};

/**
 * Tell Next which locale segments to pre-render. Anything outside
 * `routing.locales` returns a 404.
 */
export function generateStaticParams() {
  return routing.locales.map((locale) => ({ locale }));
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!hasLocale(routing.locales, locale)) notFound();

  return (
    <html
      lang={locale}
      className={`${inter.variable} ${spaceGrotesk.variable} ${jetbrains.variable}`}
    >
      <body>
        <NextIntlClientProvider>
          <Providers>{children}</Providers>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
