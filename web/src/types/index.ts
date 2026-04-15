/**
 * Type definitions mirroring the backend API contract and iOS models.
 * Field names follow the snake_case wire format used by the REST API.
 */

export type BandRole = "leader" | "member";

export interface Profile {
  id: string;
  full_name: string;
  avatar_url?: string | null;
  instrument?: string | null;
  language?: string | null;
}

export interface AuthSession {
  access_token: string;
  refresh_token: string;
  expires_at?: number;
}

export interface AuthResponse {
  user: Profile;
  session: AuthSession;
}

export interface Band {
  id: string;
  name: string;
  church?: string | null;
  invite_code: string;
  avatar_color: string;
  avatar_emoji: string;
  avatar_url?: string | null;
  created_by?: string | null;
  created_at?: string | null;
  my_role?: BandRole;
  member_count?: number;
}

export interface Song {
  id: string;
  band_id?: string | null;
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
  created_by?: string | null;
  created_at?: string | null;
  times_used?: number | null;
  last_used_at?: string | null;
}

export type ServiceType =
  | "sunday_morning"
  | "sunday_evening"
  | "wednesday"
  | "special";

export interface Setlist {
  id: string;
  band_id?: string | null;
  name: string;
  date?: string | null;
  time?: string | null;
  notes?: string | null;
  is_template?: boolean;
  service_type?: ServiceType | null;
  location?: string | null;
  theme?: string | null;
  created_by?: string | null;
  created_at?: string | null;
  song_count?: number;
}

export interface SetlistSong {
  id: string;
  setlist_id?: string | null;
  song_id?: string | null;
  position: number;
  key_override?: string | null;
  notes?: string | null;
  songs?: Song | null;
}

export interface Rehearsal {
  id: string;
  band_id?: string | null;
  setlist_id?: string | null;
  title: string;
  location?: string | null;
  scheduled_at: string;
  notes?: string | null;
  created_by?: string | null;
  created_at?: string | null;
  setlists?: { name: string } | null;
}

export type RSVPStatus = "going" | "not_going" | "maybe" | "pending";

export interface RehearsalRSVP {
  rehearsal_id: string;
  user_id: string;
  status: RSVPStatus;
  updated_at?: string;
}

export interface Member {
  id: string;
  full_name: string;
  avatar_url?: string | null;
  instrument?: string | null;
  role: BandRole;
  joined_at?: string | null;
}

export interface ChordSheet {
  id: string;
  song_id: string;
  instrument?: string | null;
  title?: string | null;
  /** JSON-serialized ChordProgression */
  content: string;
  created_at?: string;
}

export type StemKind =
  | "click"
  | "guide"
  | "drums"
  | "bass"
  | "keys"
  | "pad"
  | "vocal"
  | "guitar"
  | "other";

/**
 * A single multitrack stem attached to a song.
 * Audio is NOT hosted by us — `url` points to the user's own cloud
 * (Dropbox, Google Drive, OneDrive, direct web host, etc.).
 */
export interface SongStem {
  id: string;
  song_id: string;
  band_id: string;
  kind: StemKind;
  label: string;
  url: string;
  position?: number | null;
  created_by?: string | null;
  created_at?: string | null;
}

export interface ChordEntry {
  id: string;
  degree: number;
  isPass?: boolean;
  modifier?: string | null;
}

export interface ChordSection {
  id: string;
  name: string;
  chords: ChordEntry[];
}

export interface ChordProgression {
  sections: ChordSection[];
}

/** Generic helper for form mutation error surfaces. */
export interface ApiError {
  error: string;
}
