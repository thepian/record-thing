"""
Full integration test suite.
Tests the complete workflow from database creation to iOS compatibility.
"""

import pytest
import sqlite3
import tempfile
import shutil
import json
from pathlib import Path
from typing import List, Dict, Any

from libs.record_thing.db.connection import connect_to_db, get_db_tables, test_connection
from libs.record_thing.db_setup import create_database, create_tables, insert_sample_data, update_schema
from libs.record_thing.cli import (
    init_db_command, update_db_command, populate_db_command, test_db_command
)
from libs.record_thing.commons import commons, DBP


class MockArgs:
    """Mock arguments for CLI commands."""
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)


class TestFullIntegration:
    """Full integration test suite."""
    
    def setup_method(self):
        """Set up test environment for each test."""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.test_db_path = self.temp_dir / "integration-test.sqlite"
    
    def teardown_method(self):
        """Clean up test environment after each test."""
        shutil.rmtree(self.temp_dir)
    
    def test_complete_database_lifecycle(self):
        """Test complete database lifecycle from creation to usage."""
        
        # Step 1: Create fresh database
        create_database(self.test_db_path)
        assert self.test_db_path.exists(), "Database file not created"
        
        # Step 2: Verify database structure
        conn = connect_to_db(self.test_db_path, read_only=True)
        tables = get_db_tables(conn)
        conn.close()
        
        required_tables = [
            'accounts', 'owners', 'teams', 'evidence', 'evidence_type',
            'things', 'requests', 'product', 'brand', 'company'
        ]
        
        for table in required_tables:
            assert table in tables, f"Required table {table} missing"
        
        # Step 3: Verify data was populated
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM accounts")
        account_count = cursor.fetchone()[0]
        assert account_count > 0, "No accounts created"
        
        cursor.execute("SELECT COUNT(*) FROM things")
        things_count = cursor.fetchone()[0]
        assert things_count > 0, "No things created"
        
        cursor.execute("SELECT COUNT(*) FROM evidence")
        evidence_count = cursor.fetchone()[0]
        assert evidence_count > 0, "No evidence created"
        
        conn.close()
        
        # Step 4: Test schema migration
        update_schema(self.test_db_path)
        
        # Verify data preserved after migration
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM accounts")
        final_account_count = cursor.fetchone()[0]
        assert final_account_count == account_count, "Data lost during migration"
        
        cursor.execute("SELECT COUNT(*) FROM things")
        final_things_count = cursor.fetchone()[0]
        assert final_things_count == things_count, "Things lost during migration"
        
        conn.close()
        
        # Step 5: Test database connection
        assert test_connection(self.test_db_path), "Connection test failed"
    
    def test_cli_integration(self):
        """Test CLI command integration."""
        
        # Test init-db command
        args = MockArgs(db_path=self.test_db_path, force=True)
        init_db_command(args)
        
        assert self.test_db_path.exists(), "CLI init-db failed to create database"
        
        # Test test-db command
        args = MockArgs(db_path=self.test_db_path, verbose=True)
        test_db_command(args)  # Should not raise exception
        
        # Test update-db command
        args = MockArgs(db_path=self.test_db_path)
        update_db_command(args)  # Should not raise exception
        
        # Verify database is still functional
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM accounts")
        count = cursor.fetchone()[0]
        assert count > 0, "Database not functional after CLI operations"
        conn.close()
    
    def test_data_consistency_across_operations(self):
        """Test data consistency across all operations."""
        
        # Create initial database
        create_database(self.test_db_path)
        
        # Get initial data fingerprint
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Create data fingerprint
        cursor.execute("SELECT account_id, name FROM accounts ORDER BY account_id")
        initial_accounts = cursor.fetchall()
        
        cursor.execute("SELECT id, title FROM things ORDER BY id")
        initial_things = cursor.fetchall()
        
        cursor.execute("SELECT id, name FROM evidence ORDER BY id")
        initial_evidence = cursor.fetchall()
        
        conn.close()
        
        # Perform schema update
        update_schema(self.test_db_path)
        
        # Verify data consistency after update
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        cursor.execute("SELECT account_id, name FROM accounts ORDER BY account_id")
        final_accounts = cursor.fetchall()
        
        cursor.execute("SELECT id, title FROM things ORDER BY id")
        final_things = cursor.fetchall()
        
        cursor.execute("SELECT id, name FROM evidence ORDER BY id")
        final_evidence = cursor.fetchall()
        
        conn.close()
        
        # Data should be identical
        assert initial_accounts == final_accounts, "Account data changed during update"
        assert initial_things == final_things, "Things data changed during update"
        assert initial_evidence == final_evidence, "Evidence data changed during update"
    
    def test_foreign_key_integrity_throughout_lifecycle(self):
        """Test foreign key integrity throughout database lifecycle."""
        
        create_database(self.test_db_path)
        
        def check_foreign_key_integrity():
            """Check foreign key integrity."""
            conn = connect_to_db(self.test_db_path, foreign_keys=True)
            cursor = conn.cursor()
            
            cursor.execute("PRAGMA foreign_key_check")
            violations = cursor.fetchall()
            
            conn.close()
            return violations
        
        # Check integrity after creation
        violations = check_foreign_key_integrity()
        assert len(violations) == 0, f"Foreign key violations after creation: {violations}"
        
        # Perform schema update
        update_schema(self.test_db_path)
        
        # Check integrity after update
        violations = check_foreign_key_integrity()
        assert len(violations) == 0, f"Foreign key violations after update: {violations}"
        
        # Add some test data and check again
        conn = connect_to_db(self.test_db_path)
        cursor = conn.cursor()
        
        # Insert test thing
        from libs.record_thing.db.uid import create_uid
        test_thing_id = create_uid()
        cursor.execute("""
            INSERT INTO things (id, account_id, title, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?)
        """, (test_thing_id, commons["owner_id"], "Test Thing", 1640995200.0, 1640995200.0))
        
        # Insert test evidence
        test_evidence_id = create_uid()
        cursor.execute("""
            INSERT INTO evidence (id, thing_account_id, thing_id, name, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (test_evidence_id, commons["owner_id"], test_thing_id, "Test Evidence", 1640995200.0, 1640995200.0))
        
        conn.commit()
        conn.close()
        
        # Check integrity after adding data
        violations = check_foreign_key_integrity()
        assert len(violations) == 0, f"Foreign key violations after adding data: {violations}"
    
    def test_performance_throughout_lifecycle(self):
        """Test performance remains acceptable throughout lifecycle."""
        
        import time
        
        # Time database creation
        start_time = time.time()
        create_database(self.test_db_path)
        creation_time = time.time() - start_time
        
        assert creation_time < 30, f"Database creation too slow: {creation_time:.2f}s"
        
        # Time schema update
        start_time = time.time()
        update_schema(self.test_db_path)
        update_time = time.time() - start_time
        
        assert update_time < 10, f"Schema update too slow: {update_time:.2f}s"
        
        # Time common queries
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        start_time = time.time()
        cursor.execute("SELECT COUNT(*) FROM things")
        cursor.fetchone()
        query_time = time.time() - start_time
        
        assert query_time < 1, f"Simple query too slow: {query_time:.3f}s"
        
        start_time = time.time()
        cursor.execute("""
            SELECT t.*, e.name as evidence_name
            FROM things t
            LEFT JOIN evidence e ON t.id = e.thing_id
            LIMIT 20
        """)
        cursor.fetchall()
        join_time = time.time() - start_time
        
        assert join_time < 2, f"Join query too slow: {join_time:.3f}s"
        
        conn.close()
        
        print(f"Performance - Creation: {creation_time:.2f}s, Update: {update_time:.2f}s, Query: {query_time:.3f}s, Join: {join_time:.3f}s")
    
    def test_ios_compatibility_integration(self):
        """Test iOS compatibility throughout integration."""
        
        create_database(self.test_db_path)
        
        # Test data types are iOS compatible
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Test string data
        cursor.execute("SELECT account_id, name, email FROM accounts LIMIT 1")
        account = cursor.fetchone()
        if account:
            for field in account:
                if field is not None:
                    assert isinstance(field, str), f"Non-string field in account: {type(field)}"
        
        # Test integer data
        cursor.execute("SELECT id FROM evidence_type LIMIT 1")
        evidence_type = cursor.fetchone()
        if evidence_type:
            assert isinstance(evidence_type[0], int), f"Non-integer ID: {type(evidence_type[0])}"
        
        # Test timestamp data
        cursor.execute("SELECT created_at FROM things WHERE created_at IS NOT NULL LIMIT 1")
        timestamp = cursor.fetchone()
        if timestamp:
            assert isinstance(timestamp[0], (int, float)), f"Non-numeric timestamp: {type(timestamp[0])}"
        
        # Test JSON data
        cursor.execute("SELECT tags FROM things WHERE tags IS NOT NULL LIMIT 1")
        tags = cursor.fetchone()
        if tags:
            try:
                json.loads(tags[0])
            except (json.JSONDecodeError, TypeError):
                pytest.fail(f"Invalid JSON in tags: {tags[0]}")
        
        conn.close()
    
    def test_error_recovery_integration(self):
        """Test error recovery throughout integration."""
        
        # Test recovery from incomplete database creation
        incomplete_db_path = self.temp_dir / "incomplete.sqlite"
        
        # Create incomplete database (just the file)
        conn = sqlite3.connect(incomplete_db_path)
        conn.execute("CREATE TABLE incomplete_table (id INTEGER)")
        conn.close()
        
        # Should be able to complete the database
        create_database(incomplete_db_path)
        
        # Verify it's now complete
        conn = connect_to_db(incomplete_db_path, read_only=True)
        tables = get_db_tables(conn)
        conn.close()
        
        assert 'accounts' in tables, "Database completion failed"
        assert 'things' in tables, "Database completion failed"
        
        # Test recovery from corrupted schema update
        create_database(self.test_db_path)
        
        # Simulate partial schema update by manually modifying database
        conn = connect_to_db(self.test_db_path)
        cursor = conn.cursor()
        
        # Add a test column that might conflict
        try:
            cursor.execute("ALTER TABLE accounts ADD COLUMN test_column TEXT")
            conn.commit()
        except sqlite3.OperationalError:
            pass  # Column might already exist
        
        conn.close()
        
        # Schema update should handle this gracefully
        update_schema(self.test_db_path)
        
        # Database should still be functional
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM accounts")
        count = cursor.fetchone()[0]
        assert count > 0, "Database not functional after recovery"
        conn.close()
    
    def test_concurrent_access_integration(self):
        """Test concurrent access throughout integration."""
        
        create_database(self.test_db_path)
        
        import threading
        import time
        
        results = []
        errors = []
        
        def reader_thread(thread_id: int):
            """Thread that reads from database."""
            try:
                for i in range(10):
                    conn = connect_to_db(self.test_db_path, read_only=True)
                    cursor = conn.cursor()
                    
                    cursor.execute("SELECT COUNT(*) FROM things")
                    count = cursor.fetchone()[0]
                    
                    cursor.execute("SELECT * FROM things LIMIT 5")
                    things = cursor.fetchall()
                    
                    conn.close()
                    
                    results.append((thread_id, i, count, len(things)))
                    time.sleep(0.01)  # Small delay
                    
            except Exception as e:
                errors.append((thread_id, str(e)))
        
        # Start multiple reader threads
        threads = []
        for i in range(5):
            thread = threading.Thread(target=reader_thread, args=(i,))
            threads.append(thread)
            thread.start()
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
        
        # Check results
        assert len(errors) == 0, f"Concurrent access errors: {errors}"
        assert len(results) == 50, f"Not all operations completed: {len(results)}/50"
        
        # All threads should get consistent results
        counts = [result[2] for result in results]
        assert len(set(counts)) == 1, f"Inconsistent counts from concurrent reads: {set(counts)}"
    
    def test_backup_and_restore_integration(self):
        """Test backup and restore functionality."""
        
        # Create original database
        create_database(self.test_db_path)
        
        # Create backup
        backup_path = self.temp_dir / "backup.sqlite"
        
        # Simple backup using SQLite backup API
        source_conn = connect_to_db(self.test_db_path, read_only=True)
        backup_conn = sqlite3.connect(backup_path)
        
        source_conn.backup(backup_conn)
        
        source_conn.close()
        backup_conn.close()
        
        # Verify backup is functional
        conn = connect_to_db(backup_path, read_only=True)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM accounts")
        backup_account_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM things")
        backup_things_count = cursor.fetchone()[0]
        
        conn.close()
        
        # Get original counts
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM accounts")
        original_account_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM things")
        original_things_count = cursor.fetchone()[0]
        
        conn.close()
        
        # Backup should have same data
        assert backup_account_count == original_account_count, "Backup account count mismatch"
        assert backup_things_count == original_things_count, "Backup things count mismatch"
        
        # Test restore by using backup as new database
        restore_path = self.temp_dir / "restored.sqlite"
        shutil.copy2(backup_path, restore_path)
        
        # Verify restored database
        conn = connect_to_db(restore_path, read_only=True)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM accounts")
        restored_account_count = cursor.fetchone()[0]
        
        assert restored_account_count == original_account_count, "Restore failed"
        
        conn.close()


class TestIntegrationScenarios:
    """Test specific integration scenarios."""
    
    def setup_method(self):
        """Set up test environment for each test."""
        self.temp_dir = Path(tempfile.mkdtemp())
    
    def teardown_method(self):
        """Clean up test environment after each test."""
        shutil.rmtree(self.temp_dir)
    
    def test_fresh_install_scenario(self):
        """Test fresh installation scenario."""
        
        fresh_db_path = self.temp_dir / "fresh-install.sqlite"
        
        # Simulate fresh install
        assert not fresh_db_path.exists(), "Database should not exist initially"
        
        # Create database
        create_database(fresh_db_path)
        
        # Verify fresh install is complete and functional
        assert fresh_db_path.exists(), "Database not created"
        assert test_connection(fresh_db_path), "Fresh database not functional"
        
        # Should have demo data
        conn = connect_to_db(fresh_db_path, read_only=True)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM accounts")
        account_count = cursor.fetchone()[0]
        assert account_count > 0, "No demo accounts in fresh install"
        
        cursor.execute("SELECT COUNT(*) FROM things")
        things_count = cursor.fetchone()[0]
        assert things_count > 0, "No demo things in fresh install"
        
        conn.close()
    
    def test_upgrade_scenario(self):
        """Test database upgrade scenario."""
        
        old_db_path = self.temp_dir / "old-version.sqlite"
        
        # Create "old version" database with minimal schema
        conn = sqlite3.connect(old_db_path)
        cursor = conn.cursor()
        
        # Create basic tables (simulating older version)
        cursor.execute("""
            CREATE TABLE accounts (
                account_id TEXT PRIMARY KEY,
                name TEXT
            )
        """)
        
        cursor.execute("""
            CREATE TABLE things (
                id TEXT PRIMARY KEY,
                account_id TEXT,
                title TEXT
            )
        """)
        
        # Insert some "old" data
        cursor.execute("INSERT INTO accounts VALUES (?, ?)", ("old-account", "Old User"))
        cursor.execute("INSERT INTO things VALUES (?, ?, ?)", ("old-thing", "old-account", "Old Thing"))
        
        conn.commit()
        conn.close()
        
        # Perform upgrade
        update_schema(old_db_path)
        
        # Verify upgrade preserved data and added new schema
        conn = connect_to_db(old_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Old data should be preserved
        cursor.execute("SELECT name FROM accounts WHERE account_id = ?", ("old-account",))
        old_account = cursor.fetchone()
        assert old_account[0] == "Old User", "Old account data lost"
        
        cursor.execute("SELECT title FROM things WHERE id = ?", ("old-thing",))
        old_thing = cursor.fetchone()
        assert old_thing[0] == "Old Thing", "Old thing data lost"
        
        # New tables should exist
        tables = get_db_tables(conn)
        assert 'evidence' in tables, "New tables not added during upgrade"
        assert 'evidence_type' in tables, "New tables not added during upgrade"
        
        conn.close()
    
    def test_migration_with_data_scenario(self):
        """Test migration scenario with existing data."""
        
        data_db_path = self.temp_dir / "with-data.sqlite"
        
        # Create database with substantial data
        create_database(data_db_path)
        
        # Add additional data
        conn = connect_to_db(data_db_path)
        cursor = conn.cursor()
        
        from libs.record_thing.db.uid import create_uid
        
        # Add many things
        for i in range(50):
            thing_id = create_uid()
            cursor.execute("""
                INSERT INTO things (id, account_id, title, description, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (thing_id, commons["owner_id"], f"Migration Test Thing {i}", 
                  f"Description {i}", 1640995200.0 + i, 1640995200.0 + i))
        
        conn.commit()
        
        # Get pre-migration counts
        cursor.execute("SELECT COUNT(*) FROM things")
        pre_migration_count = cursor.fetchone()[0]
        
        conn.close()
        
        # Perform migration
        update_schema(data_db_path)
        
        # Verify all data preserved
        conn = connect_to_db(data_db_path, read_only=True)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM things")
        post_migration_count = cursor.fetchone()[0]
        
        assert post_migration_count == pre_migration_count, "Data lost during migration"
        
        # Verify specific test data
        cursor.execute("SELECT COUNT(*) FROM things WHERE title LIKE 'Migration Test Thing%'")
        test_data_count = cursor.fetchone()[0]
        assert test_data_count == 50, "Test data lost during migration"
        
        conn.close()
