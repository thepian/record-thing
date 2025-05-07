import logging
import sqlite3
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union

from ..commons import DBP, commons
from .schema import ensure_owner_account, init_db_tables

# Create logger
logger = logging.getLogger(__name__)


def connect_to_db(
    db_path: Optional[Union[str, Path]] = None,
    read_only: bool = False,
    init_if_missing: bool = True,
    foreign_keys: bool = True,
) -> sqlite3.Connection:
    """
    Connect to the SQLite database with appropriate settings.

    Args:
        db_path: Path to the database file (uses default if None)
        read_only: Whether to open the database in read-only mode
        init_if_missing: Whether to initialize tables if they don't exist
        foreign_keys: Whether to enable foreign key constraints

    Returns:
        SQLite connection object
    """
    # Use default path if none provided
    if db_path is None:
        db_path = DBP

    # Convert to Path object if string
    if isinstance(db_path, str):
        db_path = Path(db_path)

    # Handle read-only connections
    if read_only:
        if not db_path.exists():
            raise FileNotFoundError(f"Database file not found: {db_path}")

        # Connect using URI with immutable flag
        conn = sqlite3.connect(f"file:{db_path}?immutable=1", uri=True)
    else:
        # Regular connection
        conn = sqlite3.connect(db_path)

    # Configure connection
    conn.row_factory = sqlite3.Row

    # Enable foreign keys if requested
    if foreign_keys:
        conn.execute("PRAGMA foreign_keys = ON")

    # Initialize tables if needed and requested
    if not read_only and init_if_missing:
        if not db_path.exists() or is_empty_db(conn):
            logger.info(f"Initializing database tables in {db_path}")
            init_db_tables(conn)
            ensure_owner_account(conn)

    return conn


def is_empty_db(conn: sqlite3.Connection) -> bool:
    """
    Check if the database is empty (no tables).

    Args:
        conn: SQLite connection

    Returns:
        True if the database has no tables, False otherwise
    """
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    return len(tables) == 0


def test_connection(db_path: Optional[Union[str, Path]] = None) -> bool:
    """
    Test if we can connect to the database and if it has the expected structure.

    Args:
        db_path: Path to the database file (uses default if None)

    Returns:
        True if connection successful and database has expected tables
    """
    try:
        conn = connect_to_db(db_path, read_only=True, init_if_missing=False)

        # Check for essential tables
        cursor = conn.cursor()
        cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name IN (?, ?, ?)",
            ("accounts", "owners", "evidence"),
        )
        tables = cursor.fetchall()

        # Close connection
        conn.close()

        # All three essential tables should exist
        return len(tables) >= 3

    except Exception as e:
        logger.error(f"Connection test failed: {e}")
        return False


def get_db_tables(conn: sqlite3.Connection) -> List[str]:
    """
    Get a list of all tables in the database.

    Args:
        conn: SQLite connection

    Returns:
        List of table names
    """
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    return [row[0] for row in cursor.fetchall()]


def get_table_schema(conn: sqlite3.Connection, table_name: str) -> List[Dict[str, Any]]:
    """
    Get the schema for a specific table.

    Args:
        conn: SQLite connection
        table_name: Name of the table

    Returns:
        List of column definitions
    """
    cursor = conn.cursor()
    cursor.execute(f"PRAGMA table_info({table_name})")
    columns = []
    for row in cursor.fetchall():
        columns.append(
            {
                "cid": row[0],
                "name": row[1],
                "type": row[2],
                "notnull": row[3],
                "default_value": row[4],
                "pk": row[5],
            }
        )
    return columns


def show_database_info(db_path: Path) -> None:
    """
    Display information about the RecordThing database tables.

    Args:
        db_path: Path to the database file
    """
    if not db_path.exists():
        logger.error(f"Database file not found: {db_path}")
        return

    con = None

    try:
        # Connect directly to the SQLite database
        con = sqlite3.connect(str(db_path))
        cursor = con.cursor()

        # Get list of tables
        cursor.execute(
            """
            SELECT name, type
            FROM sqlite_master 
            WHERE type='table' 
            AND name NOT LIKE 'sqlite_%'
            ORDER BY name
        """
        )

        tables = cursor.fetchall()

        # Print table information
        print("\nDatabase Tables:")
        print(f"{'Table Name':<30} {'Type':<10} {'Row Count':<10}")
        print("-" * 50)

        for table_name, table_type in tables:
            # Get row count for this table
            cursor.execute(f"SELECT COUNT(*) FROM '{table_name}'")
            count = cursor.fetchone()[0]

            print(f"{table_name:<30} {table_type:<10} {count:<10}")

        # Also print some database stats
        cursor.execute("PRAGMA database_list")
        db_info = cursor.fetchall()
        print("\nDatabase Information:")
        for db in db_info:
            print(f"Database: {db[1]}, File: {db[2]}")

        # Get database size
        db_size = Path(db_path).stat().st_size
        print(f"Database Size: {db_size / 1024 / 1024:.2f} MB")

    except Exception as e:
        logger.error(f"Error showing database info: {e}")
    finally:
        if con:
            con.close()
