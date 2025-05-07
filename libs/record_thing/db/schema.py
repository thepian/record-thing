import logging
import re
import sqlite3
from pathlib import Path

from ..commons import FREE_TEAM_ID, PREMIUM_TEAM_ID, commons

# Create logger
logger = logging.getLogger(__name__)

# Set up logging if not already configured
if not logger.handlers:
    handler = logging.StreamHandler()
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)

# sql_dir.glob('*.sql')
SQL_FILES = [
    # 'account.sql',
    "categories.sql",
    "evidence.sql",
    "assets.sql",
    "translations.sql",
    "product.sql",
    # 'auth.sql',
    # 'vector.sql',
]


# TODO this needs to always be called
def ensure_owner_account(con, dummy_account_data=True) -> str:
    """
    Scenarios:
    1) No owners or accounts exist
    2) No owner exist, but accounts exist
    3) Owner exists, but no accounts exist
    4) Owner and accounts exist

    returns the owner_id
    """
    cursor = con.cursor()
    cursor.execute("SELECT * FROM owners LIMIT 1")
    one_owner = cursor.fetchone()
    cursor.execute("SELECT * FROM accounts LIMIT 1")
    one_account = cursor.fetchone()

    if one_owner is None and one_account is None:
        cursor.execute(
            """
            INSERT OR IGNORE INTO accounts(account_id, name, username, email, sms, region) VALUES (?, ?, ?, ?, ?, ?);
            """,
            [commons["account_id"], "Joe Schmoe", "joe", "joe@schmoe.com", "+0", "EU"],
        )
        cursor.execute(
            "INSERT OR IGNORE INTO owners(account_id) VALUES (?);",
            [commons["owner_id"]],
        )
    elif one_owner is None and one_account is not None:
        commons["account_id"] = one_account[0]
        commons["owner_id"] = one_account[0]
        cursor.execute(
            "INSERT OR IGNORE INTO owners(account_id) VALUES (?);",
            [commons["owner_id"]],
        )
    elif one_owner is not None and one_account is None:
        commons["account_id"] = one_owner[0]
        commons["owner_id"] = one_owner[0]
        cursor.execute(
            """
            INSERT OR IGNORE INTO accounts(account_id, name, username, email, sms, region) VALUES (?, ?, ?, ?, ?, ?);
            """,
            [commons["account_id"], "Joe Schmoe", "joe", "joe@schmoe.com", "+0", "EU"],
        )
    else:
        commons["account_id"] = one_owner[0]
        commons["owner_id"] = one_owner[0]
    cursor.close()

    return commons["owner_id"]


