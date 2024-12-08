-- Enhanced Accounts Table with Passkey Support
CREATE TABLE IF NOT EXISTS accounts (
    id TEXT PRIMARY KEY, -- KSUID
    name TEXT,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    sms TEXT UNIQUE, 
    region TEXT, -- e.g., 'US', 'EU', 'APAC' for legal compliance
    password_hash TEXT, -- Optional, for backward compatibility
    registration_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1,
    last_login DATETIME
);

-- The account_id used to create new data on this node
CREATE TABLE IF NOT EXISTS owners (
    account_id TEXT PRIMARY KEY, -- KSUID
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Passkey Credentials Table
CREATE TABLE IF NOT EXISTS passkey_credentials (
    credential_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT NOT NULL,
    credential_name TEXT, -- User-friendly name for the credential
    public_key BLOB NOT NULL, -- Store the public key
    credential_id_hash TEXT NOT NULL UNIQUE, -- Unique identifier from WebAuthn
    attestation_type TEXT, -- e.g., 'packed', 'tpm', 'android-key'
    authenticator_aaguid TEXT, -- Authenticator Attestation GUID
    backup_eligible BOOLEAN DEFAULT 0,
    backup_state BOOLEAN DEFAULT 0,
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_used DATETIME,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Authentication Attempts Logging
CREATE TABLE IF NOT EXISTS authentication_attempts (
    attempt_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT,
    attempt_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_successful BOOLEAN,
    authentication_method TEXT, -- 'passkey', 'password', etc.
    ip_address TEXT,
    user_agent TEXT,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Device Trust Table
CREATE TABLE IF NOT EXISTS trusted_devices (
    device_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT NOT NULL,
    device_name TEXT,
    device_type TEXT,
    first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen DATETIME,
    is_trusted BOOLEAN DEFAULT 0,
    device_identifier TEXT UNIQUE, -- Unique device fingerprint
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Indexes for performance and security
CREATE INDEX idx_accounts_email ON accounts(email);
CREATE INDEX idx_passkey_account ON passkey_credentials(account_id);
CREATE INDEX idx_auth_attempts_account ON authentication_attempts(account_id);
CREATE INDEX idx_trusted_devices_account ON trusted_devices(account_id);