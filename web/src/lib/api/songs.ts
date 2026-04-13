import { apiClient } from "@/lib/api/client";
import type { ChordSheet, Song, SongStem, StemKind } from "@/types";

export interface BulkSongInput {
  title: string;
  artist?: string | null;
}

export interface SongInput {
  title: string;
  artist?: string | null;
  default_key?: string | null;
  tempo_bpm?: number | null;
  duration_sec?: number | null;
  notes?: string | null;
  lyrics?: string | null;
  tags?: string[] | null;
  theme?: string | null;
  youtube_url?: string | null;
  spotify_url?: string | null;
}

export interface StemInput {
  kind: StemKind;
  label: string;
  url: string;
  position?: number;
}

export interface StemPatch {
  kind?: StemKind;
  label?: string;
  url?: string;
  position?: number;
}

export const songsApi = {
  list: (bandId: string) => apiClient.get<Song[]>(`/bands/${bandId}/songs`),

  create: (bandId: string, input: SongInput) =>
    apiClient.post<Song>(`/bands/${bandId}/songs`, input),

  update: (bandId: string, songId: string, input: Partial<SongInput>) =>
    apiClient.put<Song>(`/bands/${bandId}/songs/${songId}`, input),

  remove: (bandId: string, songId: string) =>
    apiClient.delete(`/bands/${bandId}/songs/${songId}`),

  listChords: (songId: string) =>
    apiClient.get<ChordSheet[]>(`/songs/${songId}/chords`),

  createChordSheet: (
    songId: string,
    input: { content: string; title?: string; instrument?: string },
  ) => apiClient.post<ChordSheet>(`/songs/${songId}/chords`, input),

  updateChordSheet: (
    chordSheetId: string,
    input: { content?: string; title?: string; instrument?: string },
  ) => apiClient.put<ChordSheet>(`/chords/${chordSheetId}`, input),

  /** Bulk-create songs from a list of titles (and optional artists). */
  bulkCreate: (bandId: string, songs: BulkSongInput[]) =>
    apiClient.post<{ songs: Song[] }>(`/bands/${bandId}/songs/bulk`, {
      songs,
    }),

  // Multitracks (stems)
  listStems: (songId: string) =>
    apiClient.get<SongStem[]>(`/songs/${songId}/stems`),

  addStem: (songId: string, input: StemInput) =>
    apiClient.post<SongStem>(`/songs/${songId}/stems`, input),

  updateStem: (songId: string, stemId: string, patch: StemPatch) =>
    apiClient.patch<SongStem>(`/songs/${songId}/stems/${stemId}`, patch),

  removeStem: (songId: string, stemId: string) =>
    apiClient.delete(`/songs/${songId}/stems/${stemId}`),
};
