import { apiClient } from "@/lib/api/client";
import type { Rehearsal, RSVPStatus } from "@/types";
import type { AttendanceRSVP } from "@/lib/api/setlists";

export interface RehearsalInput {
  title: string;
  scheduled_at: string; // ISO 8601
  location?: string | null;
  notes?: string | null;
  setlist_id?: string | null;
}

export const rehearsalsApi = {
  list: (bandId: string) =>
    apiClient.get<Rehearsal[]>(`/bands/${bandId}/rehearsals`),

  create: (bandId: string, input: RehearsalInput) =>
    apiClient.post<Rehearsal>(`/bands/${bandId}/rehearsals`, input),

  update: (rehearsalId: string, input: Partial<RehearsalInput>) =>
    apiClient.put<Rehearsal>(`/rehearsals/${rehearsalId}`, input),

  remove: (rehearsalId: string) =>
    apiClient.delete(`/rehearsals/${rehearsalId}`),

  rsvp: (rehearsalId: string, status: RSVPStatus) =>
    apiClient.post(`/rehearsals/${rehearsalId}/rsvp`, { status }),

  rsvps: (rehearsalId: string) =>
    apiClient.get<AttendanceRSVP[]>(`/rehearsals/${rehearsalId}/rsvps`),
};
