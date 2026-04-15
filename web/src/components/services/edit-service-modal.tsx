"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input, Textarea } from "@/components/ui/input";
import { Modal } from "@/components/ui/modal";
import { setlistsApi, type SetlistInput } from "@/lib/api/setlists";
import { errorMessage } from "@/lib/utils";
import type { ServiceType, Setlist } from "@/types";

const SERVICE_TYPES: { value: ServiceType | ""; label: string }[] = [
  { value: "", label: "—" },
  { value: "sunday_morning", label: "Sunday Morning" },
  { value: "sunday_evening", label: "Sunday Evening" },
  { value: "wednesday", label: "Wednesday" },
  { value: "special", label: "Special Event" },
];

interface EditServiceModalProps {
  open: boolean;
  onClose: () => void;
  setlist: Setlist;
  bandId: string;
}

export function EditServiceModal({
  open,
  onClose,
  setlist,
  bandId,
}: EditServiceModalProps) {
  const queryClient = useQueryClient();

  const [form, setForm] = useState({
    name: setlist.name,
    date: setlist.date ?? "",
    time: setlist.time ?? "",
    service_type: setlist.service_type ?? "",
    location: setlist.location ?? "",
    theme: setlist.theme ?? "",
    notes: setlist.notes ?? "",
  });

  const mutation = useMutation({
    mutationFn: (input: Partial<SetlistInput>) =>
      setlistsApi.update(setlist.id, input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["setlists", bandId] });
      onClose();
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    mutation.mutate({
      name: form.name.trim(),
      date: form.date || null,
      time: form.time || null,
      service_type: (form.service_type || null) as ServiceType | null,
      location: form.location.trim() || null,
      theme: form.theme.trim() || null,
      notes: form.notes.trim() || null,
    });
  };

  return (
    <Modal open={open} onClose={onClose} title="Edit service" size="md">
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          name="name"
          label="Service name"
          required
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
        />
        <div className="grid grid-cols-2 gap-3">
          <Input
            name="date"
            type="date"
            label="Date"
            value={form.date}
            onChange={(e) => setForm({ ...form, date: e.target.value })}
          />
          <Input
            name="time"
            type="time"
            label="Time"
            value={form.time}
            onChange={(e) => setForm({ ...form, time: e.target.value })}
          />
        </div>
        <div>
          <label htmlFor="service_type" className="label">
            Service type
          </label>
          <select
            id="service_type"
            value={form.service_type}
            onChange={(e) =>
              setForm({
                ...form,
                service_type: e.target.value as ServiceType | "",
              })
            }
            className="input"
          >
            {SERVICE_TYPES.map((t) => (
              <option key={t.value || "none"} value={t.value}>
                {t.label}
              </option>
            ))}
          </select>
        </div>
        <Input
          name="location"
          label="Location"
          value={form.location}
          onChange={(e) => setForm({ ...form, location: e.target.value })}
        />
        <Input
          name="theme"
          label="Theme"
          value={form.theme}
          onChange={(e) => setForm({ ...form, theme: e.target.value })}
        />
        <Textarea
          name="notes"
          label="Notes"
          rows={3}
          value={form.notes}
          onChange={(e) => setForm({ ...form, notes: e.target.value })}
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
