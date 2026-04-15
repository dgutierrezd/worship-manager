"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Modal } from "@/components/ui/modal";
import { bandsApi, type UpdateBandInput } from "@/lib/api/bands";
import { useBandStore } from "@/lib/stores/band-store";
import { errorMessage } from "@/lib/utils";
import type { Band } from "@/types";

const EMOJI_PRESETS = ["🎵", "🎶", "🎸", "🎤", "🎹", "🙏", "✝️", "🕊️"];
const COLOR_PRESETS = [
  "#2563EB",
  "#0B1B3B",
  "#0EA5E9",
  "#6366F1",
  "#10B981",
  "#F59E0B",
  "#EF4444",
  "#C9A84C",
];

interface EditBandModalProps {
  open: boolean;
  onClose: () => void;
  band: Band;
}

export function EditBandModal({ open, onClose, band }: EditBandModalProps) {
  const queryClient = useQueryClient();
  const setCurrentBand = useBandStore((s) => s.setCurrentBand);

  const [form, setForm] = useState({
    name: band.name,
    church: band.church ?? "",
    avatar_emoji: band.avatar_emoji || "🎵",
    avatar_color: band.avatar_color || "#2563EB",
  });

  const mutation = useMutation({
    mutationFn: (input: UpdateBandInput) => bandsApi.update(band.id, input),
    onSuccess: (updated) => {
      setCurrentBand(updated);
      queryClient.invalidateQueries({ queryKey: ["bands", "mine"] });
      onClose();
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    mutation.mutate({
      name: form.name.trim(),
      church: form.church.trim() || null,
      avatar_emoji: form.avatar_emoji,
      avatar_color: form.avatar_color,
    });
  };

  return (
    <Modal open={open} onClose={onClose} title="Edit band" size="md">
      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Avatar preview + presets */}
        <div className="flex items-center gap-5">
          <div
            style={{ backgroundColor: form.avatar_color }}
            className="flex h-20 w-20 items-center justify-center rounded-2xl text-4xl shadow-elevated"
          >
            {form.avatar_emoji}
          </div>
          <div className="flex-1 space-y-2">
            <p className="label mb-1">Avatar</p>
            <div className="flex flex-wrap gap-1.5">
              {EMOJI_PRESETS.map((e) => (
                <button
                  key={e}
                  type="button"
                  onClick={() => setForm({ ...form, avatar_emoji: e })}
                  className={`flex h-9 w-9 items-center justify-center rounded-full border text-lg transition ${
                    form.avatar_emoji === e
                      ? "border-accent bg-accent/15"
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
                  onClick={() => setForm({ ...form, avatar_color: c })}
                  style={{ backgroundColor: c }}
                  className={`h-7 w-7 rounded-full border-2 transition ${
                    form.avatar_color === c
                      ? "border-primary"
                      : "border-transparent"
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
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
        />
        <Input
          name="church"
          label="Church"
          value={form.church}
          onChange={(e) => setForm({ ...form, church: e.target.value })}
        />

        {mutation.error && (
          <p className="rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">
            {errorMessage(mutation.error)}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            type="submit"
            variant="accent"
            loading={mutation.isPending}
            disabled={!form.name.trim()}
          >
            Save changes
          </Button>
        </div>
      </form>
    </Modal>
  );
}
