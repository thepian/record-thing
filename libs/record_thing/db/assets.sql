CREATE TABLE IF NOT EXISTS clip_assets (
    account_id TEXT,
    id TEXT, 
    product_id TEXT,
    dino_vec_rowid INTEGER,
    sha1 TEXT,
    name TEXT,
    tags TEXT,
    category TEXT,
    -- scanned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (account_id, id)
);

CREATE TABLE IF NOT EXISTS image_assets (
    path TEXT PRIMARY KEY, -- More versions can be found in the asset bucket treating this a folder path
    alt_url TEXT,
    original_url TEXT,
    sha1 TEXT,
    md5 TEXT,
    iconic_png BLOB
);