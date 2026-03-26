-- Add service-specific columns to setlists table
-- These were sent by the iOS app but never stored

ALTER TABLE setlists ADD COLUMN IF NOT EXISTS service_type TEXT;
ALTER TABLE setlists ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE setlists ADD COLUMN IF NOT EXISTS theme TEXT;
ALTER TABLE setlists ADD COLUMN IF NOT EXISTS time TIME;
