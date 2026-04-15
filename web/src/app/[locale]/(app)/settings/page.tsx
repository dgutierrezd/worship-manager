"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useTranslations } from "next-intl";
import { LogOut, Pencil, Plus, RefreshCcw, Trash2 } from "lucide-react";
import { Link, useRouter } from "@/i18n/navigation";
import { authApi } from "@/lib/api/auth";
import { bandsApi } from "@/lib/api/bands";
import { useAuthStore } from "@/lib/stores/auth-store";
import { useBandStore } from "@/lib/stores/band-store";
import { PageHeader } from "@/components/ui/page-header";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { BandAvatar } from "@/components/ui/band-avatar";
import { Skeleton } from "@/components/ui/skeleton";
import { EditBandModal } from "@/components/bands/edit-band-modal";
import { LocaleSwitcher } from "@/components/layout/locale-switcher";
import { errorMessage } from "@/lib/utils";
import type { Band } from "@/types";

export default function SettingsPage() {
  const t = useTranslations("settings");
  const tc = useTranslations("common");
  const router = useRouter();
  const profile = useAuthStore((s) => s.profile);
  const signOutStore = useAuthStore((s) => s.signOut);
  const currentBand = useBandStore((s) => s.currentBand);
  const setCurrentBand = useBandStore((s) => s.setCurrentBand);
  const queryClient = useQueryClient();
  const [editingBand, setEditingBand] = useState<Band | null>(null);

  const bandsQuery = useQuery({
    queryKey: ["bands", "mine"],
    queryFn: bandsApi.listMine,
  });

  const regenMutation = useMutation({
    mutationFn: (id: string) => bandsApi.regenerateCode(id),
    onSuccess: (band) => {
      setCurrentBand(band);
      queryClient.invalidateQueries({ queryKey: ["bands", "mine"] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => bandsApi.remove(id),
    onSuccess: () => {
      setCurrentBand(null);
      queryClient.invalidateQueries({ queryKey: ["bands", "mine"] });
    },
  });

  const handleSignOut = async () => {
    try {
      await authApi.signOut();
    } finally {
      signOutStore();
      router.replace("/login");
    }
  };

  return (
    <div className="animate-fade-in space-y-8">
      <PageHeader
        eyebrow={t("eyebrow")}
        title={t("title")}
        description={t("description")}
      />

      {/* Profile */}
      <section className="rounded-2xl border border-divider bg-surface p-6 shadow-card">
        <h2 className="mb-4 font-display text-xl font-semibold text-primary">
          {t("profile")}
        </h2>
        <div className="flex items-center gap-4">
          <div className="flex h-14 w-14 items-center justify-center rounded-full bg-accent/15 text-xl font-semibold text-accent">
            {profile?.full_name?.[0] ?? "?"}
          </div>
          <div>
            <p className="font-semibold text-primary">
              {profile?.full_name ?? "—"}
            </p>
            {profile?.instrument && (
              <p className="text-sm text-secondary">{profile.instrument}</p>
            )}
          </div>
        </div>
      </section>

      {/* Language */}
      <section className="rounded-2xl border border-divider bg-surface p-6 shadow-card">
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 className="font-display text-xl font-semibold text-primary">
              {t("language.title")}
            </h2>
            <p className="mt-1 text-sm text-secondary">
              {t("language.description")}
            </p>
          </div>
          <LocaleSwitcher />
        </div>
      </section>

      {/* Bands */}
      <section className="rounded-2xl border border-divider bg-surface p-6 shadow-card">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="font-display text-xl font-semibold text-primary">
            {t("bands")}
          </h2>
          <div className="flex items-center gap-2">
            <Link href="/bands/join">
              <Button variant="outline" size="sm">
                {t("joinBand")}
              </Button>
            </Link>
            <Link href="/bands/create">
              <Button variant="accent" size="sm">
                <Plus className="h-4 w-4" /> {t("createBand")}
              </Button>
            </Link>
          </div>
        </div>

        {bandsQuery.isLoading ? (
          <div className="space-y-2">
            <Skeleton className="h-14" />
            <Skeleton className="h-14" />
          </div>
        ) : (
          <div className="space-y-2">
            {(bandsQuery.data ?? []).map((b) => {
              const isActive = currentBand?.id === b.id;
              return (
                <div
                  key={b.id}
                  className="flex items-center justify-between gap-4 rounded-xl border border-divider p-4"
                >
                  <button
                    type="button"
                    onClick={() => setCurrentBand(b)}
                    className="flex min-w-0 flex-1 items-center gap-3 text-left"
                  >
                    <BandAvatar band={b} size={40} />
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="truncate font-semibold text-primary">
                          {b.name}
                        </p>
                        {isActive && (
                          <Badge variant="accent">{tc("active")}</Badge>
                        )}
                      </div>
                      {b.church && (
                        <p className="truncate text-xs text-secondary">
                          {b.church}
                        </p>
                      )}
                    </div>
                  </button>
                  {b.my_role === "leader" && (
                    <div className="flex items-center gap-1">
                      <button
                        type="button"
                        aria-label={t("editBandAria")}
                        onClick={() => setEditingBand(b)}
                        className="rounded-full p-2 text-secondary hover:bg-surfaceMuted hover:text-primary"
                      >
                        <Pencil className="h-4 w-4" />
                      </button>
                      <button
                        type="button"
                        aria-label={t("regenerateCodeAria")}
                        onClick={() => regenMutation.mutate(b.id)}
                        className="rounded-full p-2 text-secondary hover:bg-surfaceMuted hover:text-primary"
                      >
                        <RefreshCcw className="h-4 w-4" />
                      </button>
                      <button
                        type="button"
                        aria-label={t("deleteBandAria")}
                        onClick={() => {
                          if (confirm(t("confirmDelete", { name: b.name }))) {
                            deleteMutation.mutate(b.id);
                          }
                        }}
                        className="rounded-full p-2 text-secondary hover:bg-danger/10 hover:text-danger"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {(regenMutation.error || deleteMutation.error) && (
          <p className="mt-4 rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
            {errorMessage(regenMutation.error ?? deleteMutation.error)}
          </p>
        )}
      </section>

      {/* Sign out */}
      <section>
        <Button variant="outline" onClick={handleSignOut}>
          <LogOut className="h-4 w-4" /> {tc("signOut")}
        </Button>
      </section>

      {editingBand && (
        <EditBandModal
          open={!!editingBand}
          onClose={() => setEditingBand(null)}
          band={editingBand}
        />
      )}
    </div>
  );
}
