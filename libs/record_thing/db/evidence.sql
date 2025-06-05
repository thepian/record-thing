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
    evidence_type INTEGER NULL DEFAULT NULL,
    evidence_type_name TEXT NULL DEFAULT NULL, -- full name of the evidence type
    title TEXT NULL DEFAULT NULL, -- Title of the thing
    description TEXT NULL DEFAULT NULL, -- Description of the thing
    -- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at FLOAT NULL DEFAULT NULL,
    updated_at FLOAT NULL DEFAULT NULL,
    PRIMARY KEY (account_id, id)
    -- , FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);


-- Requests table
CREATE TABLE IF NOT EXISTS requests (
    id INTEGER PRIMARY KEY,
    account_id TEXT NOT NULL DEFAULT '',
    url TEXT UNIQUE NOT NULL, -- The URL is used to identify the request
    universe_id INTEGER,
    type TEXT NOT NULL, -- What process does the request belong to?
    data TEXT, -- JSON object containing request data
    status TEXT NOT NULL,  -- e.g., 'pending', 'completed'
    -- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- completed_at TIMESTAMP,
    created_at FLOAT NULL DEFAULT NULL,
    completed_at FLOAT NULL DEFAULT NULL,
    delivery_method TEXT, -- 'email' or 'http_post'
    delivery_target TEXT -- email address or URL
    -- , FOREIGN KEY (universe_id) REFERENCES universe(id)
);


-- Strategists table (Thepia Strategist knowledge base)
CREATE TABLE IF NOT EXISTS strategists (
    id TEXT NOT NULL DEFAULT '',  -- KSUID
    account_id TEXT NOT NULL DEFAULT '',
    title TEXT NULL DEFAULT NULL, -- Title/name of the strategic focus area
    description TEXT NULL DEFAULT NULL, -- Description of the strategic area
    tags TEXT NULL DEFAULT NULL, -- JSON array of tags
    created_at FLOAT NULL DEFAULT NULL,
    updated_at FLOAT NULL DEFAULT NULL,
    PRIMARY KEY (account_id, id)
    -- , FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Evidence table
CREATE TABLE IF NOT EXISTS evidence (
    id TEXT PRIMARY KEY,  -- KSUID
    thing_account_id TEXT,
    thing_id TEXT,
    request_id INTEGER,
    strategist_account_id TEXT,
    strategist_id TEXT,
    -- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at FLOAT NULL DEFAULT NULL,
    updated_at FLOAT NULL DEFAULT NULL,
    evidence_type INTEGER,
    data TEXT, -- JSON object containing evidence data
    local_file TEXT -- Path to local file (.jpg or .png), starts with '/images/
    -- , FOREIGN KEY (thing_account_id, thing_id) REFERENCES things(account_id, id),
    -- FOREIGN KEY (request_id) REFERENCES requests(id),
    -- FOREIGN KEY (strategist_account_id, strategist_id) REFERENCES strategists(account_id, id)
);


-- I want to set up a new feed table. It will be used to show the main feed for a user in the app. A feed entry can be a Thing, a Request, an Event, a single piece of evidence, or a Chat. I want to track read, clickthrough and relevant metrics. It will link to a single record in other tables with an account_id, a uid/id and a table name. What fields should it include, and are there additional considerations for tracking.

CREATE TABLE IF NOT EXISTS feed (
    id INTEGER PRIMARY KEY,
    account_id TEXT NOT NULL,
    
    -- Content Reference
    content_table TEXT NOT NULL,  -- 'things', 'request', 'event', 'evidence', 'chat'
    content_id TEXT NOT NULL,    -- UUID or ID from the referenced table
    content_title TEXT,          -- Denormalized title for quick access
    content_preview TEXT,        -- Short preview/summary
    content_image_url TEXT,      -- Optional preview image
    
    -- Metadata
    -- -- created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- -- updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- published_at DATETIME,       -- When it should appear in feed
    -- expires_at DATETIME,         -- Optional expiration
    priority INTEGER DEFAULT 0,  -- For feed ordering
    
    -- Engagement Metrics
    view_count INTEGER DEFAULT 0,
    click_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    last_viewed_at DATETIME,
    last_interaction_at DATETIME,
    
    -- User-specific Status
    is_read BOOLEAN DEFAULT FALSE,
    is_hidden BOOLEAN DEFAULT FALSE,
    is_bookmarked BOOLEAN DEFAULT FALSE,
    user_action TEXT          -- 'like', 'save', 'hide', etc.
    
    -- Indexing
    -- , UNIQUE(account_id, content_type, content_id)
);

-- Index for efficient feed queries
-- CREATE INDEX idx_feed_account_date ON feed(account_id, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_feed_content ON feed(content_table, content_id);


-- Create indexes for better query performance
-- CREATE INDEX IF NOT EXISTS idx_things_account ON things(account_id);
-- CREATE INDEX IF NOT EXISTS idx_evidence_thing ON evidence(thing_account_id, thing_id);
-- CREATE INDEX IF NOT EXISTS idx_evidence_request ON evidence(request_id);

-- CREATE INDEX IF NOT EXISTS idx_universe_name ON universe(name);

-- CREATE INDEX IF NOT EXISTS idx_producttype_name ON product_type(name);
-- CREATE INDEX IF NOT EXISTS idx_documenttype_name ON document_type(name);
