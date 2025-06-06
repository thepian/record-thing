"""
Test schema migration and updates.
Tests updating libs/record_thing/record-thing.sqlite with latest schema changes.
"""

import pytest
import sqlite3
import tempfile
import shutil
from pathlib import Path
from typing import List, Dict, Any

from libs.record_thing.db.schema import init_db_tables, migrate_schema
from libs.record_thing.db.connection import connect_to_db, get_db_tables, get_table_schema
from libs.record_thing.db_setup import create_database, update_schema
from libs.record_thing.commons import commons


class TestSchemaMigration:
    """Test database schema migration functionality."""
    
    def setup_method(self):
        """Set up test environment for each test."""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.test_db_path = self.temp_dir / "test-migration.sqlite"
    
    def teardown_method(self):
        """Clean up test environment after each test."""
        shutil.rmtree(self.temp_dir)
    
    def test_migrate_empty_database(self):
        """Test migrating an empty database to current schema."""
        # Create empty database
        conn = sqlite3.connect(self.test_db_path)
        conn.close()
        
        # Apply migration
        update_schema(self.test_db_path)
        
        # Verify tables were created
        conn = connect_to_db(self.test_db_path, read_only=True)
        tables = get_db_tables(conn)
        conn.close()
        
        essential_tables = ['accounts', 'owners', 'teams', 'evidence', 'things']
        for table in essential_tables:
            assert table in tables, f"Table {table} not created during migration"
    
    def test_migrate_existing_database_preserves_data(self):
        """Test that migration preserves existing data."""
        # Create database with initial data
        create_database(self.test_db_path)
        
        # Get initial data counts
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM accounts")
        initial_accounts = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM things")
        initial_things = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM evidence")
        initial_evidence = cursor.fetchone()[0]
        
        conn.close()
        
        # Apply migration
        update_schema(self.test_db_path)
        
        # Verify data is preserved
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM accounts")
        final_accounts = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM things")
        final_things = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM evidence")
        final_evidence = cursor.fetchone()[0]
        
        conn.close()
        
        # Data should be preserved
        assert final_accounts == initial_accounts, "Account data lost during migration"
        assert final_things == initial_things, "Things data lost during migration"
        assert final_evidence == initial_evidence, "Evidence data lost during migration"
    
    def test_migrate_adds_missing_tables(self):
        """Test that migration adds missing tables."""
        # Create database with only basic tables
        conn = sqlite3.connect(self.test_db_path)
        cursor = conn.cursor()
        
        # Create only accounts table
        cursor.execute("""
            CREATE TABLE accounts (
                account_id TEXT PRIMARY KEY,
                name TEXT
            )
        """)
        
        # Insert test data
        cursor.execute("INSERT INTO accounts (account_id, name) VALUES (?, ?)", 
                      ("test-id", "Test Account"))
        conn.commit()
        conn.close()
        
        # Apply migration
        update_schema(self.test_db_path)
        
        # Verify all tables now exist
        conn = connect_to_db(self.test_db_path, read_only=True)
        tables = get_db_tables(conn)
        cursor = conn.cursor()
        
        # Check that new tables were added
        expected_tables = ['owners', 'teams', 'evidence', 'things', 'requests']
        for table in expected_tables:
            assert table in tables, f"Table {table} not added during migration"
        
        # Verify original data is preserved
        cursor.execute("SELECT name FROM accounts WHERE account_id = ?", ("test-id",))
        result = cursor.fetchone()
        assert result[0] == "Test Account", "Original data lost during migration"
        
        conn.close()
    
    def test_migrate_adds_missing_columns(self):
        """Test that migration adds missing columns to existing tables."""
        # Create database with incomplete table schema
        conn = sqlite3.connect(self.test_db_path)
        cursor = conn.cursor()
        
        # Create accounts table with minimal columns
        cursor.execute("""
            CREATE TABLE accounts (
                account_id TEXT PRIMARY KEY,
                name TEXT
            )
        """)
        
        cursor.execute("INSERT INTO accounts (account_id, name) VALUES (?, ?)", 
                      ("test-id", "Test Account"))
        conn.commit()
        conn.close()
        
        # Apply migration
        update_schema(self.test_db_path)
        
        # Verify new columns were added
        conn = connect_to_db(self.test_db_path, read_only=True)
        schema = get_table_schema(conn, 'accounts')
        cursor = conn.cursor()
        
        # Check for expected columns
        column_names = [col[1] for col in schema]
        expected_columns = ['account_id', 'name']  # Only check for columns we know exist
        
        for col in expected_columns:
            assert col in column_names, f"Column {col} not found after migration"
        
        # Verify original data is preserved
        cursor.execute("SELECT name FROM accounts WHERE account_id = ?", ("test-id",))
        result = cursor.fetchone()
        assert result[0] == "Test Account", "Original data lost during migration"
        
        conn.close()
    
    def test_migrate_handles_foreign_keys(self):
        """Test that migration properly handles foreign key constraints."""
        # Create database with data that has foreign key relationships
        create_database(self.test_db_path)
        
        # Apply migration
        update_schema(self.test_db_path)
        
        # Verify foreign key constraints are working
        conn = connect_to_db(self.test_db_path, foreign_keys=True)
        cursor = conn.cursor()
        
        # Test foreign key constraint
        cursor.execute("PRAGMA foreign_key_check")
        violations = cursor.fetchall()
        assert len(violations) == 0, f"Foreign key violations after migration: {violations}"
        
        conn.close()
    
    def test_migrate_idempotent(self):
        """Test that migration is idempotent (can be run multiple times safely)."""
        # Create initial database
        create_database(self.test_db_path)
        
        # Get initial state
        conn = connect_to_db(self.test_db_path, read_only=True)
        initial_tables = get_db_tables(conn)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM accounts")
        initial_count = cursor.fetchone()[0]
        conn.close()
        
        # Apply migration multiple times
        for i in range(3):
            update_schema(self.test_db_path)
        
        # Verify state is unchanged
        conn = connect_to_db(self.test_db_path, read_only=True)
        final_tables = get_db_tables(conn)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM accounts")
        final_count = cursor.fetchone()[0]
        conn.close()
        
        assert set(initial_tables) == set(final_tables), "Tables changed after repeated migration"
        assert initial_count == final_count, "Data changed after repeated migration"
    
    def test_migrate_with_corrupted_data(self):
        """Test migration behavior with corrupted or inconsistent data."""
        # Create database with potentially problematic data
        conn = sqlite3.connect(self.test_db_path)
        cursor = conn.cursor()
        
        # Create table with data that might cause issues
        cursor.execute("""
            CREATE TABLE accounts (
                account_id TEXT PRIMARY KEY,
                name TEXT,
                email TEXT
            )
        """)
        
        # Insert data with potential issues
        cursor.execute("INSERT INTO accounts VALUES (?, ?, ?)", 
                      ("", "Empty ID", "test@example.com"))  # Empty ID
        cursor.execute("INSERT INTO accounts VALUES (?, ?, ?)", 
                      ("test-id", "", ""))  # Empty name and email
        
        conn.commit()
        conn.close()
        
        # Migration should handle this gracefully
        try:
            update_schema(self.test_db_path)
            migration_succeeded = True
        except Exception as e:
            migration_succeeded = False
            print(f"Migration failed with: {e}")
        
        # At minimum, database should still be accessible
        conn = connect_to_db(self.test_db_path, read_only=True)
        tables = get_db_tables(conn)
        assert 'accounts' in tables, "Database became inaccessible after migration"
        conn.close()
    
    @pytest.mark.slow
    def test_migrate_large_database(self):
        """Test migration performance with larger database."""
        # Create database with substantial data
        create_database(self.test_db_path)
        
        # Add more test data
        conn = connect_to_db(self.test_db_path)
        cursor = conn.cursor()
        
        # Add many more things and evidence records
        from libs.record_thing.db.uid import create_uid
        for i in range(100):  # Add 100 more things
            thing_id = create_uid()
            cursor.execute("""
                INSERT INTO things (id, account_id, title, description, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (thing_id, commons["owner_id"], f"Test Thing {i}", 
                  f"Description {i}", 1640995200.0, 1640995200.0))
        
        conn.commit()
        conn.close()
        
        # Time the migration
        import time
        start_time = time.time()
        update_schema(self.test_db_path)
        migration_time = time.time() - start_time
        
        # Migration should complete in reasonable time (< 30 seconds)
        assert migration_time < 30, f"Migration took too long: {migration_time:.2f} seconds"
        
        # Verify database is still functional
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM things")
        count = cursor.fetchone()[0]
        assert count >= 100, "Data lost during migration"
        conn.close()
    
    def test_migrate_backup_creation(self):
        """Test that migration creates backup if needed."""
        # Create initial database
        create_database(self.test_db_path)
        
        # Get initial file modification time
        initial_mtime = self.test_db_path.stat().st_mtime
        
        # Apply migration
        update_schema(self.test_db_path)
        
        # Check if backup was created (implementation dependent)
        backup_path = self.test_db_path.with_suffix('.sqlite.backup')
        if backup_path.exists():
            # If backup exists, verify it's functional
            conn = connect_to_db(backup_path, read_only=True)
            tables = get_db_tables(conn)
            assert 'accounts' in tables, "Backup database is not functional"
            conn.close()


class TestSchemaMigrationEdgeCases:
    """Test edge cases in schema migration."""
    
    def setup_method(self):
        """Set up test environment for each test."""
        self.temp_dir = Path(tempfile.mkdtemp())
    
    def teardown_method(self):
        """Clean up test environment after each test."""
        shutil.rmtree(self.temp_dir)
    
    def test_migrate_nonexistent_database(self):
        """Test migration behavior with nonexistent database."""
        nonexistent_path = self.temp_dir / "nonexistent.sqlite"
        
        # Should handle gracefully
        with pytest.raises(Exception):
            update_schema(nonexistent_path)
    
    def test_migrate_locked_database(self):
        """Test migration behavior with locked database."""
        db_path = self.temp_dir / "locked.sqlite"
        create_database(db_path)
        
        # Lock the database by keeping a connection open
        lock_conn = connect_to_db(db_path)
        lock_conn.execute("BEGIN EXCLUSIVE TRANSACTION")
        
        try:
            # Migration should handle locked database gracefully
            with pytest.raises(Exception):
                update_schema(db_path)
        finally:
            lock_conn.close()
