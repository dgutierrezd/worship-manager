"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Copy, Crown, Users2 } from "lucide-react";
import { useState } from "react";
import { useBandStore } from "@/lib/stores/band-store";
import { membersApi } from "@/lib/api/members";
import { PageHeader } from "@/components/ui/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { SkeletonList } from "@/components/ui/skeleton";
import { errorMessage } from "@/lib/utils";
import type { BandRole } from "@/types";

export default function MembersPage() {
  const band = useBandStore((s) => s.currentBand);
  const bandId = band?.id ?? "";
  const queryClient = useQueryClient();
  const [copied, setCopied] = useState(false);

  const query = useQuery({
    queryKey: ["members", bandId],
    queryFn: () => membersApi.list(bandId),
    enabled: !!bandId,
  });

  const removeMutation = useMutation({
    mutationFn: (userId: string) => membersApi.remove(bandId, userId),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ["members", bandId] }),
  });

  const roleMutation = useMutation({
    mutationFn: ({ userId, role }: { userId: string; role: BandRole }) =>
      membersApi.changeRole(bandId, userId, role),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ["members", bandId] }),
  });

  if (!band) return null;

  const canManage = band.my_role === "leader";

  const copyCode = async () => {
    await navigator.clipboard.writeText(band.invite_code);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <div className="animate-fade-in">
      <PageHeader
        eyebrow="Team"
        title="Members"
        description="Everyone who plays with your band."
      />

      {/* Invite card */}
      <div className="mb-8 flex flex-col gap-4 rounded-2xl border border-divider bg-surface p-6 shadow-card md:flex-row md:items-center md:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-widest text-secondary">
            Invite code
          </p>
          <p className="mt-1 font-mono text-3xl font-semibold text-primary tracking-widest">
            {band.invite_code}
          </p>
          <p className="mt-1 text-xs text-secondary">
            Share this with teammates so they can join.
          </p>
        </div>
        <Button variant="outline" onClick={copyCode}>
          <Copy className="h-4 w-4" />
          {copied ? "Copied!" : "Copy code"}
        </Button>
      </div>

      {query.isLoading ? (
        <SkeletonList count={4} />
      ) : !query.data || query.data.length === 0 ? (
        <EmptyState
          icon={Users2}
          title="No members yet"
          description="Share the invite code to bring your team on board."
        />
      ) : (
        <div className="space-y-3">
          {query.data.map((m) => (
            <div
              key={m.id}
              className="flex items-center justify-between gap-4 rounded-2xl border border-divider bg-surface p-4 shadow-card"
            >
              <div className="flex min-w-0 items-center gap-4">
                <div className="flex h-11 w-11 items-center justify-center rounded-full bg-accent/15 font-semibold text-accent">
                  {m.full_name?.[0] ?? "?"}
                </div>
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="truncate font-semibold text-primary">
                      {m.full_name}
                    </p>
                    {m.role === "leader" && (
                      <Badge variant="accent">
                        <Crown className="h-3 w-3" /> Leader
                      </Badge>
                    )}
                  </div>
                  {m.instrument && (
                    <p className="text-xs text-secondary">{m.instrument}</p>
                  )}
                </div>
              </div>

              {canManage && m.id !== band.created_by && (
                <div className="flex items-center gap-2">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() =>
                      roleMutation.mutate({
                        userId: m.id,
                        role: m.role === "leader" ? "member" : "leader",
                      })
                    }
                  >
                    {m.role === "leader" ? "Make member" : "Promote"}
                  </Button>
                  <Button
                    variant="danger"
                    size="sm"
                    onClick={() => {
                      if (confirm(`Remove ${m.full_name} from ${band.name}?`)) {
                        removeMutation.mutate(m.id);
                      }
                    }}
                  >
                    Remove
                  </Button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {(removeMutation.error || roleMutation.error) && (
        <p className="mt-4 rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
          {errorMessage(removeMutation.error ?? roleMutation.error)}
        </p>
      )}
    </div>
  );
}
