#!/usr/bin/env python
"""
CLI utilities for Record Thing.
"""
import argparse
import sys
from pathlib import Path
from typing import Optional

from . import create_database, test_connection, ensure_empty_db, insert_sample_data, DBP


def init_db_command(args) -> None:
    """Initialize the database."""
    db_path = args.db_path or DBP
    
    # Check if the database exists
    exists = db_path.exists()
    
    if exists and not args.force:
        print(f"Database already exists at {db_path}")
        print("Use --force to reset the database.")
        test_connection(db_path)
        return
    
    # Create or reset the database
    print(f"{'Creating' if not exists else 'Resetting'} database at {db_path}")
    create_database(db_path)
    
    print("Database initialization complete.")
    test_connection(db_path)


def main() -> None:
    """Main entry point for the CLI."""
    parser = argparse.ArgumentParser(description="Record Thing CLI")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # init-db command
    init_db_parser = subparsers.add_parser("init-db", help="Initialize the database")
    init_db_parser.add_argument(
        "--db-path", 
        type=Path, 
        help=f"Path to the database (default: {DBP})"
    )
    init_db_parser.add_argument(
        "--force", 
        action="store_true", 
        help="Force reset of the database if it already exists"
    )
    init_db_parser.set_defaults(func=init_db_command)
    
    # Parse arguments
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        sys.exit(1)
        
    # Execute the command
    args.func(args)


if __name__ == "__main__":
    main()