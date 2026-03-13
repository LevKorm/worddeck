-- Migration: add native-language enrichment columns to cards table
-- Run in Supabase SQL editor or via: supabase db push

ALTER TABLE cards
  ADD COLUMN IF NOT EXISTS example_sentence_native text,
  ADD COLUMN IF NOT EXISTS synonyms_native         text[],
  ADD COLUMN IF NOT EXISTS usage_notes_native      text;
