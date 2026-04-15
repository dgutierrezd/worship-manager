import { apiClient } from "@/lib/api/client";
import type { BandRole, Member } from "@/types";

export const membersApi = {
  list: (bandId: string) =>
    apiClient.get<Member[]>(`/bands/${bandId}/members`),

  remove: (bandId: string, userId: string) =>
    apiClient.delete(`/bands/${bandId}/members/${userId}`),

  changeRole: (bandId: string, userId: string, role: BandRole) =>
    apiClient.patch(`/bands/${bandId}/members/${userId}`, { role }),
};
