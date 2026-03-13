-- Migration 005: Language Spaces
-- Creates the spaces table and adds space_id FK to cards and card_feed_content.
-- Apply in Supabase dashboard BEFORE deploying the Flutter update.

CREATE TABLE spaces (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  native_language   text NOT NULL,
  learning_language text NOT NULL,
  display_order     int  NOT NULL DEFAULT 0,
  created_at        timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, native_language, learning_language)
);

ALTER TABLE spaces ENABLE ROW LEVEL SECURITY;
CREATE POLICY "spaces_owner" ON spaces
  FOR ALL USING (auth.uid() = user_id);

-- Add nullable space_id to cards (backfilled later)
ALTER TABLE cards ADD COLUMN space_id uuid REFERENCES spaces(id) ON DELETE CASCADE;
CREATE INDEX idx_cards_space_id ON cards(space_id);

-- Add nullable space_id to card_feed_content
ALTER TABLE card_feed_content ADD COLUMN space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
CREATE INDEX idx_feed_space_id ON card_feed_content(space_id);

-- Add active_space_id to user_settings
ALTER TABLE user_settings ADD COLUMN active_space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;

-- Backfill: create a default space for each user who has cards,
-- using their user_settings languages (falling back to UK/EN)
INSERT INTO spaces (id, user_id, native_language, learning_language, display_order)
SELECT
  gen_random_uuid(),
  c.user_id,
  COALESCE(us.native_language, 'UK'),
  COALESCE(us.learning_language, 'EN'),
  0
FROM (SELECT DISTINCT user_id FROM cards) c
LEFT JOIN user_settings us ON us.user_id = c.user_id
ON CONFLICT (user_id, native_language, learning_language) DO NOTHING;

-- Backfill cards
UPDATE cards SET space_id = (
  SELECT s.id FROM spaces s WHERE s.user_id = cards.user_id ORDER BY s.display_order LIMIT 1
) WHERE space_id IS NULL;

-- Backfill card_feed_content
UPDATE card_feed_content SET space_id = (
  SELECT s.id FROM spaces s WHERE s.user_id = card_feed_content.user_id ORDER BY s.display_order LIMIT 1
) WHERE space_id IS NULL;

-- Set active_space_id in user_settings to the default space
UPDATE user_settings SET active_space_id = (
  SELECT s.id FROM spaces s WHERE s.user_id = user_settings.user_id ORDER BY s.display_order LIMIT 1
) WHERE active_space_id IS NULL;
