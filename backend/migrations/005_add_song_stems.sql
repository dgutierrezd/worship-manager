-- Add song_stems table for multitrack playback
-- Stems are stored as URL references (no audio hosted in our bucket).
-- The user uploads stems to their own cloud (Dropbox, Drive, OneDrive, direct URL)
-- and the app stores only the streaming URL + metadata.

CREATE TABLE IF NOT EXISTS public.song_stems (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  song_id      UUID NOT NULL REFERENCES public.songs(id) ON DELETE CASCADE,
  band_id      UUID NOT NULL REFERENCES public.bands(id) ON DELETE CASCADE,
  kind         TEXT NOT NULL,        -- click | guide | drums | bass | keys | pad | vocal | guitar | other
  label        TEXT NOT NULL,        -- user-facing, e.g. "Electric Guitar L"
  url          TEXT NOT NULL,        -- direct streaming URL
  position     INT NOT NULL DEFAULT 0,
  created_by   UUID REFERENCES auth.users(id),
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS song_stems_song_id_idx ON public.song_stems(song_id);
CREATE INDEX IF NOT EXISTS song_stems_band_id_idx ON public.song_stems(band_id);

ALTER TABLE public.song_stems ENABLE ROW LEVEL SECURITY;

-- Band members can read their band's stems
DROP POLICY IF EXISTS "song_stems_select" ON public.song_stems;
CREATE POLICY "song_stems_select" ON public.song_stems
  FOR SELECT USING (band_id IN (SELECT get_user_band_ids()));

-- Inserts/updates/deletes go through the backend (service role), so no
-- write policies needed for the anon/authenticated roles. The Express
-- backend uses supabaseAdmin which bypasses RLS.