def ensure_teams(con) -> None:
    """
    Ensure the teams table is populated with required team entries.
    - FREE_TEAM_ID: For free tier users
    - PREMIUM_TEAM_ID: For premium tier users

    This should be called after ensure_owner_account to make sure
    the required teams exist in the database.
    """
    cursor = con.cursor()

    # Check if teams table exists
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='teams'")
    if not cursor.fetchone():
        logger.warning("Teams table doesn't exist, skipping team population")
        cursor.close()
        return

    # Check for existing teams
    cursor.execute(
        "SELECT team_id FROM teams WHERE team_id=? OR team_id=?",
        (FREE_TEAM_ID, PREMIUM_TEAM_ID),
    )
    existing_teams = [row[0] for row in cursor.fetchall()]

    # Insert free team if not exists
    if FREE_TEAM_ID not in existing_teams:
        logger.info(f"Creating free team with ID: {FREE_TEAM_ID}")
        cursor.execute(
            """
            INSERT INTO teams (
                team_id, name, region, tier, is_demo, is_active,
                storage_domain, storage_bucket_name, storage_bucket_region,
                fallback_domain, fallback_bucket_name, fallback_bucket_region,
                created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
            (
                FREE_TEAM_ID,
                "Free Tier",
                "EU",
                "free",
                0,  # is_demo
                1,  # is_active
                "storage.bunnycdn.com",
                "recordthing-demo",
                "eu",
                "storage.bunnycdn.com",  # fallback domain
                "recordthing-demo",  # fallback bucket
                "eu",  # fallback region
                0.0,  # created_at
                0.0,  # updated_at
            ),
        )

    # Insert premium team if not exists
    if PREMIUM_TEAM_ID not in existing_teams:
        logger.info(f"Creating premium team with ID: {PREMIUM_TEAM_ID}")
        cursor.execute(
            """
            INSERT INTO teams (
                team_id, name, region, tier, is_demo, is_active,
                storage_domain, storage_bucket_name, storage_bucket_region,
                fallback_domain, fallback_bucket_name, fallback_bucket_region,
                created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
            (
                PREMIUM_TEAM_ID,
                "Premium Tier",
                "EU",
                "premium",
                0,  # is_demo
                1,  # is_active
                "storage.bunnycdn.com",
                "recordthing-premium",
                "eu",
                "storage.bunnycdn.com",  # fallback domain
                "recordthing-premium",  # fallback bucket (fall back to common bucket)
                "eu",  # fallback region
                0.0,  # created_at
                0.0,  # updated_at
            ),
        )

    # If any changes were made, commit them
    if FREE_TEAM_ID not in existing_teams or PREMIUM_TEAM_ID not in existing_teams:
        con.commit()
        logger.info("Teams table updated with required team entries")
    else:
        logger.debug("Teams table already contains required team entries")

    cursor.close()


def init_account(con, dummy_account_data=True) -> None:
    """
    Initialize account tables.

    Args:
        con: Database connection
    """
    with open(Path(__file__).parent / "account.sql", "r") as sql_file:
        sql_script = sql_file.read()
        if "executescript" in dir(con):
            con.executescript(sql_script)
        else:
            con.execute(sql_script)

    ensure_owner_account(con, dummy_account_data=dummy_account_data)


def init_categories(con) -> None:
    """
    Initialize category tables.

    Args:
        con: Database connection
    """
    with open(Path(__file__).parent / "categories.sql", "r") as sql_file:
        sql_script = sql_file.read()
        if "executescript" in dir(con):
            con.executescript(sql_script)
        else:
            con.execute(sql_script)


def init_evidence(con) -> None:
    """
    Initialize evidence-related tables.

    Args:
        con: Database connection
    """
    with open(Path(__file__).parent / "evidence.sql", "r") as sql_file:
        sql_script = sql_file.read()
        if "executescript" in dir(con):
            con.executescript(sql_script)
        else:
            con.execute(sql_script)


def init_assets(con) -> None:
    """
    Initialize asset-related tables.

    Args:
        con: Database connection
    """
    with open(Path(__file__).parent / "assets.sql", "r") as sql_file:
        sql_script = sql_file.read()
        if "executescript" in dir(con):
            con.executescript(sql_script)
        else:
            con.execute(sql_script)


def init_translations(con) -> None:
    """
    Initialize translations table.

    Args:
        con: Database connection
    """
    with open(Path(__file__).parent / "translations.sql", "r") as sql_file:
        sql_script = sql_file.read()
        if "executescript" in dir(con):
            con.executescript(sql_script)
        else:
            con.execute(sql_script)


def init_product(con) -> None:
    """
    Initialize product-related tables (product, company, brand).

    Args:
        con: Database connection
    """
    with open(Path(__file__).parent / "product.sql", "r") as sql_file:
        sql_script = sql_file.read()
        if "executescript" in dir(con):
            con.executescript(sql_script)
        else:
            con.execute(sql_script)


def init_db_tables(con, dummy_account_data=True) -> None:
    """
    Initialize all database tables in the correct order.

    Args:
        con: Database connection
    """
    # Initialize tables in dependency order
    init_account(con, dummy_account_data=dummy_account_data)
    init_categories(con)
    init_product(con)
    init_evidence(con)
    init_assets(con)
    init_translations(con)

    # Apply any schema migrations
    # Uncomment if needed for automatic migrations
    # migrate_schema(con)

    # Ensure basic data exists
    ensure_owner_account(con, dummy_account_data=dummy_account_data)
    ensure_teams(con)


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


def parse_sql_schema(sql_file: Path) -> dict:
    """
    Parse SQL file to extract schema information and identify migrations.
    Returns a dictionary of migrations keyed by version.
    """
    migrations = {}
    current_table = None

    logger.debug(f"Parsing schema file: {sql_file}")

    with open(sql_file, "r") as f:
        sql = f.read()

    # Split into statements
    statements = [s.strip() for s in sql.split(";") if s.strip()]
    logger.debug(f"Found {len(statements)} SQL statements")

    for statement in statements:
        # Look for CREATE TABLE statements
        if statement.upper().startswith("CREATE TABLE"):
            # Extract table name
            table_match = re.search(
                r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?[`"]?(\w+)[`"]?\s*\((.*)\)',
                statement,
                re.IGNORECASE | re.DOTALL,
            )
            if table_match:
                current_table = table_match.group(1)
                column_defs = table_match.group(2)
                logger.debug(f"Processing CREATE TABLE for {current_table}")

                # Split column definitions
                for column_def in re.split(r",\s*(?=\w)", column_defs):
                    column_def = column_def.strip()
                    if not column_def or column_def.startswith(
                        ("PRIMARY KEY", "FOREIGN KEY", "UNIQUE", "CHECK")
                    ):
                        continue

                    # Extract column name and type
                    col_match = re.match(
                        r'[`"]?(\w+)[`"]?\s+([\w\(\),\s]+)(?:\s+(.*))?', column_def
                    )
                    if col_match:
                        column_name = col_match.group(1)
                        column_type = col_match.group(2).strip()
                        constraints = col_match.group(3) or ""

                        # Store base schema for comparison
                        if 0 not in migrations:
                            migrations[0] = []
                        migrations[0].append(
                            {
                                "table": current_table,
                                "column": column_name,
                                "definition": f"{column_type} {constraints}".strip(),
                            }
                        )
                        logger.debug(
                            f"Added base column: {current_table}.{column_name}"
                        )

        # Look for ALTER TABLE statements
        elif statement.upper().startswith("ALTER TABLE"):
            alter_match = re.search(
                r'ALTER\s+TABLE\s+[`"]?(\w+)[`"]?\s+ADD\s+(?:COLUMN\s+)?[`"]?(\w+)[`"]?\s+(.*)',
                statement,
                re.IGNORECASE,
            )
            if alter_match:
                table = alter_match.group(1)
                column = alter_match.group(2)
                definition = alter_match.group(3).strip()

                # Look for version comment
                version_match = re.search(
                    r"--\s*version:\s*(\d+)", statement, re.IGNORECASE
                )
                version = int(version_match.group(1)) if version_match else 1

                if version not in migrations:
                    migrations[version] = []
                migrations[version].append(
                    {"table": table, "column": column, "definition": definition}
                )
                logger.debug(f"Added migration v{version}: {table}.{column}")

    logger.info(f"Parsed {len(migrations)} migration versions from {sql_file}")
    return migrations


def migrate_schema(con) -> None:
    """
    Migrate database schema to latest version by applying necessary updates.
    Reapplies all SQL files to ensure tables are created and updated.
    """
    logger.info("Starting schema migration")

    cursor = con.cursor()

    try:
        # Create schema_migrations table if it doesn't exist
        cursor.execute(
            """
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version INTEGER PRIMARY KEY,
            description TEXT NOT NULL,
            applied_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
        """
        )

        # Get existing tables
        cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        )
        existing_tables = {row[0] for row in cursor.fetchall()}
        logger.info(f"Found {len(existing_tables)} existing tables")

        # Get SQL directory
        sql_dir = Path(__file__).parent

        # Load and apply all SQL files to ensure tables exist
        # This is safe because the SQL files use CREATE TABLE IF NOT EXISTS
        for sql_filename in [
            "account.sql",
            "categories.sql",
            "evidence.sql",
            "assets.sql",
            "translations.sql",
            "product.sql",
        ]:
            sql_file = sql_dir / sql_filename
            if not sql_file.exists():
                logger.warning(f"SQL file not found: {sql_file}")
                continue

            logger.info(f"Applying schema from {sql_filename}")
            with open(sql_file, "r") as f:
                sql_script = f.read()
                # Execute the SQL to ensure all tables exist
                if "executescript" in dir(con):
                    con.executescript(sql_script)
                else:
                    con.execute(sql_script)

        # Get updated list of tables
        cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        )
        updated_tables = {row[0] for row in cursor.fetchall()}

        # Record which tables were added
        new_tables = updated_tables - existing_tables
        if new_tables:
            logger.info(f"Added {len(new_tables)} new tables: {', '.join(new_tables)}")

            # Record migration in schema_migrations table
            version = 1  # Starting with version 1
            cursor.execute("SELECT COALESCE(MAX(version), 0) FROM schema_migrations")
            last_version = cursor.fetchone()[0]
            if last_version >= version:
                version = last_version + 1

            description = f"Added tables: {', '.join(new_tables)}"
            cursor.execute(
                "INSERT INTO schema_migrations (version, description) VALUES (?, ?)",
                (version, description),
            )
            con.commit()
        else:
            logger.info("No new tables added")

        # Ensure required teams exist
        if "teams" in updated_tables:
            logger.info("Ensuring required teams exist")
            ensure_teams(con)

    except Exception as e:
        logger.error(f"Schema migration failed: {e}")
        raise

    finally:
        cursor.close()

    logger.info("Schema migration completed")
