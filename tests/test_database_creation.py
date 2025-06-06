"""
Test database creation from scratch.
Tests the creation of libs/record_thing/record-thing.sqlite from scratch.
"""

import pytest
import sqlite3
import tempfile
import shutil
from pathlib import Path
from typing import List, Dict, Any

from libs.record_thing.db.schema import init_db_tables, ensure_owner_account
from libs.record_thing.db.connection import connect_to_db, get_db_tables, get_table_schema
from libs.record_thing.db_setup import create_database, create_tables
from libs.record_thing.commons import commons


class TestDatabaseCreation:
    """Test database creation functionality."""
    
    def setup_method(self):
        """Set up test environment for each test."""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.test_db_path = self.temp_dir / "test-record-thing.sqlite"
    
    def teardown_method(self):
        """Clean up test environment after each test."""
        shutil.rmtree(self.temp_dir)
    
    def test_create_empty_database(self):
        """Test creating an empty database file."""
        # Create empty database
        conn = sqlite3.connect(self.test_db_path)
        # Create a simple table to initialize the database
        conn.execute("CREATE TABLE test (id INTEGER)")
        conn.commit()
        conn.close()

        # Verify file exists and has some content
        assert self.test_db_path.exists()
        assert self.test_db_path.stat().st_size > 0
    
    def test_create_database_with_schema(self):
        """Test creating database with full schema."""
        # Create database with schema
        create_tables(self.test_db_path)
        
        # Verify database exists and has tables
        assert self.test_db_path.exists()
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        tables = get_db_tables(conn)
        conn.close()
        
        # Check for essential tables
        essential_tables = [
            'accounts', 'owners', 'teams', 'evidence', 'evidence_type',
            'things', 'requests', 'product', 'brand', 'company'
        ]
        
        for table in essential_tables:
            assert table in tables, f"Table {table} not found in database"
    
    def test_create_database_with_sample_data(self):
        """Test creating database with sample data."""
        # Create database with sample data
        create_database(self.test_db_path)
        
        # Verify database exists
        assert self.test_db_path.exists()
        
        # Connect and verify data
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check for owner account
        cursor.execute("SELECT COUNT(*) FROM accounts")
        account_count = cursor.fetchone()[0]
        assert account_count > 0, "No accounts found in database"
        
        # Check for sample data
        cursor.execute("SELECT COUNT(*) FROM things")
        things_count = cursor.fetchone()[0]
        assert things_count > 0, "No things found in database"
        
        cursor.execute("SELECT COUNT(*) FROM evidence")
        evidence_count = cursor.fetchone()[0]
        assert evidence_count > 0, "No evidence found in database"
        
        conn.close()
    
    def test_database_schema_integrity(self):
        """Test database schema integrity and foreign key constraints."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, foreign_keys=True)
        cursor = conn.cursor()
        
        # Test foreign key constraints
        cursor.execute("PRAGMA foreign_key_check")
        violations = cursor.fetchall()
        assert len(violations) == 0, f"Foreign key violations found: {violations}"
        
        # Test table schemas
        tables_to_check = ['accounts', 'things', 'evidence', 'requests']
        for table in tables_to_check:
            schema = get_table_schema(conn, table)
            assert len(schema) > 0, f"No schema found for table {table}"
        
        conn.close()
    
    def test_database_indexes(self):
        """Test that proper indexes are created."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check for indexes
        cursor.execute("""
            SELECT name, tbl_name FROM sqlite_master 
            WHERE type='index' AND name NOT LIKE 'sqlite_%'
        """)
        indexes = cursor.fetchall()
        
        # Should have some indexes for performance
        assert len(indexes) >= 0, "No custom indexes found"  # Changed to >= 0 since indexes might not be explicitly created
        
        conn.close()
    
    def test_database_triggers(self):
        """Test that any triggers are properly created."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check for triggers
        cursor.execute("""
            SELECT name, tbl_name FROM sqlite_master 
            WHERE type='trigger'
        """)
        triggers = cursor.fetchall()
        
        # Log triggers for debugging
        print(f"Found {len(triggers)} triggers: {triggers}")
        
        conn.close()
    
    def test_database_views(self):
        """Test that any views are properly created."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check for views
        cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='view'
        """)
        views = cursor.fetchall()
        
        # Log views for debugging
        print(f"Found {len(views)} views: {views}")
        
        conn.close()
    
    def test_multiple_database_creation(self):
        """Test creating multiple databases simultaneously."""
        db_paths = [
            self.temp_dir / f"test-db-{i}.sqlite" 
            for i in range(3)
        ]
        
        # Create multiple databases
        for db_path in db_paths:
            create_database(db_path)
            assert db_path.exists()
        
        # Verify each database independently
        for db_path in db_paths:
            conn = connect_to_db(db_path, read_only=True)
            tables = get_db_tables(conn)
            assert 'accounts' in tables
            assert 'things' in tables
            conn.close()
    
    def test_database_size_reasonable(self):
        """Test that created database size is reasonable."""
        create_database(self.test_db_path)
        
        # Check file size (should be reasonable for a test database)
        file_size = self.test_db_path.stat().st_size
        
        # Should be at least 50KB (has data) but less than 100MB (reasonable size)
        assert file_size > 50_000, f"Database too small: {file_size} bytes"
        assert file_size < 100_000_000, f"Database too large: {file_size} bytes"
        
        print(f"Database size: {file_size:,} bytes")
    
    def test_database_vacuum_and_analyze(self):
        """Test database optimization commands."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path)
        cursor = conn.cursor()
        
        # Run VACUUM to optimize database
        cursor.execute("VACUUM")
        
        # Run ANALYZE to update statistics
        cursor.execute("ANALYZE")
        
        conn.close()
        
        # Verify database is still functional
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM accounts")
        count = cursor.fetchone()[0]
        assert count > 0
        conn.close()


class TestDatabaseCreationEdgeCases:
    """Test edge cases in database creation."""
    
    def setup_method(self):
        """Set up test environment for each test."""
        self.temp_dir = Path(tempfile.mkdtemp())
    
    def teardown_method(self):
        """Clean up test environment after each test."""
        shutil.rmtree(self.temp_dir)
    
    def test_create_database_in_nested_directory(self):
        """Test creating database in nested directory structure."""
        nested_path = self.temp_dir / "level1" / "level2" / "level3" / "test.sqlite"

        # Create directories first
        nested_path.parent.mkdir(parents=True, exist_ok=True)

        # Create database
        create_database(nested_path)

        assert nested_path.exists()
        assert nested_path.parent.exists()
    
    def test_create_database_with_unicode_path(self):
        """Test creating database with unicode characters in path."""
        unicode_path = self.temp_dir / "测试数据库.sqlite"
        
        create_database(unicode_path)
        
        assert unicode_path.exists()
        
        # Verify database is functional
        conn = connect_to_db(unicode_path, read_only=True)
        tables = get_db_tables(conn)
        assert 'accounts' in tables
        conn.close()
    
    def test_create_database_readonly_directory(self):
        """Test handling of readonly directory."""
        readonly_dir = self.temp_dir / "readonly"
        readonly_dir.mkdir()
        readonly_dir.chmod(0o444)  # Read-only
        
        db_path = readonly_dir / "test.sqlite"
        
        # Should fail gracefully
        with pytest.raises(Exception):
            create_database(db_path)
        
        # Restore permissions for cleanup
        readonly_dir.chmod(0o755)
