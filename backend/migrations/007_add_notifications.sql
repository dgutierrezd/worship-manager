-- 007_add_notifications.sql
-- Persistent notification inbox. Every push fan-out also writes one row
-- per recipient here so the iOS app can render the user's full history,
-- including notifications that arrived while the device was offline.

CREATE TABLE IF NOT EXISTS notifications (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  band_id     UUID REFERENCES bands(id) ON DELETE CASCADE,
  kind        TEXT NOT NULL CHECK (kind IN ('service', 'rehearsal', 'system')),
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  -- For deep-linking. Holds the setlist_id when kind='service', the
  -- rehearsal_id when kind='rehearsal', null otherwise.
  entity_id   UUID,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notifications_user_created_idx
  ON notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS notifications_user_unread_idx
  ON notifications(user_id) WHERE read_at IS NULL;

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Each user can read and update only their own notifications.
CREATE POLICY "Users read own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users mark own notifications read"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
