from pathlib import Path
from typing import Generator
import duckdb
import sqlite3
from datetime import datetime, timezone, timedelta
import json
from .taxonomy.category import EvidenceType, generate_evidence_types
import random
from .db.schema import migrate_schema, init_db_tables, ensure_owner_account
from .db.test_data import (
    BRANDS, RETAILERS, DOCUMENT_PROVIDERS, 
    USE_CASES, TEST_SCENARIOS, VARIATIONS,
    THING_EVIDENCE_TYPES, REQUEST_TYPES,
    Status, Condition, Region, DEFAULT_TRANSLATIONS,
    LUXURY_ITEMS, DeliveryMethod
)

from .commons import commons, create_uid

DBP = Path(__file__).parent / "record-thing.sqlite"

def ensure_empty_db(dbp: Path) -> None:
    """
    Create an empty SQLite database if it doesn't exist.
    
    Args:
        dbp: Path to the database file
    """
    if not dbp.exists():
        dbp.parent.mkdir(parents=True, exist_ok=True)
        sqlite3.connect(dbp).close()
        print(f"Created empty database at {dbp}")

def test_connection(dbp: Path = DBP) -> None:
    """
    Test connection to the RecordThing database.
    
    Args:
        dbp: Path to the database file
    """
    ensure_empty_db(dbp)
    con = None
    
    try:
        # First connect to an in-memory DuckDB instance
        con = duckdb.connect(':memory:')
        
        # Install and load SQLite extension
        con.execute("INSTALL sqlite;")
        con.execute("LOAD sqlite;")
        
        # Attach the SQLite database
        con.execute(f"CALL sqlite_attach('{dbp}');")

        # Example: List SQLite databases
        con.sql("SELECT * FROM sqlite_master").show()

    finally:
        if con:
            con.close()

