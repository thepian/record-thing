"""
Database operations module for record_thing.
Contains functions for displaying database info and manipulating records.
"""

import json
import logging
import random
import sqlite3
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Dict, Generator, List

import duckdb

from ..commons import commons, create_uid
from ..taxonomy.category import EvidenceType, generate_evidence_types
from .schema import ensure_owner_account, init_db_tables
from .test_data import (
    BRANDS,
    DEFAULT_TRANSLATIONS,
    DOCUMENT_PROVIDERS,
    LUXURY_ITEMS,
    REQUEST_TYPES,
    RETAILERS,
    TEST_SCENARIOS,
    THING_EVIDENCE_TYPES,
    USE_CASES,
    VARIATIONS,
    Condition,
    DeliveryMethod,
    Region,
    Status,
)

# Create logger
logger = logging.getLogger(__name__)


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

            # Generate timestamps
            now = datetime.now(timezone.utc)
            created_at = now - timedelta(days=random.randint(0, 30))
            updated_at = created_at + timedelta(days=random.randint(0, 7))

            evidence_data.append(
                (
                    create_uid(),  # id
                    thing_account_id,
                    thing_id,
                    None,  # request_id (null for now)
                    random.randint(
                        1, 100
                    ),  # evidence_type (random for now) TODO correlate with evidence_type
                    json.dumps(
                        {
                            "type": evidence_type,
                            "document_type": random.choice(doc_types),
                            "date": datetime.now(timezone.utc).isoformat(),
                            "notes": f"Evidence for {evidence_type}",
                            "metadata": {
                                "source": random.choice(
                                    [p[0] for p in DOCUMENT_PROVIDERS]
                                ),
                                "format": random.choice(["pdf", "jpg", "png"]),
                                "size": random.randint(100000, 5000000),
                            },
                        }
                    ),
                    f"/images/{create_uid()}.jpg",  # local_file
                    created_at.timestamp(),  # created_at
                    updated_at.timestamp(),  # updated_at
                )
            )

    cursor.executemany(
        """
    INSERT OR IGNORE INTO evidence (
        id, thing_account_id, thing_id, request_id,
        evidence_type, data, local_file, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """,
        evidence_data,
    )


def generate_evidence_for_requests(cursor, request_ids: list) -> None:
    """
    Link evidence records to requests.

    Args:
        cursor: Database cursor
        request_ids: List of request IDs to link evidence to
    """
    for request_id in request_ids:
        cursor.execute(
            """
        UPDATE evidence 
        SET request_id = ? 
        WHERE id IN (
            SELECT id FROM evidence 
            WHERE request_id IS NULL 
            ORDER BY RANDOM() 
            LIMIT ?
        )
        """,
            (request_id, random.randint(1, 3)),
        )


