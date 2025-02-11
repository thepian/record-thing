-- universe table
CREATE TABLE IF NOT EXISTS universe (
    id INTEGER PRIMARY KEY,
    url TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    version VARCHAR,
    date TIMESTAMP,
    checksum TEXT,
    checksum_type TEXT,
    is_downloaded BOOLEAN DEFAULT FALSE,
    is_installed BOOLEAN DEFAULT FALSE,
    is_running BOOLEAN DEFAULT FALSE,
    is_paused BOOLEAN DEFAULT FALSE,
    is_stopped BOOLEAN DEFAULT FALSE,
    is_failed BOOLEAN DEFAULT FALSE,
    is_completed BOOLEAN DEFAULT FALSE,
    is_cancelled BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    enabled_menus TEXT,  -- JSON array
    enabled_features TEXT, -- JSON array
    flags TEXT -- JSON object
);

-- things table
CREATE TABLE IF NOT EXISTS things (
    id TEXT NOT NULL DEFAULT '',  -- KSUID
    account_id TEXT NOT NULL DEFAULT '',
    upc TEXT NULL DEFAULT NULL, -- Universal Product Code
    asin TEXT NULL DEFAULT NULL, -- Amazon Standard Identification Number
    elid TEXT NULL DEFAULT NULL, -- Electronic Product Identifier
    brand TEXT NULL DEFAULT NULL, -- Brand name
    model TEXT NULL DEFAULT NULL, -- Model name or number
    color TEXT NULL DEFAULT NULL, -- Color name or code
    tags TEXT NULL DEFAULT NULL, -- Tags
    category TEXT NULL DEFAULT NULL, -- Category name
    product_type INTEGER NULL DEFAULT NULL,
    document_type INTEGER NULL DEFAULT NULL,
    title TEXT NULL DEFAULT NULL, -- Title of the thing
    description TEXT NULL DEFAULT NULL, -- Description of the thing
    -- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (account_id, id)
    -- , FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);


-- Requests table
CREATE TABLE IF NOT EXISTS requests (
    id INTEGER PRIMARY KEY,
    url TEXT UNIQUE NOT NULL,
    universe_id INTEGER,
    status TEXT NOT NULL,  -- e.g., 'pending', 'completed'
    -- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- completed_at TIMESTAMP,
    delivery_method TEXT, -- 'email' or 'http_post'
    delivery_target TEXT -- email address or URL
    -- , FOREIGN KEY (universe_id) REFERENCES universe(id)
);


-- Evidence table
CREATE TABLE IF NOT EXISTS evidence (
    id TEXT PRIMARY KEY,  -- KSUID
    thing_account_id TEXT,
    thing_id TEXT,
    request_id INTEGER,
    -- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    product_type INTEGER,
    document_type INTEGER,
    data TEXT, -- JSON object containing evidence data
    local_file TEXT -- Path to local file (.jpg or .png), starts with '/images/
    -- , FOREIGN KEY (thing_account_id, thing_id) REFERENCES things(account_id, id),
    -- FOREIGN KEY (request_id) REFERENCES requests(id)
);

-- Create indexes for better query performance
-- CREATE INDEX IF NOT EXISTS idx_things_account ON things(account_id);
-- CREATE INDEX IF NOT EXISTS idx_evidence_thing ON evidence(thing_account_id, thing_id);
-- CREATE INDEX IF NOT EXISTS idx_evidence_request ON evidence(request_id);

-- CREATE INDEX IF NOT EXISTS idx_universe_name ON universe(name);

-- CREATE INDEX IF NOT EXISTS idx_producttype_name ON product_type(name);
-- CREATE INDEX IF NOT EXISTS idx_documenttype_name ON document_type(name);
