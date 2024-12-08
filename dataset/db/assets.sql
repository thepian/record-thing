CREATE TABLE IF NOT EXISTS clip_assets (
    account TEXT,
    id TEXT, 
    product_id TEXT,
    dino_vec_rowid INTEGER,
    sha1 TEXT,
    name TEXT,
    tags TEXT,
    category TEXT,
    scanned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (account, id)
);

CREATE VIRTUAL TABLE IF NOT EXISTS dino_embedding USING vec0(
    asset_id TEXT PRIMARY KEY,
    sha1 TEXT,
    url TEXT,
    embedding float[768]
);
