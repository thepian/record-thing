-- agreements table
CREATE TABLE IF NOT EXISTS agreements (
    id INTEGER PRIMARY KEY,
    account_id TEXT NOT NULL DEFAULT '',
    url TEXT UNIQUE NOT NULL,  -- URL to identify the agreement
    universe_id INTEGER,
    type TEXT NOT NULL,  -- e.g., 'insurance', 'lease', 'purchase'
    status TEXT NOT NULL,  -- e.g., 'active', 'expired', 'pending_renewal'
    
    -- Time validity
    -- start_date DATETIME,
    -- end_date DATETIME,
    -- renewal_date DATETIME,
    
    -- Agreement details
    title TEXT NOT NULL,
    description TEXT,
    provider TEXT,  -- Company/entity providing the agreement
    reference_number TEXT,  -- Provider's reference number
    
    -- Agreement data
    data TEXT,  -- JSON object containing agreement details
    
    -- Metadata
    -- created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key
    FOREIGN KEY (universe_id) REFERENCES universe(id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_agreements_account ON agreements(account_id);
CREATE INDEX IF NOT EXISTS idx_agreements_status ON agreements(status);
CREATE INDEX IF NOT EXISTS idx_agreements_dates ON agreements(start_date, end_date, renewal_date); 