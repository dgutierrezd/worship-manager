-- Migration 008: Create Supabase Storage bucket for uploaded stem audio files
-- Run this in the Supabase SQL Editor (or via the dashboard Storage panel).
--
-- The bucket is public so that the generated URLs can be streamed directly by
-- the browser-based multitrack player without auth headers.
-- File-size limit: 200 MB per stem (large uncompressed WAV stems can be big).

-- file_size_limit uses the project-level default (NULL = no extra cap on top of plan limit)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'song-stems',
  'song-stems',
  true,
  NULL,
  ARRAY[
    'audio/mpeg',
    'audio/wav',
    'audio/x-wav',
    'audio/mp4',
    'audio/m4a',
    'audio/aac',
    'audio/ogg',
    'audio/flac',
    'audio/x-flac',
    'audio/webm'
  ]
)
ON CONFLICT (id) DO UPDATE
  SET public            = EXCLUDED.public,
      file_size_limit   = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Storage RLS: any authenticated user can upload to a path that starts with
-- their own song's id (validated server-side via signed URL generation).
-- Anyone can read (download) since the bucket is public.
