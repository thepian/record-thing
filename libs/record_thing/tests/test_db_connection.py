import unittest
import sqlite3
from pathlib import Path
import tempfile
import shutil
import os

# Use absolute imports to avoid relative import issues
from libs.record_thing.commons import DBP
from libs.record_thing.db.connection import (
    connect_to_db,
    is_empty_db,
    test_connection,
    get_db_tables,
    get_table_schema,
)


class TestDBConnection(unittest.TestCase):
    """Test the database connection utility functions."""

    def setUp(self):
        """Set up test environment."""
        # Create a temporary directory for test files
        self.temp_dir = Path(tempfile.mkdtemp())

        # Path to the default database
        self.default_db_path = DBP

    def tearDown(self):
        """Clean up test environment."""
        shutil.rmtree(self.temp_dir)

    def test_connect_to_db_default(self):
        """Test connecting to the default database."""
        # Skip if default database doesn't exist
        if not self.default_db_path.exists():
            self.skipTest(f"Default database not found at {self.default_db_path}")

        # Connect to the default database
        conn = connect_to_db(read_only=True, init_if_missing=False)

        # Test connection is valid
        cursor = conn.cursor()
        cursor.execute("PRAGMA integrity_check")
        result = cursor.fetchone()
        self.assertEqual(result[0], "ok")

        # Clean up
        conn.close()

    def test_connect_to_db_new(self):
        """Test connecting to a new database."""
        # Create path for a new database
        new_db_path = self.temp_dir / "new-db.sqlite"

        # Connect and initialize
        conn = connect_to_db(new_db_path, init_if_missing=True)

        # Check tables were created
        tables = get_db_tables(conn)
        required_tables = ["accounts", "owners", "teams"]
        for table in required_tables:
            self.assertIn(table, tables)

        # Clean up
        conn.close()

    def test_connect_readonly(self):
        """Test connecting in read-only mode."""
        # Create and initialize a test database
        test_db_path = self.temp_dir / "readonly-test.sqlite"

        # Create database with a simple table
        setup_conn = sqlite3.connect(test_db_path)
        setup_conn.execute("CREATE TABLE test (id INTEGER PRIMARY KEY, value TEXT)")
        setup_conn.execute("INSERT INTO test (value) VALUES (?)", ("test value",))
        setup_conn.commit()
        setup_conn.close()

        # Connect in read-only mode
        conn = connect_to_db(test_db_path, read_only=True, init_if_missing=False)

        # Test we can read
        cursor = conn.cursor()
        cursor.execute("SELECT value FROM test")
        result = cursor.fetchone()
        self.assertEqual(result[0], "test value")

        # Test we cannot write
        with self.assertRaises(sqlite3.OperationalError):
            cursor.execute("INSERT INTO test (value) VALUES (?)", ("new value",))

        # Clean up
        conn.close()

    def test_is_empty_db(self):
        """Test the is_empty_db function."""
        # Create an empty database
        empty_db_path = self.temp_dir / "empty.sqlite"
        empty_conn = sqlite3.connect(empty_db_path)

        # Test it's empty
        self.assertTrue(is_empty_db(empty_conn))

        # Add a table and test again
        empty_conn.execute("CREATE TABLE test (id INTEGER PRIMARY KEY)")
        self.assertFalse(is_empty_db(empty_conn))

        # Clean up
        empty_conn.close()

    def test_test_connection(self):
        """Test the test_connection function."""
        # Skip if default database doesn't exist
        if not self.default_db_path.exists():
            self.skipTest(f"Default database not found at {self.default_db_path}")

        # Test that the database file exists
        print(f"Testing connection to database at {self.default_db_path}")
        print(f"Database exists: {self.default_db_path.exists()}")

        # Create a connection manually and check tables
        try:
            conn = sqlite3.connect(self.default_db_path)
            cursor = conn.cursor()
            cursor.execute(
                "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('accounts', 'owners', 'teams')"
            )
            tables = cursor.fetchall()
            print(f"Essential tables found: {tables}")
            conn.close()
        except Exception as e:
            print(f"Error checking tables manually: {e}")

        # Test connection to default database
        result = test_connection()
        self.assertTrue(
            result, f"Connection test failed for database at {self.default_db_path}"
        )

        # Test connection to a non-existent database
        result = test_connection(self.temp_dir / "nonexistent.sqlite")
        self.assertFalse(result)

        # Test connection to an empty database
        empty_db_path = self.temp_dir / "empty.sqlite"
        sqlite3.connect(empty_db_path).close()
        result = test_connection(empty_db_path)
        self.assertFalse(result)

    def test_get_db_tables(self):
        """Test the get_db_tables function."""
        # Create a test database with multiple tables
        test_db_path = self.temp_dir / "tables-test.sqlite"
        conn = sqlite3.connect(test_db_path)

        # Create tables
        conn.execute("CREATE TABLE table1 (id INTEGER PRIMARY KEY)")
        conn.execute("CREATE TABLE table2 (id INTEGER PRIMARY KEY)")
        conn.execute("CREATE TABLE table3 (id INTEGER PRIMARY KEY)")

        # Test function
        tables = get_db_tables(conn)

        # Should have 3 tables
        self.assertEqual(len(tables), 3)
        self.assertIn("table1", tables)
        self.assertIn("table2", tables)
        self.assertIn("table3", tables)

        # Clean up
        conn.close()

    def test_get_table_schema(self):
        """Test the get_table_schema function."""
        # Create a test database with a table that has various column types
        test_db_path = self.temp_dir / "schema-test.sqlite"
        conn = sqlite3.connect(test_db_path)

        # Create a table with different column types and constraints
        conn.execute(
            """
            CREATE TABLE test_table (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                value REAL DEFAULT 0.0,
                is_active INTEGER DEFAULT 1,
                description TEXT
            )
        """
        )

        # Test function
        schema = get_table_schema(conn, "test_table")

        # Should have 5 columns
        self.assertEqual(len(schema), 5)

        # Check column details
        columns = {col["name"]: col for col in schema}

        # id column
        self.assertEqual(columns["id"]["type"], "INTEGER")
        self.assertEqual(columns["id"]["pk"], 1)

        # name column
        self.assertEqual(columns["name"]["type"], "TEXT")
        self.assertEqual(columns["name"]["notnull"], 1)

        # value column
        self.assertEqual(columns["value"]["type"], "REAL")
        self.assertEqual(columns["value"]["default_value"], "0.0")

        # is_active column
        self.assertEqual(columns["is_active"]["type"], "INTEGER")
        self.assertEqual(columns["is_active"]["default_value"], "1")

        # description column
        self.assertEqual(columns["description"]["type"], "TEXT")
        self.assertEqual(columns["description"]["notnull"], 0)

        # Clean up
        conn.close()


if __name__ == "__main__":
    unittest.main()
