
-- Categories Table
CREATE TABLE categories (
    category_id TEXT PRIMARY KEY, -- KSUID
    category_name TEXT NOT NULL,
    parent_category_id TEXT,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id),
    UNIQUE(category_name)
);

-- Manufacturers Table
CREATE TABLE manufacturers (
    account TEXT NOT NULL,
    manufacturer_id TEXT PRIMARY KEY, -- KSUID
    name TEXT NOT NULL,
    website TEXT,
    country TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account) REFERENCES accounts(id),
    UNIQUE(account, name)
);

-- Products Master Table
CREATE TABLE products (
    account TEXT NOT NULL,
    id TEXT PRIMARY KEY, -- KSUID
    upc TEXT,
    asin TEXT,
    elid TEXT,
    brand TEXT,

    name TEXT, -- personal name
    tags TEXT, -- user tags separated/surrounded by commas
    title TEXT, -- product title from upc lookup
    product_name TEXT NOT NULL,
    manufacturer_id TEXT,
    category_id TEXT,
    category TEXT,
    description TEXT,
    model TEXT,
            color TEXT,
    weight REAL,
    dimensions TEXT,
    msrp REAL, -- TODO consider per region
    msrp_currency TEXT,
    web_scrape_info TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account) REFERENCES accounts(id),
    FOREIGN KEY (manufacturer_id) REFERENCES manufacturers(manufacturer_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    UNIQUE(account, upc),
    UNIQUE(account, product_name, model_number)
);

-- Personal Inventory Table
CREATE TABLE user_items (
    account TEXT NOT NULL,
    item_id TEXT PRIMARY KEY, -- KSUID
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
    FOREIGN KEY (account) REFERENCES accounts(id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Image Storage Table (with Vector Embeddings)
CREATE TABLE item_images (
    account TEXT NOT NULL,
    image_id TEXT PRIMARY KEY, -- KSUID
    item_id TEXT NOT NULL,
    image_path TEXT NOT NULL,
    is_public BOOLEAN DEFAULT 0,
    image_type TEXT, -- 'original', 'user_added', 'web_scraped'
    vector_embedding BLOB, -- Storing vector embedding for image recognition
    upload_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account) REFERENCES accounts(id),
    FOREIGN KEY (item_id) REFERENCES user_items(item_id)
);

-- Web Scrape Metadata Table
CREATE TABLE web_scrape_metadata (
    account TEXT NOT NULL,
    scrape_id TEXT PRIMARY KEY, -- KSUID
    product_id TEXT NOT NULL,
    source_url TEXT,
    scraped_data TEXT,
    scrape_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account) REFERENCES accounts(id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Indexes for performance
CREATE INDEX idx_accounts_email ON accounts(email);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_user_items_product ON user_items(account_id, product_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_manufacturer ON products(manufacturer_id);
CREATE INDEX idx_images_item ON item_images(item_id);