"""
Setup functions for initializing the database.
These are utilities used primarily by the CLI to setup databases.
"""

import logging
import sqlite3
from pathlib import Path
from typing import Optional

from .db.operations import create_database as _create_database
from .db.operations import insert_sample_data as _insert_sample_data
from .db.schema import init_db_tables, migrate_schema

# Configure logging
logger = logging.getLogger(__name__)


def create_database(
    db_path: Path, connection: Optional[sqlite3.Connection] = None
) -> None:
    """
    Create a new database with the RecordThing schema.

    Args:
        db_path: Path to the database file
        connection: Optional existing connection (creates a new one if not provided)
    """
    if connection is None:
        # Create a new connection if one wasn't provided
        connection = sqlite3.connect(db_path)
        should_close = True
    else:
        should_close = False

    try:
        # Call the actual database creation function
        _create_database(connection, db_path)
        logger.info(f"Database created successfully at {db_path}")
    finally:
        # Only close the connection if we created it
        if should_close and connection:
            connection.close()


def insert_sample_data(
    db_path: Path, connection: Optional[sqlite3.Connection] = None
) -> None:
    """
    Insert sample data into the database.

    Args:
        db_path: Path to the database file
        connection: Optional existing connection (creates a new one if not provided)
    """
    if connection is None:
        # Create a new connection if one wasn't provided
        connection = sqlite3.connect(db_path)
        should_close = True
    else:
        should_close = False

    try:
        # Call the actual sample data insertion function
        _insert_sample_data(connection, db_path)
        logger.info(f"Sample data inserted successfully into {db_path}")
    finally:
        # Only close the connection if we created it
        if should_close and connection:
            connection.close()


def update_schema(db_path: Path) -> None:
    """
    Update the database schema to the latest version.

    Args:
        db_path: Path to the database file
    """
    if not db_path.exists():
        logger.error(f"Database file not found: {db_path}")
        return

    connection = None
    try:
        connection = sqlite3.connect(db_path)
        migrate_schema(connection)
        logger.info(f"Database schema updated successfully for {db_path}")
    except Exception as e:
        logger.error(f"Error updating database schema: {e}")
    finally:
        if connection:
            connection.close()


def create_tables(db_path: Path) -> None:
    """
    Create tables in the database without inserting sample data.

    Args:
        db_path: Path to the database file
    """
    connection = None
    try:
        connection = sqlite3.connect(db_path)
        init_db_tables(connection)
        logger.info(f"Database tables created successfully at {db_path}")
    except Exception as e:
        logger.error(f"Error creating database tables: {e}")
    finally:
        if connection:
            connection.close()