def generate_universe_records(cursor, use_cases: dict) -> int:
    """
    Generate universe records for each use case if they don't exist.

    Args:
        cursor: Database cursor
        use_cases: Dictionary of use cases

    Returns:
        The total count of universes
    """
    # Check existing universes
    cursor.execute("SELECT url FROM universe")
    existing_urls = {row[0] for row in cursor.fetchall()}

    # Filter out universes that already exist
    universe_data = [
        (
            f"https://example.com/universe/{use_case}",
            use_case.replace("_", " ").title(),
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
            json.dumps({"active": True}),
        )
        for use_case, data in use_cases.items()
        if f"https://example.com/universe/{use_case}" not in existing_urls
    ]

    if universe_data:
        cursor.executemany(
            """
        INSERT OR IGNORE INTO universe (
            url, name, description, version, date,
            checksum, checksum_type, is_downloaded, is_installed,
            is_running, is_paused, is_stopped, is_failed,
            is_completed, is_cancelled, is_deleted,
            enabled_menus, enabled_features, flags
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
            universe_data,
        )

    # Return total count of universes
    cursor.execute("SELECT COUNT(*) FROM universe")
    return cursor.fetchone()[0]


def generate_document_types(cursor) -> int:
    """
    Generate and insert document type records if they don't exist.

    Args:
        cursor: Database cursor

    Returns:
        The total count of document types
    """
    # Check existing document types
    cursor.execute("SELECT rootName FROM document_type WHERE lang = 'en'")
    existing_types = {row[0] for row in cursor.fetchall()}

    # Filter out types that already exist
    document_types = [
        (
            "en",
            f"{provider}_{doc_type}".lower().replace(" ", "_"),
            f"{provider} {doc_type}",
            f"https://example.com/documents/{provider}/{doc_type}".lower().replace(
                " ", "-"
            ),
        )
        for provider, doc_types in DOCUMENT_PROVIDERS
        for doc_type in doc_types
        if f"{provider}_{doc_type}".lower().replace(" ", "_") not in existing_types
    ]

    if document_types:
        cursor.executemany(
            """
        INSERT OR IGNORE INTO document_type (lang, rootName, name, url)
        VALUES (?, ?, ?, ?)
        """,
            document_types,
        )

    # Return total count
    cursor.execute("SELECT COUNT(*) FROM document_type WHERE lang = 'en'")
    return cursor.fetchone()[0]


def generate_requests(cursor, scenario: dict, universe_count: int) -> list:
    """
    Generate and insert request records.

    Args:
        cursor: Database cursor
        scenario: Test scenario containing request count
        universe_count: Count of universes in the database

    Returns:
        List of generated request IDs
    """
    # Get highest existing ID
    cursor.execute("SELECT MAX(id) FROM requests")
    max_id = int(cursor.fetchone()[0] or 0)

    requests_data = []
    for i in range(scenario["requests"]):
        new_id = max_id + i + 1
        request_type, required_evidence = random.choice(REQUEST_TYPES)

        # Generate a unique URL for the request
        request_url = f"https://example.com/requests/{new_id}"

        created_at = datetime.now(timezone.utc) - timedelta(days=random.randint(0, 30))
        completed_at = (
            created_at + timedelta(days=random.randint(1, 30))
            if random.choice([True, False])
            else None
        )

        # Select random delivery method from enum
        delivery_method = random.choice(list(DeliveryMethod))
        # Get corresponding target for this delivery method
        delivery_target = random.choice(
            VARIATIONS["delivery_targets"][delivery_method.value]
        )

        requests_data.append(
            (
                new_id,  # id
                commons["owner_id"],  # account_id
                request_url,  # url (required)
                random.randint(1, universe_count),  # universe_id
                request_type,  # type
                json.dumps(
                    {
                        "required_evidence": required_evidence,
                        "priority": random.choice(VARIATIONS["priorities"]),
                        "due_date": (
                            datetime.now(timezone.utc)
                            + timedelta(days=random.randint(1, 30))
                        ).isoformat(),
                        "notes": f"Request for {request_type}",
                    }
                ),  # data
                random.choice(list(Status)).value,  # status
                created_at,
                completed_at,
                delivery_method.value,  # delivery_method
                delivery_target,  # delivery_target
            )
        )

    if requests_data:
        cursor.executemany(
            """
        INSERT OR IGNORE INTO requests (
            id, account_id, url, universe_id, type, data, status,
            created_at, completed_at,
            delivery_method, delivery_target
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
            requests_data,
        )

    # Return request IDs for evidence generation
    return [r[0] for r in requests_data]


def generate_things(
    cursor, scenario: dict, evidence_type_count: int, document_type_count: int
) -> list:
    """
    Generate and insert thing records up to planned quantity.

    Args:
        cursor: Database cursor
        scenario: Test scenario containing things_count
        evidence_type_count: Count of evidence types in the database
        document_type_count: Count of document types in the database

    Returns:
        List of (account_id, thing_id) tuples
    """
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

                    # Generate timestamps
                    now = datetime.now(timezone.utc)
                    created_at = now - timedelta(days=random.randint(0, 365))
                    updated_at = created_at + timedelta(days=random.randint(0, 30))

                    things_data.append(
                        (
                            create_uid(),  # id
                            commons["owner_id"],  # account_id
                            serial,  # upc (using as serial number)
                            None,  # asin
                            None,  # elid
                            brand_name,
                            model,
                            (
                                random.choice(["Black", "Silver", "Gold", "Platinum"])
                                if "Watch" in category
                                else random.choice(
                                    ["Natural", "Classic", "Limited Edition"]
                                )
                            ),
                            json.dumps(
                                [category.lower(), brand_name.lower(), model.lower()]
                            ),  # tags
                            category,  # category
                            random.randint(1, evidence_type_count),  # evidence_type
                            f"{brand_name} {model}",  # title
                            f"Authentic {brand_name} {model} - {category}",  # description
                            created_at.timestamp(),  # created_at
                            updated_at.timestamp(),  # updated_at
                        )
                    )

        # Fill remaining with regular items if needed
        while len(things_data) < remaining_count:
            # Generate timestamps
            now = datetime.now(timezone.utc)
            created_at = now - timedelta(days=random.randint(0, 365))
            updated_at = created_at + timedelta(days=random.randint(0, 30))

            things_data.append(
                (
                    create_uid(),
                    commons["owner_id"],
                    f"{random.choice(RETAILERS)[2]}{random.randint(1000, 9999)}",
                    f"ASIN{random.randint(1000, 9999)}",
                    f"ELID{random.randint(1000, 9999)}",
                    random.choice([brand for brand, _ in BRANDS]),
                    f"Model {random.randint(100, 999)}",
                    random.choice(["Black", "White", "Silver", "Gold"]),
                    json.dumps([f"tag{j}" for j in range(3)]),
                    random.choice(
                        sum([data["things"] for data in USE_CASES.values()], [])
                    ),
                    random.randint(1, evidence_type_count),  # evidence_type
                    f"Sample Thing {existing_count + len(things_data)}",
                    f"Description for sample thing {existing_count + len(things_data)}",
                    created_at.timestamp(),  # created_at
                    updated_at.timestamp(),  # updated_at
                )
            )

        cursor.executemany(
            """
        INSERT OR IGNORE INTO things (
            id, account_id, upc, asin, elid, brand, model, color,
            tags, category, evidence_type, title, description,
            created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
            things_data,
        )

    # Return all things for evidence generation
    cursor.execute("SELECT account_id, id FROM things")
    return cursor.fetchall()


def insert_evidence_types(
    evidences: Generator[EvidenceType, None, None], cursor
) -> int:
    """
    Insert evidence type records and return the count of inserted records.

    Args:
        evidences: Generator of evidence types
        cursor: Database cursor

    Returns:
        Count of evidence types
    """
    evidence_list = list(evidences)
    cursor.executemany(
        """
    INSERT OR IGNORE INTO evidence_type (
        lang, rootName, name, url, gpcRoot, gpcName, gpcCode, unspscID
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """,
        evidence_list,
    )

    # Return the count of evidence types
    return len(evidence_list)


def generate_translations(cursor) -> None:
    """
    Generate and insert translation records if they don't exist.

    Args:
        cursor: Database cursor
    """
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
            translations.append(
                (
                    lang,
                    key,
                    value,
                    context,
                    # datetime.now(timezone.utc).isoformat(),
                    # datetime.now(timezone.utc).isoformat()
                )
            )

    # Add default UI translations
    for lang, key, value, context in DEFAULT_TRANSLATIONS:
        add_translation(lang, key, value, context)

    # Add product type translations
    cursor.execute("SELECT lang, rootName, name FROM product_type")
    for lang, root_name, name in cursor.fetchall():
        key = f"product_type.{root_name}"
        add_translation(lang, key, name, "product_type")

    # Add document type translations
    cursor.execute("SELECT lang, rootName, name FROM document_type")
    for lang, root_name, name in cursor.fetchall():
        key = f"document_type.{root_name}"
        add_translation(lang, key, name, "document_type")

    if translations:
        cursor.executemany(
            """
        INSERT OR IGNORE INTO translations (
            lang, key, value, context
        ) VALUES (?, ?, ?, ?)
        """,
            translations,
        )


def generate_testdata_records(conn: sqlite3.Connection, db_path: Path) -> None:
    """
    Generate and insert all types of records.

    Args:
        conn: Database connection
        db_path: Path to the database file
    """
    conn.execute("BEGIN TRANSACTION;")
    cursor = conn.cursor()

    try:
        ensure_owner_account(conn)

        # Generate all types of records
        universe_count = generate_universe_records(cursor, USE_CASES)

        evidence_type_count = insert_evidence_types(generate_evidence_types(), cursor)

        document_type_count = generate_document_types(cursor)

        # Generate translations after product and document types
        generate_translations(cursor)

        # Generate things and their evidence
        scenario = TEST_SCENARIOS[0]
        things = generate_things(
            cursor, scenario, evidence_type_count, document_type_count
        )
        generate_evidence_for_things(cursor, things, scenario)

        # Generate requests and link evidence
        request_ids = generate_requests(cursor, scenario, universe_count)
        generate_evidence_for_requests(cursor, request_ids)

        conn.commit()
        logger.info(f"Successfully inserted sample data into {db_path}")

    except Exception as e:
        conn.rollback()
        logger.error(f"Error inserting sample data: {e}")
        raise
    finally:
        cursor.close()


def insert_sample_data(conn: sqlite3.Connection, db_path: Path) -> None:
    """
    Insert sample records into all tables using realistic test data.

    Args:
        conn: Database connection
        db_path: Path to the database file
    """
    try:
        generate_testdata_records(conn, db_path)
    except Exception as e:
        logger.error(f"Database operation error: {e}")
        raise


def create_database(conn: sqlite3.Connection, db_path: Path) -> None:
    """
    Create the RecordThing database schema and insert sample data.

    Args:
        conn: Database connection
        db_path: Path to the database file
    """
    try:
        logger.info(f"Initializing database schema for {db_path}...")
        init_db_tables(conn)

        # After creating the database, insert sample data
        insert_sample_data(conn, db_path)

    except Exception as e:
        logger.error(f"Error creating database: {e}")
        raise
