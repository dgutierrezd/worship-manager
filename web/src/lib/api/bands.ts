import { apiClient } from "@/lib/api/client";
import type { Band } from "@/types";

export interface CreateBandInput {
  name: string;
  church?: string;
  avatar_emoji?: string;
  avatar_color?: string;
}

export interface UpdateBandInput {
  name?: string;
  church?: string | null;
  avatar_emoji?: string;
  avatar_color?: string;
  avatar_url?: string | null;
}

export const bandsApi = {
  listMine: () => apiClient.get<Band[]>("/bands/my"),

  getById: (id: string) => apiClient.get<Band>(`/bands/${id}`),

  create: (input: CreateBandInput) => apiClient.post<Band>("/bands", input),

  join: (code: string) =>
    apiClient.post<Band>("/bands/join", { code: code.toUpperCase() }),

  update: (id: string, input: UpdateBandInput) =>
    apiClient.put<Band>(`/bands/${id}`, input),

  remove: (id: string) => apiClient.delete(`/bands/${id}`),

  regenerateCode: (id: string) =>
    apiClient.post<Band>(`/bands/${id}/regenerate-code`),
};
