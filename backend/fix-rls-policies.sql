-- ═══════════════════════════════════════════
-- Fix: Infinite recursion in RLS policies
-- ═══════════════════════════════════════════
-- The band_members SELECT policy referenced band_members itself,
-- causing infinite recursion. This fix uses a SECURITY DEFINER
-- function to safely fetch the user's band IDs without triggering RLS.
--
-- Run this in your Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- ═══════════════════════════════════════════

-- Step 1: Create helper function (bypasses RLS to avoid recursion)
CREATE OR REPLACE FUNCTION get_user_band_ids()
RETURNS SETOF UUID AS $$
  SELECT band_id FROM public.band_members WHERE user_id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public;

-- Step 2: Drop ALL existing policies that reference band_members subquery
DROP POLICY IF EXISTS "View band members" ON band_members;
DROP POLICY IF EXISTS "Join band" ON band_members;
DROP POLICY IF EXISTS "Member band access" ON bands;
DROP POLICY IF EXISTS "Leader manages band" ON bands;
DROP POLICY IF EXISTS "Member can view songs" ON songs;
DROP POLICY IF EXISTS "Member can insert songs" ON songs;
DROP POLICY IF EXISTS "Member can update songs" ON songs;
DROP POLICY IF EXISTS "Member can view chords" ON chord_sheets;
DROP POLICY IF EXISTS "Member can manage chords" ON chord_sheets;
DROP POLICY IF EXISTS "Member can view setlists" ON setlists;
DROP POLICY IF EXISTS "Member can insert setlists" ON setlists;
DROP POLICY IF EXISTS "Member can view setlist songs" ON setlist_songs;
DROP POLICY IF EXISTS "Member can view rehearsals" ON rehearsals;
DROP POLICY IF EXISTS "Member can insert rehearsals" ON rehearsals;
DROP POLICY IF EXISTS "Member can view RSVPs" ON rehearsal_rsvps;
DROP POLICY IF EXISTS "User can manage own RSVP" ON rehearsal_rsvps;

-- Step 3: Recreate policies using the safe helper function

-- Band Members
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

-- Bands
CREATE POLICY "Member band access" ON bands
  FOR SELECT USING (id IN (SELECT get_user_band_ids()));
CREATE POLICY "Anyone can read band by invite code" ON bands
  FOR SELECT USING (true);
CREATE POLICY "Leader manages band" ON bands
  FOR ALL USING (created_by = auth.uid());

-- Songs
CREATE POLICY "Member can view songs" ON songs
  FOR SELECT USING (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can insert songs" ON songs
  FOR INSERT WITH CHECK (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can update songs" ON songs
  FOR UPDATE USING (band_id IN (SELECT get_user_band_ids()));
CREATE POLICY "Member can delete songs" ON songs
  FOR DELETE USING (band_id IN (SELECT get_user_band_ids()));

-- Chord Sheets
CREATE POLICY "Member can view chords" ON chord_sheets
  FOR SELECT USING (
    song_id IN (SELECT id FROM songs WHERE band_id IN (SELECT get_user_band_ids()))
  );
CREATE POLICY "Member can manage chords" ON chord_sheets
  FOR ALL USING (created_by = auth.uid());

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
