"""
Record Thing Python Library
==========================

A comprehensive library for managing physical item records,
evidence, and related functionality.
"""

__version__ = "0.1.0"

# Expose CLI entrypoint
from .cli import main as cli_main

# Core commons
from .commons import DBP, commons, create_uid
from .db.connection import (
    connect_to_db,
    get_db_tables,
    get_table_schema,
    is_empty_db,
    show_database_info,
    test_connection,
)
from .db.schema import ensure_empty_db, init_categories, init_db_tables, init_evidence

# Main public API exposed without needing to import from submodules
from .db_setup import create_database, insert_sample_data

__all__ = [
    # Commons
    "DBP",
    "commons",
    "create_uid",
    # Database setup
    "create_database",
    "insert_sample_data",
    "show_database_info",
    # Database connection
    "connect_to_db",
    "test_connection",
    "is_empty_db",
    "get_db_tables",
    "get_table_schema",
    # Schema management
    "init_db_tables",
    "init_evidence",
    "init_categories",
    "ensure_empty_db",
    # CLI
    "cli_main",
    # Version
    "__version__",
]
