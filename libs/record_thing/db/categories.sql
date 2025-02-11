CREATE TABLE IF NOT EXISTS product_type (
    lang VARCHAR NOT NULL,
    rootName VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    url VARCHAR,
    gpcRoot VARCHAR,
    gpcName VARCHAR,
    gpcCode INTEGER,
    unspscID INTEGER,
    icon_path VARCHAR,
    canonicalImage BLOB,

    PRIMARY KEY (lang, rootName, name)
);

CREATE TABLE IF NOT EXISTS document_type (
    lang VARCHAR NOT NULL,
    rootName VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    url VARCHAR,
    icon_path VARCHAR,
    canonicalImage BLOB,

    PRIMARY KEY (lang, rootName, name)
);

CREATE TABLE IF NOT EXISTS evidence_type (
    id INTEGER PRIMARY KEY,
    lang VARCHAR NOT NULL,
    rootName VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    url VARCHAR,
    gpcRoot VARCHAR,
    gpcName VARCHAR,
    gpcCode INTEGER,
    unspscID INTEGER,
    icon_path VARCHAR

);