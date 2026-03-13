-- Add lineage tracking fields so synonym cards can link back to their parent.
ALTER TABLE cards ADD COLUMN IF NOT EXISTS parent_card_id uuid REFERENCES cards(id) ON DELETE SET NULL;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS parent_word text;
