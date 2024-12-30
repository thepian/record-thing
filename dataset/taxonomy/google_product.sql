-- Google Product Taxonomy Table
CREATE TABLE google_product_categories (
    category_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT NOT NULL,
    taxonomy_id INTEGER NOT NULL, -- Google's specific taxonomy numeric ID
    full_path TEXT NOT NULL, -- Full category path
    level INTEGER NOT NULL, -- Depth in taxonomy hierarchy
    parent_category_id TEXT,
    is_leaf BOOLEAN DEFAULT 0, -- Whether this is a terminal category
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (parent_category_id) REFERENCES google_product_categories(category_id),
    UNIQUE(account_id, taxonomy_id)
);

-- Mapping table for custom categories to Google Taxonomy
CREATE TABLE category_mappings (
    mapping_id TEXT PRIMARY KEY, -- KSUID
    account_id TEXT NOT NULL,
    local_category_id TEXT NOT NULL,
    google_category_id TEXT NOT NULL,
    confidence_score REAL, -- How confident is the mapping
    mapping_method TEXT, -- 'manual', 'ai', 'auto'
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (local_category_id) REFERENCES categories(category_id),
    FOREIGN KEY (google_category_id) REFERENCES google_product_categories(category_id)
);