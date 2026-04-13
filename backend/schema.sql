-- WorshipFlow Database Schema
-- Run this in your Supabase SQL Editor

-- Profiles (extends Supabase Auth)
CREATE TABLE profiles (
  id          UUID REFERENCES auth.users PRIMARY KEY,
  full_name   TEXT NOT NULL,
  avatar_url  TEXT,
  instrument  TEXT,
  language    TEXT DEFAULT 'en' CHECK (language IN ('en', 'es')),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Bands
CREATE TABLE bands (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name          TEXT NOT NULL,
  church        TEXT,
  invite_code   CHAR(6) NOT NULL UNIQUE,
  avatar_color  TEXT DEFAULT '#1C1C1E',
  avatar_emoji  TEXT DEFAULT '🎸',
  avatar_url    TEXT,
  created_by    UUID REFERENCES profiles(id),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Band Members (junction)
CREATE TABLE band_members (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  band_id    UUID REFERENCES bands(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role       TEXT DEFAULT 'member' CHECK (role IN ('leader', 'member')),
  instrument TEXT,
  joined_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(band_id, user_id)
);

-- Song Library (shared per band)
CREATE TABLE songs (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  band_id      UUID REFERENCES bands(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  artist       TEXT,
  default_key  TEXT,
  tempo_bpm    INT,
  duration_sec INT,
  notes        TEXT,
  lyrics       TEXT,
  tags         TEXT[],
  theme        TEXT,
  youtube_url  TEXT,
  spotify_url  TEXT,
  created_by   UUID REFERENCES profiles(id),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Chord Sheets per song
CREATE TABLE chord_sheets (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  song_id     UUID REFERENCES songs(id) ON DELETE CASCADE,
  instrument  TEXT,
  title       TEXT DEFAULT 'Chord Sheet',
  content     TEXT NOT NULL,
  created_by  UUID REFERENCES profiles(id),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Song Stems (multitracks) — stored as URL references (no audio hosted in our bucket)
CREATE TABLE song_stems (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  song_id     UUID REFERENCES songs(id) ON DELETE CASCADE,
  band_id     UUID REFERENCES bands(id) ON DELETE CASCADE,
  kind        TEXT NOT NULL, -- click|guide|drums|bass|keys|pad|vocal|guitar|other
  label       TEXT NOT NULL,
  url         TEXT NOT NULL,
  position    INT NOT NULL DEFAULT 0,
  created_by  UUID REFERENCES auth.users(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX song_stems_song_id_idx ON song_stems(song_id);
CREATE INDEX song_stems_band_id_idx ON song_stems(band_id);

-- Setlists
CREATE TABLE setlists (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  band_id       UUID REFERENCES bands(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  date          DATE,
  time          TIME,
  notes         TEXT,
  is_template   BOOLEAN DEFAULT FALSE,
  service_type  TEXT,
  location      TEXT,
  theme         TEXT,
  created_by    UUID REFERENCES profiles(id),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Songs inside a setlist (ordered)
CREATE TABLE setlist_songs (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  setlist_id   UUID REFERENCES setlists(id) ON DELETE CASCADE,
  song_id      UUID REFERENCES songs(id) ON DELETE CASCADE,
  position     INT NOT NULL,
  key_override TEXT,
  notes        TEXT,
  UNIQUE(setlist_id, position)
);

-- Rehearsals
CREATE TABLE rehearsals (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  band_id      UUID REFERENCES bands(id) ON DELETE CASCADE,
  setlist_id   UUID REFERENCES setlists(id) ON DELETE SET NULL,
  title        TEXT NOT NULL,
  location     TEXT,
  scheduled_at TIMESTAMPTZ NOT NULL,
  notes        TEXT,
  created_by   UUID REFERENCES profiles(id),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Rehearsal RSVPs
CREATE TABLE rehearsal_rsvps (
  rehearsal_id UUID REFERENCES rehearsals(id) ON DELETE CASCADE,
  user_id      UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status       TEXT DEFAULT 'pending' CHECK (status IN ('going', 'not_going', 'maybe', 'pending')),
  updated_at   TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (rehearsal_id, user_id)
);

-- Setlist (service) RSVPs — same shape as rehearsal_rsvps
CREATE TABLE setlist_rsvps (
  setlist_id UUID REFERENCES setlists(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status     TEXT DEFAULT 'pending' CHECK (status IN ('going', 'not_going', 'maybe', 'pending')),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (setlist_id, user_id)
);

-- Device tokens for push notifications
CREATE TABLE device_tokens (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    UUID REFERENCES profiles(id) ON DELETE CASCADE,
  token      TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════
-- Row Level Security
-- ═══════════════════════════════════════════

ALTER TABLE profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE bands             ENABLE ROW LEVEL SECURITY;
ALTER TABLE band_members      ENABLE ROW LEVEL SECURITY;
ALTER TABLE songs             ENABLE ROW LEVEL SECURITY;
ALTER TABLE chord_sheets      ENABLE ROW LEVEL SECURITY;
ALTER TABLE song_stems        ENABLE ROW LEVEL SECURITY;
ALTER TABLE setlists          ENABLE ROW LEVEL SECURITY;
ALTER TABLE setlist_songs     ENABLE ROW LEVEL SECURITY;
ALTER TABLE rehearsals        ENABLE ROW LEVEL SECURITY;
ALTER TABLE rehearsal_rsvps   ENABLE ROW LEVEL SECURITY;
ALTER TABLE setlist_rsvps     ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens     ENABLE ROW LEVEL SECURITY;

-- Helper function: safely gets user's band IDs without triggering RLS recursion
CREATE OR REPLACE FUNCTION get_user_band_ids()
RETURNS SETOF UUID AS $$
  SELECT band_id FROM public.band_members WHERE user_id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public;

-- Profiles: users can read/update their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (id = auth.uid());
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (id = auth.uid());
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (id = auth.uid());

-- Bands: members can view their bands
CREATE POLICY "Member band access" ON bands
  FOR SELECT USING (id IN (SELECT get_user_band_ids()));
CREATE POLICY "Anyone can read band by invite code" ON bands
  FOR SELECT USING (true);
CREATE POLICY "Leader manages band" ON bands
  FOR ALL USING (created_by = auth.uid());

-- Band Members: uses function to avoid self-referencing recursion
CREATE POLICY "View band members" ON band_members
  FOR SELECT USING (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Join band" ON band_members
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Leader removes members" ON band_members
  FOR DELETE USING (
    band_id IN (
      SELECT band_id FROM public.band_members
      WHERE user_id = auth.uid() AND role = 'leader'
    )
  );

-- Songs: band members can CRUD
CREATE POLICY "Member can view songs" ON songs
  FOR SELECT USING (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can insert songs" ON songs
  FOR INSERT WITH CHECK (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can update songs" ON songs
  FOR UPDATE USING (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can delete songs" ON songs
  FOR DELETE USING (band_id IN (SELECT get_user_band_ids()));

-- Chord Sheets: accessible if song's band is accessible
CREATE POLICY "Member can view chords" ON chord_sheets
  FOR SELECT USING (
    song_id IN (SELECT id FROM songs WHERE band_id IN (SELECT get_user_band_ids()))
  );
CREATE POLICY "Member can manage chords" ON chord_sheets
  FOR ALL USING (created_by = auth.uid());

-- Song Stems (multitracks): readable by band members; writes go through backend
CREATE POLICY "Member can view stems" ON song_stems
  FOR SELECT USING (band_id IN (SELECT get_user_band_ids()));

-- Setlists
CREATE POLICY "Member can view setlists" ON setlists
  FOR SELECT USING (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can insert setlists" ON setlists
  FOR INSERT WITH CHECK (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can update setlists" ON setlists
  FOR UPDATE USING (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can delete setlists" ON setlists
  FOR DELETE USING (band_id IN (SELECT get_user_band_ids()));

-- Setlist Songs
CREATE POLICY "Member can view setlist songs" ON setlist_songs
  FOR SELECT USING (
    setlist_id IN (SELECT id FROM setlists WHERE band_id IN (SELECT get_user_band_ids()))
  );
CREATE POLICY "Member can manage setlist songs" ON setlist_songs
  FOR ALL USING (
    setlist_id IN (SELECT id FROM setlists WHERE band_id IN (SELECT get_user_band_ids()))
  );

-- Rehearsals
CREATE POLICY "Member can view rehearsals" ON rehearsals
  FOR SELECT USING (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can insert rehearsals" ON rehearsals
  FOR INSERT WITH CHECK (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can update rehearsals" ON rehearsals
  FOR UPDATE USING (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can delete rehearsals" ON rehearsals
  FOR DELETE USING (band_id IN (SELECT get_user_band_ids()));

-- RSVPs
CREATE POLICY "Member can view RSVPs" ON rehearsal_rsvps
  FOR SELECT USING (
    rehearsal_id IN (SELECT id FROM rehearsals WHERE band_id IN (SELECT get_user_band_ids()))
  );
CREATE POLICY "User can manage own RSVP" ON rehearsal_rsvps
  FOR ALL USING (user_id = auth.uid());

-- Device Tokens
CREATE POLICY "User manages own tokens" ON device_tokens
  FOR ALL USING (user_id = auth.uid());

-- ═══════════════════════════════════════════
-- Auto-create profile on signup trigger
-- ═══════════════════════════════════════════

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
