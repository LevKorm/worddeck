-- Add language tracking fields to cards table.
-- word_lang: language code for the `word` column (learning language, e.g. 'EN')
-- translation_lang: language code for the `translation` column (native language, e.g. 'UK')
--
-- Convention: `word` is ALWAYS the learning language, `translation` is ALWAYS
-- the native/fluent language. Enrichment content is about the learning-language word.

ALTER TABLE cards ADD COLUMN IF NOT EXISTS word_lang text;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS translation_lang text;
