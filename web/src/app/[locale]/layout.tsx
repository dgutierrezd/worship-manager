import type { Metadata, Viewport } from "next";
import { NextIntlClientProvider, hasLocale } from "next-intl";
import { notFound } from "next/navigation";
import { Providers } from "../providers";
import { routing } from "@/i18n/routing";

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
    <NextIntlClientProvider>
      <Providers>{children}</Providers>
    </NextIntlClientProvider>
  );
}