def generate_evidence_for_things(cursor, things: list, scenario: dict) -> None:
    """
    Generate evidence records for a list of things.
    
    Args:
        cursor: Database cursor
        things: List of (account_id, thing_id) tuples
        scenario: Test scenario containing evidence_per_thing count
    """
    evidence_data = []
    
    for thing_account_id, thing_id in things:
        # Generate multiple pieces of evidence per thing
        for _ in range(random.randint(1, scenario["evidence_per_thing"])):
            evidence_type, doc_types = random.choice(THING_EVIDENCE_TYPES)
            
            evidence_data.append((
                create_uid(),  # id
                thing_account_id,
                thing_id,
                None,  # request_id (null for now)
                random.randint(1, 100),  # product_type
                random.randint(1, 100),  # document_type
                json.dumps({
                    "type": evidence_type,
                    "document_type": random.choice(doc_types),
                    "date": datetime.now(timezone.utc).isoformat(),
                    "notes": f"Evidence for {evidence_type}",
                    "metadata": {
                        "source": random.choice([p[0] for p in DOCUMENT_PROVIDERS]),
                        "format": random.choice(["pdf", "jpg", "png"]),
                        "size": random.randint(100000, 5000000)
                    }
                }),
                f"/images/{create_uid()}.jpg"  # local_file
            ))

    cursor.executemany("""
    INSERT OR IGNORE INTO evidence (
        id, thing_account_id, thing_id, request_id,
        product_type, document_type, data, local_file
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, evidence_data)

def generate_evidence_for_requests(cursor, request_ids: list) -> None:
    """
    Link evidence records to requests.
    
    Args:
        cursor: Database cursor
        request_ids: List of request IDs to link evidence to
    """
    for request_id in request_ids:
        cursor.execute("""
        UPDATE evidence 
        SET request_id = ? 
        WHERE id IN (
            SELECT id FROM evidence 
            WHERE request_id IS NULL 
            ORDER BY RANDOM() 
            LIMIT ?
        )
        """, (request_id, random.randint(1, 3)))

def generate_universe_records(cursor, use_cases: dict) -> int:
    """Generate universe records for each use case if they don't exist."""
    # Check existing universes
    cursor.execute("SELECT url FROM universe")
    existing_urls = {row[0] for row in cursor.fetchall()}
    
    # Filter out universes that already exist
    universe_data = [
        (
            f"https://example.com/universe/{use_case}", 
            use_case.replace('_', ' ').title(), 
            f"Universe for {use_case} management",
            "1.0.0",
            datetime.now(timezone.utc).isoformat(),
            f"checksum_{use_case}",
            "SHA256",
            True,
            True,
            True,
            *[False] * 6,
            json.dumps(data["things"]),
            json.dumps(data["evidence"]),
            json.dumps({"active": True})
        ) for use_case, data in use_cases.items()
        if f"https://example.com/universe/{use_case}" not in existing_urls
    ]
    
    if universe_data:
        cursor.executemany("""
        INSERT OR IGNORE INTO universe (
            url, name, description, version, date,
            checksum, checksum_type, is_downloaded, is_installed,
            is_running, is_paused, is_stopped, is_failed,
            is_completed, is_cancelled, is_deleted,
            enabled_menus, enabled_features, flags
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, universe_data)
    
    # Return total count of universes
    cursor.execute("SELECT COUNT(*) FROM universe")
    return cursor.fetchone()[0]


def generate_document_types(cursor) -> int:
    """Generate and insert document type records if they don't exist."""
    # Check existing document types
    cursor.execute("SELECT rootName FROM document_type WHERE lang = 'en'")
    existing_types = {row[0] for row in cursor.fetchall()}
    
    # Filter out types that already exist
    document_types = [
        (
            "en",
            f"{provider}_{doc_type}".lower().replace(' ', '_'),
            f"{provider} {doc_type}",
            f"https://example.com/documents/{provider}/{doc_type}".lower().replace(' ', '-')
        )
        for provider, doc_types in DOCUMENT_PROVIDERS
        for doc_type in doc_types
        if f"{provider}_{doc_type}".lower().replace(' ', '_') not in existing_types
    ]
    
    if document_types:
        cursor.executemany("""
        INSERT OR IGNORE INTO document_type (lang, rootName, name, url)
        VALUES (?, ?, ?, ?)
        """, document_types)
    
    # Return total count
    cursor.execute("SELECT COUNT(*) FROM document_type WHERE lang = 'en'")
    return cursor.fetchone()[0]

def generate_requests(cursor, scenario: dict, universe_count: int) -> list:
    """Generate and insert request records."""
    # Get highest existing ID
    cursor.execute("SELECT MAX(id) FROM requests")
    max_id = int(cursor.fetchone()[0] or 0)
    # print("max_id for requests:", max_id, type(max_id))
    
    requests_data = []
    for i in range(scenario["requests"]):
        new_id = max_id + i + 1
        request_type, required_evidence = random.choice(REQUEST_TYPES)
        
        # Generate a unique URL for the request
        request_url = f"https://example.com/requests/{new_id}"
        
        # Select random delivery method from enum
        delivery_method = random.choice(list(DeliveryMethod))
        # Get corresponding target for this delivery method
        delivery_target = random.choice(VARIATIONS["delivery_targets"][delivery_method.value])
        
        requests_data.append((
            new_id,  # id
            commons['owner_id'],  # account_id
            request_url,  # url (required)
            random.randint(1, universe_count),  # universe_id
            request_type,  # type
            json.dumps({
                "required_evidence": required_evidence,
                "priority": random.choice(VARIATIONS["priorities"]),
                "due_date": (datetime.now(timezone.utc) + timedelta(days=random.randint(1, 30))).isoformat(),
                "notes": f"Request for {request_type}"
            }),  # data
            random.choice(list(Status)).value,  # status
            delivery_method.value,  # delivery_method
            delivery_target  # delivery_target
        ))
    
    if requests_data:
        cursor.executemany("""
        INSERT OR IGNORE INTO requests (
            id, account_id, url, universe_id, type, data, status,
            delivery_method, delivery_target
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, requests_data)

    # Return request IDs for evidence generation
    return [r[0] for r in requests_data]

def generate_things(cursor, scenario: dict, product_type_count: int, document_type_count: int) -> list:
    """Generate and insert thing records up to planned quantity."""
    # Check existing things count
    cursor.execute("SELECT COUNT(*) FROM things")
    existing_count = cursor.fetchone()[0]
    
    # Only generate up to the planned quantity
    remaining_count = max(0, scenario["things_count"] - existing_count)
    
    if remaining_count > 0:
        things_data = []
        
        # Generate luxury items
        for category, brands in LUXURY_ITEMS:
            for brand_name, models in brands:
                for model in models:
                    if len(things_data) >= remaining_count:
                        break
                        
                    # Generate a unique identifier based on brand and model
                    serial = f"{brand_name[:3]}{random.randint(100000, 999999)}"
                    
                    things_data.append((
                        create_uid(),  # id
                        commons['owner_id'],  # account_id
                        serial,  # upc (using as serial number)
                        None,  # asin
                        None,  # elid
                        brand_name,
                        model,
                        random.choice(["Black", "Silver", "Gold", "Platinum"]) if "Watch" in category 
                        else random.choice(["Natural", "Classic", "Limited Edition"]),
                        json.dumps([category.lower(), brand_name.lower(), model.lower()]),  # tags
                        category,  # category
                        random.randint(1, product_type_count),
                        random.randint(1, document_type_count),
                        f"{brand_name} {model}",  # title
                        f"Authentic {brand_name} {model} - {category}"  # description
                    ))

        # Fill remaining with regular items if needed
        while len(things_data) < remaining_count:
            things_data.append((
                create_uid(),
                commons['owner_id'],
                f"{random.choice(RETAILERS)[2]}{random.randint(1000, 9999)}",
                f"ASIN{random.randint(1000, 9999)}",
                f"ELID{random.randint(1000, 9999)}",
                random.choice([brand for brand, _ in BRANDS]),
                f"Model {random.randint(100, 999)}",
                random.choice(["Black", "White", "Silver", "Gold"]),
                json.dumps([f"tag{j}" for j in range(3)]),
                random.choice(sum([data["things"] for data in USE_CASES.values()], [])),
                random.randint(1, product_type_count),
                random.randint(1, document_type_count),
                f"Sample Thing {existing_count + len(things_data)}",
                f"Description for sample thing {existing_count + len(things_data)}"
            ))

        cursor.executemany("""
        INSERT OR IGNORE INTO things (
            id, account_id, upc, asin, elid, brand, model, color,
            tags, category, product_type, document_type, title, description
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, things_data)
    
    # Return all things for evidence generation
    cursor.execute("SELECT account_id, id FROM things")
    return cursor.fetchall()

def insert_evidence_types(evidences: Generator[EvidenceType, None, None], cursor) -> None:
    """Insert evidence type records."""
    # for e in list(evidences):
    #     print(e)

    cursor.executemany("""
    INSERT OR IGNORE INTO evidence_type (
        lang, rootName, name, url, gpcRoot, gpcName, gpcCode, unspscID
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, list(evidences))

def generate_testdata_records(con, cursor, dbp = DBP) -> None:
    """
    Generate and insert all types of records.
    """
    con.execute("BEGIN TRANSACTION;")

    try:
        ensure_owner_account(con)
        
        # Generate all types of records
        universe_count = generate_universe_records(cursor, USE_CASES)
        
        evidence_type_count = insert_evidence_types(generate_evidence_types(), cursor)

        document_type_count = generate_document_types(cursor)
        
        # Generate translations after product and document types
        generate_translations(cursor)
        
        # Generate things and their evidence
        scenario = TEST_SCENARIOS[0]
        things = generate_things(cursor, scenario, evidence_type_count, document_type_count)
        generate_evidence_for_things(cursor, things, scenario)
        
        # Generate requests and link evidence
        request_ids = generate_requests(cursor, scenario, universe_count)
        generate_evidence_for_requests(cursor, request_ids)

        con.commit()
        print(f"Successfully inserted sample data into {dbp}")

    except Exception as e:
        con.rollback()
        print(f"Error inserting sample data: {e}")
        raise


def insert_sample_data(dbp: Path = DBP) -> None:
    """Insert sample records into all tables using realistic test data."""
    con = None
    try:
        con = sqlite3.connect(dbp)
        cursor = con.cursor()
        generate_testdata_records(con, cursor, dbp)
    except Exception as e:
        print(f"Database connection error: {e}")
        raise

    finally:
        if cursor:
            cursor.close()
        if con:
            try:
                con.close()
            except Exception as e:
                print(f"Error closing connection: {e}")

def create_database(dbp: Path = DBP) -> None:
    """
    Create the RecordThing database schema.
    
    Args:
        dbp: Path to the database file
    """
    ensure_empty_db(dbp)
    
    try:
        con = duckdb.connect(':memory:')
        con.execute("INSTALL sqlite;")
        con.execute("LOAD sqlite;")
        con.execute(f"ATTACH '{dbp}' (TYPE SQLITE);")
        # con.execute("USE record-thing;")
        # con.execute(f"CALL sqlite_attach('{dbp}');")

        print(f"Updating database schema for {dbp}...")
        init_db_tables(con)

        # Commit changes directly to SQLite database
        # con.execute("CALL sqlite_query('COMMIT;');")
        # con.execute("DETACH DATABASE record-thing;")
        con.commit()
    finally:
        if con:
            con.close()
    
    # After creating the database, insert sample data
    insert_sample_data(dbp)

def generate_translations(cursor) -> None:
    """Generate and insert translation records if they don't exist."""
    # Check existing translations
    cursor.execute("SELECT lang, key FROM translations")
    existing_keys = {(row[0], row[1]) for row in cursor.fetchall()}
    
    # Use a set to prevent duplicate keys during generation
    translation_keys = set()
    translations = []
    
    def add_translation(lang: str, key: str, value: str, context: str) -> None:
        """Helper to add translation if it doesn't exist."""
        if (lang, key) not in existing_keys and (lang, key) not in translation_keys:
            translation_keys.add((lang, key))
            translations.append((
                lang,
                key,
                value,
                context,
                # datetime.now(timezone.utc).isoformat(),
                # datetime.now(timezone.utc).isoformat()
            ))
    
    # Add default UI translations
    for lang, key, value, context in DEFAULT_TRANSLATIONS:
        add_translation(lang, key, value, context)
    
    # Add product type translations
    cursor.execute("SELECT lang, rootName, name FROM product_type")
    for lang, root_name, name in cursor.fetchall():
        key = f"product_type.{root_name}"
        add_translation(lang, key, name, 'product_type')
    
    # Add document type translations
    cursor.execute("SELECT lang, rootName, name FROM document_type")
    for lang, root_name, name in cursor.fetchall():
        key = f"document_type.{root_name}"
        add_translation(lang, key, name, 'document_type')
    
    if translations:
        cursor.executemany("""
        INSERT OR IGNORE INTO translations (
            lang, key, value, context
        ) VALUES (?, ?, ?, ?)
        """, translations)
        # cursor.executemany("""
        # INSERT OR IGNORE INTO translations (
        #     lang, key, value, context, created_at, updated_at
        # ) VALUES (?, ?, ?, ?, ?, ?)
        # """, translations)

if __name__ == "__main__":
    create_database()