import os
import re
from pathlib import Path
import logging
from logging import Logger

from ..commons import commons

# Create logger
logger = logging.getLogger(__name__)

# Set up logging if not already configured
if not logger.handlers:
    handler = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)

# sql_dir.glob('*.sql')
SQL_FILES = [
    # 'account.sql',
    'categories.sql',
    'evidence.sql',
    'assets.sql',
    'translations.sql',
    'product.sql',
    # 'auth.sql',
    # 'vector.sql',
]

# TODO this needs to always be called
def ensure_owner_account(con, dummy_account_data = True) -> None:
    """
    Scenarios:
    1) No owners or accounts exist
    2) No owner exist, but accounts exist
    3) Owner exists, but no accounts exist
    4) Owner and accounts exist
    """
    cursor = con.cursor()
    cursor.execute("SELECT * FROM owners LIMIT 1")
    one_owner = cursor.fetchone()
    cursor.execute("SELECT * FROM accounts LIMIT 1")
    one_account = cursor.fetchone()

    if one_owner is None and one_account is None:
        cursor.execute("""
            INSERT OR IGNORE INTO accounts(account_id, name, username, email, sms, region) VALUES (?, ?, ?, ?, ?, ?);
            """, 
            [commons['account_id'], "Joe Schmoe", "joe", "joe@schmoe.com", "+0", "EU"], 
        )
        cursor.execute("INSERT OR IGNORE INTO owners(account_id) VALUES (?);", [commons['owner_id']])
    elif one_owner is None and one_account is not None:
        commons['account_id'] = one_account[0]
        commons['owner_id'] = one_account[0]
        cursor.execute("INSERT OR IGNORE INTO owners(account_id) VALUES (?);", [commons['owner_id']])
    elif one_owner is not None and one_account is None:
        commons['account_id'] = one_owner[0]
        commons['owner_id'] = one_owner[0]
        cursor.execute("""
            INSERT OR IGNORE INTO accounts(account_id, name, username, email, sms, region) VALUES (?, ?, ?, ?, ?, ?);
            """, 
            [commons['account_id'], "Joe Schmoe", "joe", "joe@schmoe.com", "+0", "EU"], 
        )
    else:
        commons['account_id'] = one_owner[0]
        commons['owner_id'] = one_owner[0]
    cursor.close()



def init_account(con, dummy_account_data = True) -> None:
    """
    Initialize account tables.
    
    Args:
        con: Database connection
    """
    with open(Path(__file__).parent / 'account.sql', 'r') as sql_file:
        sql_script = sql_file.read()
        if "executescript" in dir(con):
            con.executescript(sql_script)
        else:
            con.execute(sql_script)
    
    ensure_owner_account(con, dummy_account_data = dummy_account_data)

def init_categories(con) -> None:
    """
    Initialize category tables.
    
    Args:
        con: Database connection
    """
    with open(Path(__file__).parent / 'categories.sql', 'r') as sql_file:
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
    with open(Path(__file__).parent / 'evidence.sql', 'r') as sql_file:
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
    with open(Path(__file__).parent / 'assets.sql', 'r') as sql_file:
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
    with open(Path(__file__).parent / 'translations.sql', 'r') as sql_file:
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
    with open(Path(__file__).parent / 'product.sql', 'r') as sql_file:
        sql_script = sql_file.read()
        if "executescript" in dir(con):
            con.executescript(sql_script)
        else:
            con.execute(sql_script)

def init_db_tables(con, dummy_account_data = True) -> None:
    """
    Initialize all database tables in the correct order.
    
    Args:
        con: Database connection
    """
    # Initialize tables in dependency order
    init_account(con, dummy_account_data = dummy_account_data)
    init_categories(con)
    init_product(con)
    init_evidence(con)
    init_assets(con)
    init_translations(con)
    
    # Apply any schema migrations
    # migrate_schema(con)

    ensure_owner_account(con, dummy_account_data = dummy_account_data)


