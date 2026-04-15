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

const EMOJI_PRESETS = ["🎵", "🎶", "🎸", "🎤", "🎹", "🙏", "✝️", "🕊️"];
const COLOR_PRESETS = [
  "#2563EB", // brand blue
  "#0B1B3B", // deep navy
  "#0EA5E9", // sky
  "#6366F1", // indigo
  "#10B981", // emerald
  "#F59E0B", // amber
  "#EF4444", // red
  "#C9A84C", // legacy gold (matches iOS default)
];

export default function CreateBandPage() {
  const router = useRouter();
  const setCurrentBand = useBandStore((s) => s.setCurrentBand);
  const queryClient = useQueryClient();

  const [name, setName] = useState("");
  const [church, setChurch] = useState("");
  const [emoji, setEmoji] = useState("🎵");
  const [color, setColor] = useState("#2563EB");

  const mutation = useMutation({
    mutationFn: () =>
      bandsApi.create({
        name: name.trim(),
        church: church.trim() || undefined,
        avatar_emoji: emoji,
        avatar_color: color,
      }),
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
        title="Create a band"
        description="Set up a space for your worship team."
      />

      <form
        onSubmit={onSubmit}
        className="space-y-6 rounded-3xl border border-divider bg-surface p-8 shadow-card"
      >
        <div className="flex items-center gap-5">
          <div
            style={{ backgroundColor: color }}
            className="flex h-20 w-20 items-center justify-center rounded-2xl text-4xl shadow-elevated"
          >
            {emoji}
          </div>
          <div className="flex-1 space-y-2">
            <p className="label mb-1">Avatar</p>
            <div className="flex flex-wrap gap-1.5">
              {EMOJI_PRESETS.map((e) => (
                <button
                  key={e}
                  type="button"
                  onClick={() => setEmoji(e)}
                  className={`flex h-9 w-9 items-center justify-center rounded-full border text-lg transition ${
                    emoji === e
                      ? "border-accent bg-accent/20"
                      : "border-divider hover:bg-surfaceMuted"
                  }`}
                >
                  {e}
                </button>
              ))}
            </div>
            <div className="flex flex-wrap gap-1.5">
              {COLOR_PRESETS.map((c) => (
                <button
                  key={c}
                  type="button"
                  onClick={() => setColor(c)}
                  style={{ backgroundColor: c }}
                  className={`h-7 w-7 rounded-full border-2 transition ${
                    color === c ? "border-primary" : "border-transparent"
                  }`}
                  aria-label={`Use color ${c}`}
                />
              ))}
            </div>
          </div>
        </div>

        <Input
          name="name"
          label="Band name"
          required
          placeholder="e.g. Grace Worship Team"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <Input
          name="church"
          label="Church (optional)"
          placeholder="e.g. Grace Community Church"
          value={church}
          onChange={(e) => setChurch(e.target.value)}
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
            disabled={!name.trim()}
          >
            Create band
          </Button>
        </div>
      </form>
    </div>
  );
}
