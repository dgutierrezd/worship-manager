-- 006_add_setlist_rsvps.sql
-- Adds RSVP tracking to services (setlists), mirroring the existing
-- rehearsal_rsvps table. Lets band members confirm/decline attendance
-- to a scheduled service the same way they do for rehearsals.

CREATE TABLE IF NOT EXISTS setlist_rsvps (
  setlist_id UUID REFERENCES setlists(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status     TEXT DEFAULT 'pending'
             CHECK (status IN ('going', 'not_going', 'maybe', 'pending')),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (setlist_id, user_id)
);

ALTER TABLE setlist_rsvps ENABLE ROW LEVEL SECURITY;

-- Any band member can read RSVPs for setlists in their bands.
CREATE POLICY "Members can view setlist RSVPs"
  ON setlist_rsvps FOR SELECT
  USING (
    setlist_id IN (
      SELECT id FROM setlists WHERE band_id IN (SELECT get_user_band_ids())
    )
  );

-- Each user can manage only their own RSVP row.
CREATE POLICY "Users manage own setlist RSVP"
  ON setlist_rsvps FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
