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
    -- created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- last_used DATETIME,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Authentication Attempts Logging
CREATE TABLE IF NOT EXISTS authentication_attempts (
    attempt_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT,
    -- attempt_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
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
    -- first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- last_seen DATETIME,
    is_trusted BOOLEAN DEFAULT 0,
    device_identifier TEXT UNIQUE, -- Unique device fingerprint
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Indexes for performance and security
CREATE INDEX idx_passkey_account ON passkey_credentials(account_id);
CREATE INDEX idx_auth_attempts_account ON authentication_attempts(account_id);
CREATE INDEX idx_trusted_devices_account ON trusted_devices(account_id);
