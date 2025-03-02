CREATE TABLE IF NOT EXISTS product (
    id TEXT PRIMARY KEY,  -- KSUID
    name TEXT NOT NULL,
    alt TEXT,            -- Alternative name
    alt1 TEXT,           -- Additional alternative name
    alt2 TEXT,           -- Additional alternative name
    brand_id TEXT,       -- Reference to brand table
    company_id TEXT,     -- Reference to company table
    category TEXT,       -- Product category
    tags TEXT,           -- Comma-separated tags
    wikidata_id TEXT,    -- Wikidata Q identifier
    isni_id TEXT,        -- ISNI identifier (https://isni.org/isni/{id})
    description TEXT,    -- Product description
    launch_date TEXT,    -- Launch/release date
    discontinued_date TEXT, -- End of life date
    official_url TEXT,   -- Official product webpage
    support_url TEXT,    -- Product support webpage
    wikipedia_url TEXT,  -- Wikipedia article URL
    image_url TEXT,      -- Primary product image URL
    -- created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- scanned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    source TEXT          -- Data source (wikidata, manual, etc)
    -- FOREIGN KEY(brand_id) REFERENCES brand(id),
    -- FOREIGN KEY(company_id) REFERENCES company(id)
);

CREATE TABLE IF NOT EXISTS company (
    id TEXT PRIMARY KEY,  -- KSUID
    name TEXT NOT NULL,
    alt TEXT,            -- Alternative name
    alt1 TEXT,           -- Additional alternative name
    alt2 TEXT,           -- Additional alternative name
    category TEXT,       -- Industry category
    tags TEXT,           -- Comma-separated tags
    wikidata_id TEXT,    -- Wikidata Q identifier
    isni_id TEXT,        -- ISNI identifier
    description TEXT,    -- Company description
    founded_date TEXT,   -- Founding date
    headquarters TEXT,   -- HQ location
    official_url TEXT,   -- Official company website
    support_url TEXT,    -- Support website
    wikipedia_url TEXT,  -- Wikipedia article URL
    logo_url TEXT,       -- Company logo URL
    -- created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- scanned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    source TEXT,         -- Data source (wikidata, manual, etc)
    verified_domain TEXT -- Verified company domain
);

CREATE TABLE IF NOT EXISTS brand (
    id TEXT PRIMARY KEY,  -- KSUID
    name TEXT NOT NULL,
    alt TEXT,            -- Alternative name
    alt1 TEXT,           -- Additional alternative name
    alt2 TEXT,           -- Additional alternative name
    company_id TEXT,     -- Owner company
    parent_brand_id TEXT, -- Parent brand for sub-brands
    category TEXT,       -- Brand category
    tags TEXT,           -- Comma-separated tags
    wikidata_id TEXT,    -- Wikidata Q identifier
    isni_id TEXT,        -- ISNI identifier
    description TEXT,    -- Brand description
    founded_date TEXT,   -- Brand founding date
    discontinued_date TEXT, -- End of life date
    official_url TEXT,   -- Official brand website
    support_url TEXT,    -- Support website
    wikipedia_url TEXT,  -- Wikipedia article URL
    logo_url TEXT,       -- Brand logo URL
    -- created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- scanned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    source TEXT          -- Data source (wikidata, manual, etc)
    -- FOREIGN KEY(company_id) REFERENCES company(id),
    -- FOREIGN KEY(parent_brand_id) REFERENCES brand(id)
);

-- Indexes for better query performance
-- CREATE INDEX IF NOT EXISTS idx_product_brand ON product(brand_id);
-- CREATE INDEX IF NOT EXISTS idx_product_company ON product(company_id);
-- CREATE INDEX IF NOT EXISTS idx_product_wikidata ON product(wikidata_id);
-- CREATE INDEX IF NOT EXISTS idx_brand_company ON brand(company_id);
-- CREATE INDEX IF NOT EXISTS idx_brand_parent ON brand(parent_brand_id);
-- CREATE INDEX IF NOT EXISTS idx_brand_wikidata ON brand(wikidata_id);
-- CREATE INDEX IF NOT EXISTS idx_company_wikidata ON company(wikidata_id);

-- Triggers to update timestamps
-- CREATE TRIGGER IF NOT EXISTS update_product_timestamp 
-- AFTER UPDATE ON product
-- BEGIN
--     UPDATE product SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
-- END;

-- CREATE TRIGGER IF NOT EXISTS update_company_timestamp 
-- AFTER UPDATE ON company
-- BEGIN
--     UPDATE company SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
-- END;

-- CREATE TRIGGER IF NOT EXISTS update_brand_timestamp 
-- AFTER UPDATE ON brand
-- BEGIN
--     UPDATE brand SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
-- END;