"use client";

import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { bandsApi } from "@/lib/api/bands";
import { useBandStore } from "@/lib/stores/band-store";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/ui/page-header";
import { errorMessage } from "@/lib/utils";

export default function JoinBandPage() {
  const router = useRouter();
  const setCurrentBand = useBandStore((s) => s.setCurrentBand);
  const queryClient = useQueryClient();
  const [code, setCode] = useState("");

  const mutation = useMutation({
    mutationFn: () => bandsApi.join(code.trim()),
    onSuccess: (band) => {
      setCurrentBand(band);
      queryClient.invalidateQueries({ queryKey: ["bands", "mine"] });
      router.replace("/home");
    },
  });

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    mutation.mutate();
  };

  return (
    <div className="mx-auto max-w-xl animate-fade-in">
      <PageHeader
        eyebrow="Onboarding"
        title="Join a band"
        description="Enter the 6-character invite code from your band leader."
      />

      <form
        onSubmit={onSubmit}
        className="space-y-6 rounded-3xl border border-divider bg-surface p-8 shadow-card"
      >
        <Input
          name="code"
          label="Invite code"
          required
          maxLength={6}
          placeholder="ABC123"
          value={code}
          onChange={(e) => setCode(e.target.value.toUpperCase())}
          className="text-center font-mono text-2xl tracking-[0.5em]"
        />

        {mutation.error && (
          <p className="rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
            {errorMessage(mutation.error)}
          </p>
        )}

        <div className="flex justify-end gap-2">
          <Button type="button" variant="ghost" onClick={() => router.back()}>
            Cancel
          </Button>
          <Button
            type="submit"
            variant="accent"
            loading={mutation.isPending}
            disabled={code.trim().length !== 6}
          >
            Join band
          </Button>
        </div>
      </form>
    </div>
  );
}
