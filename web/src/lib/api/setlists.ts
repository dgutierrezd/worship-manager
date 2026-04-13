import { apiClient } from "@/lib/api/client";
import type { RSVPStatus, ServiceType, Setlist, SetlistSong } from "@/types";

export interface SetlistInput {
  name: string;
  date?: string | null;
  time?: string | null;
  notes?: string | null;
  is_template?: boolean;
  service_type?: ServiceType | null;
  location?: string | null;
  theme?: string | null;
}

export interface SetlistRSVPRow {
  setlist_id: string;
  status: RSVPStatus;
}

/** Attendance roster entry returned by GET /<entity>/:id/rsvps. */
export interface AttendanceRSVP {
  user_id: string;
  status: RSVPStatus;
  updated_at: string | null;
  profiles: {
    full_name: string | null;
    avatar_url: string | null;
    instrument: string | null;
  } | null;
}

export const setlistsApi = {
  list: (bandId: string) =>
    apiClient.get<Setlist[]>(`/bands/${bandId}/setlists`),

  create: (bandId: string, input: SetlistInput) =>
    apiClient.post<Setlist>(`/bands/${bandId}/setlists`, input),

  update: (setlistId: string, input: Partial<SetlistInput>) =>
    apiClient.put<Setlist>(`/setlists/${setlistId}`, input),

  remove: (setlistId: string) => apiClient.delete(`/setlists/${setlistId}`),

  listSongs: (setlistId: string) =>
    apiClient.get<SetlistSong[]>(`/setlists/${setlistId}/songs`),

  addSong: (
    setlistId: string,
    input: { song_id: string; key_override?: string; notes?: string },
  ) => apiClient.post<SetlistSong>(`/setlists/${setlistId}/songs`, input),

  removeSong: (setlistId: string, songId: string) =>
    apiClient.delete(`/setlists/${setlistId}/songs/${songId}`),

  reorder: (setlistId: string, positions: { id: string; position: number }[]) =>
    apiClient.patch(`/setlists/${setlistId}/songs/reorder`, { positions }),

  // RSVPs (services / setlists)
  myRsvps: (bandId: string) =>
    apiClient.get<SetlistRSVPRow[]>(`/setlists/my-rsvps?band_id=${bandId}`),

  rsvp: (setlistId: string, status: RSVPStatus) =>
    apiClient.post<SetlistRSVPRow>(`/setlists/${setlistId}/rsvp`, { status }),

  rsvps: (setlistId: string) =>
    apiClient.get<AttendanceRSVP[]>(`/setlists/${setlistId}/rsvps`),
};
