-- Enhanced Accounts Table with Passkey Support
CREATE TABLE
    IF NOT EXISTS accounts (
        account_id TEXT PRIMARY KEY, -- KSUID
        name TEXT,
        username TEXT UNIQUE,
        email TEXT UNIQUE,
        sms TEXT UNIQUE,
        region TEXT, -- e.g., 'US', 'EU', 'APAC' for legal compliance
        password_hash TEXT, -- Optional, for backward compatibility
        -- registration_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        team_id TEXT, -- KSUID (defaults to demo-team-id)
        avatar TEXT, -- URL or base64-encoded image
        is_active BOOLEAN DEFAULT 1,
        created_at FLOAT DEFAULT 0.0, -- Unix timestamp
        updated_at FLOAT DEFAULT 0.0, -- Unix timestamp
        last_login FLOAT DEFAULT 0.0 -- Unix timestamp
    );

-- The account_id used to create new data on this node
CREATE TABLE
    IF NOT EXISTS owners (
        account_id TEXT PRIMARY KEY -- KSUID
        -- , created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE
    IF NOT EXISTS teams (
        team_id TEXT PRIMARY KEY, -- KSUID
        name TEXT,
        region TEXT, -- e.g., 'US', 'EU', 'APAC' for legal compliance
        tier TEXT, -- e.g., 'free', 'premium', 'enterprise'
        is_demo BOOLEAN DEFAULT 0,
        is_active BOOLEAN DEFAULT 1,
        storage_domain TEXT, -- e.g., 'example.com'
        storage_bucket_name TEXT, -- e.g., 'example-bucket' 
        storage_bucket_region TEXT, -- e.g., 'us-west-1'
        fallback_domain TEXT, -- e.g., 'example.com'
        fallback_bucket_name TEXT, -- e.g., 'example-bucket'
        fallback_bucket_region TEXT, -- e.g., 'us-west-1'
        created_at FLOAT DEFAULT 0.0, -- Unix timestamp
        updated_at FLOAT DEFAULT 0.0 -- Unix timestamp
    );