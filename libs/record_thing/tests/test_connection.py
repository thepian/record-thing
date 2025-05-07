import unittest
import sqlite3
from pathlib import Path
import tempfile
import shutil
import os
import sys

# Add project root to path for absolute imports
project_root = Path(__file__).parent.parent.parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

# Use absolute imports to avoid relative import issues
from libs.record_thing.commons import DBP


class TestDatabaseConnection(unittest.TestCase):
    """Test database connection functionality."""

    def setUp(self):
        """Set up test environment."""
        # Use the common DBP constant for default database path
        self.default_db_path = DBP

        # Create a temporary directory for test files
        self.temp_dir = Path(tempfile.mkdtemp())

        # Set the repo root for relative path tests
        self.repo_root = project_root

    def tearDown(self):
        """Clean up test environment."""
        shutil.rmtree(self.temp_dir)

    def test_connect_to_default_db(self):
        """Test connecting to the default database."""
        # Skip if default database doesn't exist
        if not self.default_db_path.exists():
            self.skipTest(f"Default database not found at {self.default_db_path}")

        # Try to connect
        try:
            conn = sqlite3.connect(self.default_db_path)
            cursor = conn.cursor()

            # Check database integrity
            cursor.execute("PRAGMA integrity_check")
            result = cursor.fetchone()
            self.assertEqual(result[0], "ok", "Default database integrity check failed")

            # Check that we can query a table
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor.fetchall()
            self.assertTrue(len(tables) > 0, "Default database should have tables")

            conn.close()
        except sqlite3.Error as e:
            self.fail(f"Failed to connect to default database: {e}")

    def test_connect_with_different_paths(self):
        """Test connecting to the database with different path formats."""
        # Skip if default database doesn't exist
        if not self.default_db_path.exists():
            self.skipTest(f"Default database not found at {self.default_db_path}")

        # Test with absolute path
        try:
            conn = sqlite3.connect(str(self.default_db_path.absolute()))
            conn.close()
        except sqlite3.Error as e:
            self.fail(f"Failed to connect with absolute path: {e}")

        # Test with relative path (assuming test is run from project root)
        try:
            os.chdir(self.repo_root)
            relative_path = self.default_db_path.relative_to(self.repo_root)
            conn = sqlite3.connect(str(relative_path))
            conn.close()
        except sqlite3.Error as e:
            self.fail(f"Failed to connect with relative path: {e}")

    def test_readonly_connection(self):
        """Test connecting to the database in read-only mode."""
        # Skip if default database doesn't exist
        if not self.default_db_path.exists():
            self.skipTest(f"Default database not found at {self.default_db_path}")

        # Connect in read-only mode
        try:
            # URI connection with immutable flag
            conn = sqlite3.connect(f"file:{self.default_db_path}?immutable=1", uri=True)
            cursor = conn.cursor()

            # Read from the database
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor.fetchall()
            self.assertTrue(
                len(tables) > 0, "Should be able to read tables in read-only mode"
            )

            # Try to write (should fail)
            with self.assertRaises(sqlite3.OperationalError):
                cursor.execute("CREATE TABLE test_readonly (id INTEGER)")

            conn.close()
        except sqlite3.Error as e:
            self.fail(f"Failed in read-only test: {e}")

    def test_create_new_connection(self):
        """Test creating a new database connection."""
        new_db_path = self.temp_dir / "new-record-thing.sqlite"

        # Create a new database
        try:
            conn = sqlite3.connect(new_db_path)

            # Create a simple table
            conn.execute("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
            conn.execute("INSERT INTO test (name) VALUES (?)", ("Test Record",))
            conn.commit()

            # Verify the data was written
            cursor = conn.execute("SELECT name FROM test")
            result = cursor.fetchone()
            self.assertEqual(result[0], "Test Record")

            conn.close()

            # Verify the file was created
            self.assertTrue(new_db_path.exists())
        except sqlite3.Error as e:
            self.fail(f"Failed to create new database: {e}")

    def test_connection_with_foreign_keys(self):
        """Test connection with foreign key constraints enabled."""
        # Create a test database with foreign key relationships
        test_db_path = self.temp_dir / "foreign-keys-test.sqlite"

        try:
            conn = sqlite3.connect(test_db_path)

            # Enable foreign keys
            conn.execute("PRAGMA foreign_keys = ON")

            # Create parent and child tables
            conn.execute(
                """
                CREATE TABLE parent (
                    id INTEGER PRIMARY KEY,
                    name TEXT
                )
            """
            )

            conn.execute(
                """
                CREATE TABLE child (
                    id INTEGER PRIMARY KEY,
                    parent_id INTEGER,
                    name TEXT,
                    FOREIGN KEY (parent_id) REFERENCES parent(id)
                )
            """
            )

            # Insert parent record
            conn.execute("INSERT INTO parent (name) VALUES (?)", ("Parent Record",))

            # Insert child record with valid parent
            conn.execute(
                "INSERT INTO child (parent_id, name) VALUES (?, ?)", (1, "Child Record")
            )

            # Try to insert child with invalid parent (should fail)
            with self.assertRaises(sqlite3.IntegrityError):
                conn.execute(
                    "INSERT INTO child (parent_id, name) VALUES (?, ?)",
                    (999, "Invalid Child"),
                )

            conn.close()
        except sqlite3.Error as e:
            self.fail(f"Foreign key test failed: {e}")


if __name__ == "__main__":
    unittest.main()
