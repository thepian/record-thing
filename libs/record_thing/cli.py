#!/usr/bin/env python
"""
CLI utilities for Record Thing.
"""
import argparse
import logging
import sys
from pathlib import Path
from typing import Optional

from .commons import DBP
from .db.connection import connect_to_db, get_db_tables, test_connection
from .db.operations import show_database_info
from .db.schema import ensure_empty_db, ensure_teams
from .db_setup import create_database, create_tables, insert_sample_data, update_schema

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def init_db_command(args) -> None:
    """Initialize the database."""
    db_path = args.db_path or DBP

    # Check if the database exists
    exists = db_path.exists()

    if exists and not args.force:
        logger.info(f"Database already exists at {db_path}")
        logger.info("Use --force to reset the database.")
        show_database_info(db_path)
        return

    # Create or reset the database
    logger.info(f"{'Creating' if not exists else 'Resetting'} database at {db_path}")
    # Ensure directory exists
    db_path.parent.mkdir(parents=True, exist_ok=True)
    # First make sure file can be created
    ensure_empty_db(db_path)
    # Then create the database
    create_database(db_path)

    logger.info("Database initialization complete.")
    show_database_info(db_path)


def update_db_command(args) -> None:
    """Update the database schema without losing data."""
    db_path = args.db_path or DBP

    # Check if the database exists
    if not db_path.exists():
        logger.error(f"Database not found at {db_path}")
        logger.info("Run 'init-db' to create a new database.")
        return

    logger.info(f"Updating database schema at {db_path}")

    try:
        # Use the update_schema function from db_setup.py
        update_schema(db_path)

        # Show the updated database info
        show_database_info(db_path)
    except Exception as e:
        logger.error(f"Failed to update database: {e}")
        sys.exit(1)


def tables_db_command(args) -> None:
    """Create tables in the database without sample data."""
    db_path = args.db_path or DBP

    logger.info(f"Creating tables in database at {db_path}")

    try:
        # Use the create_tables function from db_setup.py
        create_tables(db_path)

        # Show the database info
        show_database_info(db_path)
    except Exception as e:
        logger.error(f"Failed to create tables: {e}")
        sys.exit(1)


def populate_db_command(args) -> None:
    """Insert sample data into the database."""
    db_path = args.db_path or DBP

    # Check if the database exists
    if not db_path.exists():
        logger.error(f"Database not found at {db_path}")
        logger.info("Run 'init-db' to create a new database.")
        return

    logger.info(f"Inserting sample data into database at {db_path}")

    try:
        # Use the insert_sample_data function from db_setup.py
        insert_sample_data(db_path)

        # Show the database info
        show_database_info(db_path)
    except Exception as e:
        logger.error(f"Failed to insert sample data: {e}")
        sys.exit(1)


def test_db_command(args) -> None:
    """Test database connection and display information."""
    db_path = args.db_path or DBP

    # Test the connection
    result = test_connection(db_path)
    if result:
        logger.info(f"✅ Successfully connected to database at {db_path}")

        # If verbose, show more information
        if args.verbose:
            conn = connect_to_db(db_path, read_only=True)
            try:
                tables = get_db_tables(conn)
                logger.info(f"Found {len(tables)} tables: {', '.join(tables)}")
            finally:
                conn.close()
    else:
        logger.error(f"❌ Failed to connect to database at {db_path}")
        sys.exit(1)


def main() -> None:
    """Main entry point for the CLI."""
    parser = argparse.ArgumentParser(description="Record Thing CLI")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # init-db command
    init_db_parser = subparsers.add_parser("init-db", help="Initialize the database")
    init_db_parser.add_argument(
        "--db-path", type=Path, help=f"Path to the database (default: {DBP})"
    )
    init_db_parser.add_argument(
        "--force",
        action="store_true",
        help="Force reset of the database if it already exists",
    )
    init_db_parser.set_defaults(func=init_db_command)

    # update-db command
    update_db_parser = subparsers.add_parser(
        "update-db", help="Update database schema without data loss"
    )
    update_db_parser.add_argument(
        "--db-path", type=Path, help=f"Path to the database (default: {DBP})"
    )
    update_db_parser.set_defaults(func=update_db_command)

    # tables-db command
    tables_db_parser = subparsers.add_parser(
        "tables-db", help="Create tables without sample data"
    )
    tables_db_parser.add_argument(
        "--db-path", type=Path, help=f"Path to the database (default: {DBP})"
    )
    tables_db_parser.set_defaults(func=tables_db_command)

    # populate-db command
    populate_db_parser = subparsers.add_parser(
        "populate-db", help="Insert sample data into the database"
    )
    populate_db_parser.add_argument(
        "--db-path", type=Path, help=f"Path to the database (default: {DBP})"
    )
    populate_db_parser.set_defaults(func=populate_db_command)

    # test-db command
    test_db_parser = subparsers.add_parser("test-db", help="Test database connection")
    test_db_parser.add_argument(
        "--db-path", type=Path, help=f"Path to the database (default: {DBP})"
    )
    test_db_parser.add_argument(
        "-v", "--verbose", action="store_true", help="Show detailed information"
    )
    test_db_parser.set_defaults(func=test_db_command)

    # Parse arguments
    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        sys.exit(1)

    # Execute the command
    args.func(args)


if __name__ == "__main__":
    main()
