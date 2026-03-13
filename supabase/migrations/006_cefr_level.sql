-- 006_cefr_level.sql
-- Adds CEFR difficulty level column to cards table.
-- Values: A1, A2, B1, B2, C1, C2 (nullable — existing cards have no level)

ALTER TABLE cards
  ADD COLUMN IF NOT EXISTS cefr_level text
    CHECK (cefr_level IN ('A1','A2','B1','B2','C1','C2'));
