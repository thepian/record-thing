import os
import unittest
import sqlite3
from pathlib import Path
import tempfile
import shutil
import logging

# Use absolute imports to avoid relative import issues
from libs.record_thing.db.schema import (
    init_db_tables,
    ensure_owner_account,
    ensure_empty_db,
)
from libs.record_thing.commons import commons, DBP
from libs.record_thing.db.connection import connect_to_db

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.WARNING)  # Set to WARNING to reduce noise during tests


class TestDatabaseIntegration(unittest.TestCase):
    """Integration tests for the record_thing database functionality."""

    def setUp(self):
        """Set up test environment with a temporary database."""
        # Create a temporary directory for test databases
        self.temp_dir = Path(tempfile.mkdtemp())
        self.test_db_path = self.temp_dir / "test-record-thing.sqlite"

        # Connect to the test database
        self.conn = sqlite3.connect(self.test_db_path)
        self.conn.row_factory = sqlite3.Row

        # Initialize database tables
        init_db_tables(self.conn)

    def tearDown(self):
        """Clean up test environment."""
        self.conn.close()
        shutil.rmtree(self.temp_dir)

    def test_db_initialization(self):
        """Test that the database tables are properly initialized."""
        cursor = self.conn.cursor()

        # Check for tables that should exist
        expected_tables = [
            "accounts",
            "owners",
            "teams",
            "evidence",
            "evidence_type",
            "things",
            "requests",
            "product",
            "brand",
            "company",
        ]

        for table in expected_tables:
            cursor.execute(
                f"SELECT name FROM sqlite_master WHERE type='table' AND name=?",
                (table,),
            )
            self.assertIsNotNone(cursor.fetchone(), f"Table {table} should exist")

    def test_ensure_owner_account(self):
        """Test that ensure_owner_account creates the necessary records."""
        # Call the function
        owner_id = ensure_owner_account(self.conn)

        # Verify owner record exists
        cursor = self.conn.cursor()
        cursor.execute("SELECT account_id FROM owners")
        owner = cursor.fetchone()
        self.assertIsNotNone(owner)
        self.assertEqual(owner["account_id"], owner_id)

        # Verify account record exists
        cursor.execute(
            "SELECT account_id, name, username, email FROM accounts WHERE account_id = ?",
            (owner_id,),
        )
        account = cursor.fetchone()
        self.assertIsNotNone(account)
        self.assertEqual(account["account_id"], owner_id)
        self.assertEqual(account["name"], "Joe Schmoe")
        self.assertEqual(account["username"], "joe")
        self.assertEqual(account["email"], "joe@schmoe.com")

    def test_ensure_empty_db(self):
        """Test that ensure_empty_db creates a database file if it doesn't exist."""
        # Path for a non-existent database
        new_db_path = self.temp_dir / "new-db.sqlite"

        # Ensure the database doesn't exist initially
        self.assertFalse(new_db_path.exists())

        # Call the function
        ensure_empty_db(new_db_path)

        # Verify database was created
        self.assertTrue(new_db_path.exists())

        # Verify it's a valid SQLite database
        conn = sqlite3.connect(new_db_path)
        cursor = conn.cursor()
        cursor.execute("PRAGMA integrity_check")
        result = cursor.fetchone()
        conn.close()

        self.assertEqual(result[0], "ok")


class TestDefaultDatabase(unittest.TestCase):
    """Integration tests for the default record-thing.sqlite database."""

    def setUp(self):
        """Set up the test environment with the default database."""
        # Use the common DBP constant for default database path
        self.default_db_path = DBP

        # Skip tests if the default database doesn't exist
        if not self.default_db_path.exists():
            self.skipTest(f"Default database not found at {self.default_db_path}")

        # Connect to the default database
        self.conn = sqlite3.connect(self.default_db_path)
        self.conn.row_factory = sqlite3.Row

    def tearDown(self):
        """Clean up test environment."""
        if hasattr(self, "conn"):
            self.conn.close()

    def test_connection_to_default_db(self):
        """Test connection to the default database."""
        cursor = self.conn.cursor()

        # Verify connection works by running a simple query
        cursor.execute("PRAGMA integrity_check")
        result = cursor.fetchone()
        self.assertEqual(result[0], "ok", "Default database integrity check failed")

    def test_default_db_tables(self):
        """Test that the default database has all the required tables."""
        cursor = self.conn.cursor()

        # Get a list of all tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [row["name"] for row in cursor.fetchall()]

        # Check for required tables
        required_tables = [
            "accounts",
            "owners",
            "teams",
            "evidence",
            "evidence_type",
            "things",
            "requests",
        ]

        for table in required_tables:
            self.assertIn(
                table, tables, f"Required table {table} not found in default database"
            )

    def test_default_db_owner_account(self):
        """Test that the default database has an owner account."""
        cursor = self.conn.cursor()

        # Check for owner account
        cursor.execute("SELECT account_id FROM owners LIMIT 1")
        owner = cursor.fetchone()
        self.assertIsNotNone(owner, "Default database should have an owner account")

        # Check the owner account exists in accounts table
        owner_id = owner["account_id"]
        cursor.execute(
            "SELECT name, username, email FROM accounts WHERE account_id = ?",
            (owner_id,),
        )
        account = cursor.fetchone()
        self.assertIsNotNone(account, "Owner account not found in accounts table")


if __name__ == "__main__":
    unittest.main()
