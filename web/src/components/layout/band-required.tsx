"use client";

import { useEffect, useState, type ReactNode } from "react";
import { useQuery } from "@tanstack/react-query";
import { useTranslations } from "next-intl";
import { Music2 } from "lucide-react";
import { Link, usePathname } from "@/i18n/navigation";
import { bandsApi } from "@/lib/api/bands";
import { useBandStore } from "@/lib/stores/band-store";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { SkeletonList } from "@/components/ui/skeleton";

/**
 * Ensures the user has at least one band, and auto-selects it into the
 * band store. Shows an onboarding empty state if they have none.
 */
export function BandRequired({ children }: { children: ReactNode }) {
  const t = useTranslations("bandRequired");
  const currentBand = useBandStore((s) => s.currentBand);
  const setCurrentBand = useBandStore((s) => s.setCurrentBand);
  const pathname = usePathname();
  const [checked, setChecked] = useState(false);

  // Allow band-onboarding routes to render even with no band yet.
  const isOnboardingRoute =
    pathname.startsWith("/bands/create") || pathname.startsWith("/bands/join");

  const query = useQuery({
    queryKey: ["bands", "mine"],
    queryFn: bandsApi.listMine,
  });

  useEffect(() => {
    if (!query.data) return;
    // If we don't have one selected, or the stored one is no longer in
    // our band list, fall back to the first band.
    if (
      !currentBand ||
      !query.data.some((b) => b.id === currentBand.id)
    ) {
      setCurrentBand(query.data[0] ?? null);
    }
    setChecked(true);
  }, [query.data, currentBand, setCurrentBand]);

  if (isOnboardingRoute) return <>{children}</>;

  if (query.isLoading || !checked) {
    return (
      <div className="p-10">
        <SkeletonList count={3} />
      </div>
    );
  }

  if (query.isError) {
    return (
      <div className="p-10">
        <EmptyState
          icon={Music2}
          title={t("loadErrorTitle")}
          description={(query.error as Error).message}
        />
      </div>
    );
  }

  if (!query.data || query.data.length === 0) {
    return (
      <div className="p-10">
        <EmptyState
          icon={Music2}
          title={t("welcomeTitle")}
          description={t("welcomeDescription")}
          action={
            <div className="flex flex-wrap items-center gap-2">
              <Link href="/bands/create">
                <Button variant="accent">{t("createBand")}</Button>
              </Link>
              <Link href="/bands/join">
                <Button variant="outline">{t("joinWithCode")}</Button>
              </Link>
            </div>
          }
        />
      </div>
    );
  }

  return <>{children}</>;
}
