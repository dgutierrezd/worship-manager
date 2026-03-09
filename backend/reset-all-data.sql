-- WorshipFlow: FULL DATA RESET
-- Run this in Supabase Dashboard → SQL Editor
-- This deletes ALL data and ALL users to start fresh

-- 1. Delete all data from tables (in order to respect FK constraints)
TRUNCATE TABLE rehearsal_rsvps CASCADE;
TRUNCATE TABLE device_tokens CASCADE;
TRUNCATE TABLE setlist_songs CASCADE;
TRUNCATE TABLE chord_sheets CASCADE;
TRUNCATE TABLE rehearsals CASCADE;
TRUNCATE TABLE setlists CASCADE;
TRUNCATE TABLE songs CASCADE;
TRUNCATE TABLE band_members CASCADE;
TRUNCATE TABLE bands CASCADE;
TRUNCATE TABLE profiles CASCADE;

-- 2. Delete ALL auth users
DELETE FROM auth.users;

-- Done! All users and data have been wiped clean.
