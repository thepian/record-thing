-- Enhanced Accounts Table with Passkey Support
CREATE TABLE IF NOT EXISTS accounts (
    account_id TEXT PRIMARY KEY, -- KSUID
    name TEXT,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    sms TEXT UNIQUE, 
    region TEXT, -- e.g., 'US', 'EU', 'APAC' for legal compliance
    password_hash TEXT, -- Optional, for backward compatibility
    -- registration_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1
    -- , last_login DATETIME
);

-- The account_id used to create new data on this node
CREATE TABLE IF NOT EXISTS owners (
    account_id TEXT PRIMARY KEY -- KSUID
    -- , created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

