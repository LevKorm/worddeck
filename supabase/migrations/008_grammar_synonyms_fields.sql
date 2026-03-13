-- Add grammar, enriched synonyms, multiple examples/usage notes
ALTER TABLE cards ADD COLUMN IF NOT EXISTS grammar jsonb;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS synonyms_enriched jsonb;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS example_sentences text[];
ALTER TABLE cards ADD COLUMN IF NOT EXISTS usage_notes_list text[];
