-- Migration: Add lyrics, tags, and theme columns to songs table
-- Run this in your Supabase SQL Editor → https://supabase.com/dashboard/project/_/sql

ALTER TABLE songs
  ADD COLUMN IF NOT EXISTS lyrics TEXT,
  ADD COLUMN IF NOT EXISTS tags   TEXT[],
  ADD COLUMN IF NOT EXISTS theme  TEXT;
