-- Add avatar_url column to bands table
ALTER TABLE bands ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Create storage bucket for band avatars (run in Supabase Dashboard > Storage)
-- Bucket name: band-avatars
-- Public: true
