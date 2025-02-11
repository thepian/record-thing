CREATE VIRTUAL TABLE IF NOT EXISTS dino_embedding USING vec0(
    asset_id TEXT PRIMARY KEY,
    sha1 TEXT,
    url TEXT,
    embedding float[768]
);