def parse_sql_schema(sql_file: Path) -> dict:
    """
    Parse SQL file to extract schema information and identify migrations.
    Returns a dictionary of migrations keyed by version.
    """
    migrations = {}
    current_table = None
    
    logger.debug(f"Parsing schema file: {sql_file}")
    
    with open(sql_file, 'r') as f:
        sql = f.read()
    
    # Split into statements
    statements = [s.strip() for s in sql.split(';') if s.strip()]
    logger.debug(f"Found {len(statements)} SQL statements")
    
    for statement in statements:
        # Look for CREATE TABLE statements
        if statement.upper().startswith('CREATE TABLE'):
            # Extract table name
            table_match = re.search(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?[`"]?(\w+)[`"]?\s*\((.*)\)', statement, re.IGNORECASE | re.DOTALL)
            if table_match:
                current_table = table_match.group(1)
                column_defs = table_match.group(2)
                logger.debug(f"Processing CREATE TABLE for {current_table}")
                
                # Split column definitions
                for column_def in re.split(r',\s*(?=\w)', column_defs):
                    column_def = column_def.strip()
                    if not column_def or column_def.startswith(('PRIMARY KEY', 'FOREIGN KEY', 'UNIQUE', 'CHECK')):
                        continue
                    
                    # Extract column name and type
                    col_match = re.match(r'[`"]?(\w+)[`"]?\s+([\w\(\),\s]+)(?:\s+(.*))?', column_def)
                    if col_match:
                        column_name = col_match.group(1)
                        column_type = col_match.group(2).strip()
                        constraints = col_match.group(3) or ''
                        
                        # Store base schema for comparison
                        if 0 not in migrations:
                            migrations[0] = []
                        migrations[0].append({
                            'table': current_table,
                            'column': column_name,
                            'definition': f"{column_type} {constraints}".strip()
                        })
                        logger.debug(f"Added base column: {current_table}.{column_name}")
        
        # Look for ALTER TABLE statements
        elif statement.upper().startswith('ALTER TABLE'):
            alter_match = re.search(r'ALTER\s+TABLE\s+[`"]?(\w+)[`"]?\s+ADD\s+(?:COLUMN\s+)?[`"]?(\w+)[`"]?\s+(.*)', statement, re.IGNORECASE)
            if alter_match:
                table = alter_match.group(1)
                column = alter_match.group(2)
                definition = alter_match.group(3).strip()
                
                # Look for version comment
                version_match = re.search(r'--\s*version:\s*(\d+)', statement, re.IGNORECASE)
                version = int(version_match.group(1)) if version_match else 1
                
                if version not in migrations:
                    migrations[version] = []
                migrations[version].append({
                    'table': table,
                    'column': column,
                    'definition': definition
                })
                logger.debug(f"Added migration v{version}: {table}.{column}")
    
    logger.info(f"Parsed {len(migrations)} migration versions from {sql_file}")
    return migrations

def migrate_schema(con) -> None:
    """
    Migrate database schema to latest version by applying necessary updates.
    Parses SQL files to identify needed migrations.
    """
    cursor = con.cursor()
    
    # Create schema_migrations table if it doesn't exist
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS schema_migrations (
        version INTEGER PRIMARY KEY,
        description TEXT NOT NULL,
    )
    """)
    # applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    
    # Get current schema version
    cursor.execute("SELECT COALESCE(MAX(version), 0) FROM schema_migrations")
    current_version = cursor.fetchone()[0]
    
    # Parse all SQL files in the db directory
    migrations = {}
    sql_dir = Path(__file__).parent
    logger.info(f"Looking for SQL files in {sql_dir}")
    
    for sql_file in SQL_FILES:
        logger.info(f"Processing {sql_file.name}")
        file_migrations = parse_sql_schema(sql_file)
        for version, changes in file_migrations.items():
            if version == 0:  # Base schema
                continue
            if version not in migrations:
                migrations[version] = []
            migrations[version].extend(changes)
    
    logger.info(f"Current schema version: {current_version}")
    logger.info(f"Found {len(migrations)} migration versions to process")
    
    try:
        # Apply each migration in order if it hasn't been applied yet
        for version in sorted(migrations.keys()):
            if version > current_version:
                logger.info(f"Applying migration version {version}")
                
                con.execute("BEGIN TRANSACTION")
                try:
                    # Group changes by table
                    changes_by_table = {}
                    for change in migrations[version]:
                        if change['table'] not in changes_by_table:
                            changes_by_table[change['table']] = []
                        changes_by_table[change['table']].append(change)
                    
                    # Apply changes for each table
                    for table, changes in changes_by_table.items():
                        description = f"Add columns to {table}: " + ", ".join(c['column'] for c in changes)
                        logger.info(description)
                        
                        for change in changes:
                            try:
                                sql = f"ALTER TABLE {table} ADD COLUMN {change['column']} {change['definition']}"
                                cursor.execute(sql)
                                logger.debug(f"Added column {change['column']} to {table}")
                            except Exception as e:
                                if "duplicate column name" in str(e).lower():
                                    logger.warning(f"Column already exists: {change['column']}")
                                else:
                                    raise
                    
                    # Record the migration
                    cursor.execute(
                        "INSERT OR IGNORE INTO schema_migrations (version, description) VALUES (?, ?)",
                        (version, description)
                    )
                    
                    con.commit()
                    logger.info(f"Successfully applied migration {version}")
                    
                except Exception as e:
                    con.rollback()
                    logger.error(f"Failed to apply migration {version}: {e}")
                    raise
    
    except Exception as e:
        logger.error(f"Schema migration failed: {e}")
        raise
    
    finally:
        cursor.close()

