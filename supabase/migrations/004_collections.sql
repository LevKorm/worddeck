-- Collections table
CREATE TABLE collections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  emoji text NOT NULL DEFAULT '📚',
  color text, -- hex color string, nullable
  description text,
  position int NOT NULL DEFAULT 0,
  is_pinned bool NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Add collection_id to cards (nullable — uncategorized cards are fine)
ALTER TABLE cards ADD COLUMN collection_id uuid REFERENCES collections(id) ON DELETE SET NULL;

-- Indexes
CREATE INDEX idx_collections_user ON collections(user_id);
CREATE INDEX idx_cards_collection ON cards(collection_id);

-- RLS
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own collections" ON collections
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Enforce single pinned collection per user
CREATE OR REPLACE FUNCTION enforce_single_pin() RETURNS trigger AS $$
BEGIN
  IF NEW.is_pinned = true THEN
    UPDATE collections SET is_pinned = false
    WHERE user_id = NEW.user_id AND id != NEW.id AND is_pinned = true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_single_pin
  BEFORE INSERT OR UPDATE ON collections
  FOR EACH ROW EXECUTE FUNCTION enforce_single_pin();
