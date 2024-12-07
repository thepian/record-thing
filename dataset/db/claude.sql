-- Enhanced Accounts Table with Passkey Support
CREATE TABLE IF NOT EXISTS accounts (
    account_id TEXT PRIMARY KEY, -- KSUID
    username TEXT NOT NULL UNIQUE,
    email TEXT UNIQUE,
    password_hash TEXT, -- Optional, for backward compatibility
    registration_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1,
    last_login DATETIME
);

- Passkey Credentials Table
CREATE TABLE passkey_credentials (
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
CREATE TABLE authentication_attempts (
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
CREATE TABLE trusted_devices (
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
CREATE INDEX idx_passkey_account ON passkey_credentials(account_id);
CREATE INDEX idx_auth_attempts_account ON authentication_attempts(account_id);
CREATE INDEX idx_trusted_devices_account ON trusted_devices(account_id);


-- Categories Table
CREATE TABLE categories (
    category_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT NOT NULL,
    category_name TEXT NOT NULL,
    parent_category_id TEXT,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id),
    UNIQUE(account_id, category_name)
);

-- Manufacturers Table
CREATE TABLE manufacturers (
    manufacturer_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT NOT NULL,
    name TEXT NOT NULL,
    website TEXT,
    country TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    UNIQUE(account_id, name)
);

-- Products Master Table
CREATE TABLE products (
    product_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT NOT NULL,
    barcode TEXT,
    product_name TEXT NOT NULL,
    manufacturer_id TEXT,
    category_id TEXT,
    description TEXT,
    model_number TEXT,
    weight REAL,
    dimensions TEXT,
    msrp REAL,
    web_scrape_info TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (manufacturer_id) REFERENCES manufacturers(manufacturer_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    UNIQUE(account_id, barcode),
    UNIQUE(account_id, product_name, model_number)
);

-- Personal Inventory Table
CREATE TABLE user_items (
    item_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    purchase_date DATE,
    purchase_price REAL,
    purchase_location TEXT,
    condition TEXT,
    warranty_expiration DATE,
    serial_number TEXT,
    notes TEXT,
    is_insured BOOLEAN DEFAULT 0,
    acquisition_method TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Image Storage Table (with Vector Embeddings)
CREATE TABLE item_images (
    image_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT NOT NULL,
    item_id TEXT NOT NULL,
    image_path TEXT NOT NULL,
    is_public BOOLEAN DEFAULT 0,
    image_type TEXT, -- 'original', 'user_added', 'web_scraped'
    vector_embedding BLOB, -- Storing vector embedding for image recognition
    upload_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (item_id) REFERENCES user_items(item_id)
);

-- Web Scrape Metadata Table
CREATE TABLE web_scrape_metadata (
    scrape_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    source_url TEXT,
    scraped_data TEXT,
    scrape_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Indexes for performance
CREATE INDEX idx_accounts_email ON accounts(email);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_user_items_product ON user_items(account_id, product_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_manufacturer ON products(manufacturer_id);
CREATE INDEX idx_images_item ON item_images(item_id);