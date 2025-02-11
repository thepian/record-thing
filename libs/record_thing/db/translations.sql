-- Translations table for storing all localized strings
CREATE TABLE IF NOT EXISTS translations (
    lang VARCHAR NOT NULL,
    key VARCHAR NOT NULL,
    value TEXT NOT NULL,
    context VARCHAR,  -- Optional context like 'product_type', 'document_type', etc.
    -- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (lang, key)
);

-- Create index for faster lookups
-- CREATE INDEX IF NOT EXISTS idx_translations_lang ON translations(lang);

-- Create index for context-based queries
-- CREATE INDEX IF NOT EXISTS idx_translations_context ON translations(context); 
