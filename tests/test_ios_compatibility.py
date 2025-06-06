"""
Test iOS app compatibility with generated databases.
Tests loading generated databases into simulated iOS environment using Blackbird models.
"""

import pytest
import sqlite3
import tempfile
import shutil
import json
from pathlib import Path
from typing import List, Dict, Any, Optional

from libs.record_thing.db.connection import connect_to_db, get_db_tables, get_table_schema
from libs.record_thing.db_setup import create_database
from libs.record_thing.commons import commons


class MockBlackbirdModel:
    """Mock Blackbird model for testing iOS compatibility."""
    
    def __init__(self, table_name: str, columns: Dict[str, str]):
        self.table_name = table_name
        self.columns = columns
    
    def validate_against_schema(self, db_schema: List[tuple]) -> List[str]:
        """Validate model columns against database schema."""
        errors = []
        schema_columns = {col[1]: col[2] for col in db_schema}  # name: type
        
        for col_name, col_type in self.columns.items():
            if col_name not in schema_columns:
                errors.append(f"Column {col_name} not found in database schema")
            else:
                # Basic type compatibility check
                db_type = schema_columns[col_name].upper()
                model_type = col_type.upper()
                
                # Map Swift/Blackbird types to SQLite types
                type_mappings = {
                    'STRING': ['TEXT', 'VARCHAR'],
                    'INT': ['INTEGER', 'INT'],
                    'BOOL': ['BOOLEAN', 'INTEGER'],  # SQLite stores bools as integers
                    'DOUBLE': ['REAL', 'FLOAT', 'DOUBLE'],
                    'DATE': ['REAL', 'FLOAT', 'TIMESTAMP'],  # Dates often stored as timestamps
                    'DATA': ['BLOB'],
                    'URL': ['TEXT'],  # URLs stored as text
                }
                
                compatible = False
                if model_type in type_mappings:
                    compatible = any(db_type.startswith(db_t) for db_t in type_mappings[model_type])
                
                if not compatible:
                    errors.append(f"Type mismatch for {col_name}: model expects {model_type}, DB has {db_type}")
        
        return errors


# Define mock iOS models based on the actual Blackbird models
IOS_MODELS = {
    'accounts': MockBlackbirdModel('accounts', {
        'account_id': 'STRING',
        'name': 'STRING',
        'username': 'STRING',
        'email': 'STRING',
        'sms': 'STRING',
        'region': 'STRING',
        'team_id': 'STRING',
        'is_active': 'BOOL',
        'last_login': 'DATE'
    }),
    
    'things': MockBlackbirdModel('things', {
        'id': 'STRING',
        'account_id': 'STRING',
        'upc': 'STRING',
        'asin': 'STRING',
        'elid': 'STRING',
        'brand': 'STRING',
        'model': 'STRING',
        'color': 'STRING',
        'tags': 'STRING',
        'category': 'STRING',
        'evidence_type': 'STRING',
        'evidence_type_name': 'STRING',
        'title': 'STRING',
        'description': 'STRING',
        'created_at': 'DATE',
        'updated_at': 'DATE'
    }),
    
    'evidence': MockBlackbirdModel('evidence', {
        'id': 'STRING',
        'thing_account_id': 'STRING',
        'thing_id': 'STRING',
        'request_id': 'STRING',
        'name': 'STRING',
        'description': 'STRING',
        'url': 'URL',
        'created_at': 'DATE',
        'updated_at': 'DATE'
    }),
    
    'evidence_type': MockBlackbirdModel('evidence_type', {
        'id': 'INT',
        'lang': 'STRING',
        'rootName': 'STRING',
        'name': 'STRING',
        'url': 'URL',
        'gpcRoot': 'STRING',
        'gpcName': 'STRING',
        'gpcCode': 'INT',
        'unspscID': 'INT',
        'icon_path': 'STRING'
    }),
    
    'requests': MockBlackbirdModel('requests', {
        'id': 'STRING',
        'account_id': 'STRING',
        'url': 'STRING',
        'status': 'STRING',
        'delivery_method': 'STRING',
        'delivery_target': 'STRING',
        'universe_id': 'INT'
    })
}


class TestiOSCompatibility:
    """Test iOS app compatibility with generated databases."""
    
    def setup_method(self):
        """Set up test environment for each test."""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.test_db_path = self.temp_dir / "test-ios-compat.sqlite"
    
    def teardown_method(self):
        """Clean up test environment after each test."""
        shutil.rmtree(self.temp_dir)
    
    def test_blackbird_model_schema_compatibility(self):
        """Test that Blackbird models are compatible with database schema."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        
        compatibility_errors = []
        
        for table_name, model in IOS_MODELS.items():
            # Get database schema for this table
            try:
                schema = get_table_schema(conn, table_name)
                if not schema:
                    compatibility_errors.append(f"Table {table_name} not found in database")
                    continue
                
                # Validate model against schema
                model_errors = model.validate_against_schema(schema)
                if model_errors:
                    compatibility_errors.extend([f"{table_name}: {error}" for error in model_errors])
                    
            except Exception as e:
                compatibility_errors.append(f"Error checking {table_name}: {e}")
        
        conn.close()
        
        if compatibility_errors:
            error_msg = "iOS model compatibility issues:\n" + "\n".join(compatibility_errors)
            pytest.fail(error_msg)
    
    def test_data_type_compatibility(self):
        """Test that data types are compatible between SQLite and iOS."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Test string data
        cursor.execute("SELECT account_id, name, email FROM accounts LIMIT 1")
        account_row = cursor.fetchone()
        if account_row:
            account_id, name, email = account_row
            assert isinstance(account_id, str) or account_id is None, "account_id should be string"
            assert isinstance(name, str) or name is None, "name should be string"
            assert isinstance(email, str) or email is None, "email should be string"
        
        # Test integer data
        cursor.execute("SELECT id FROM evidence_type LIMIT 1")
        evidence_type_row = cursor.fetchone()
        if evidence_type_row:
            type_id = evidence_type_row[0]
            assert isinstance(type_id, int), "evidence_type.id should be integer"
        
        # Test boolean data (stored as integer in SQLite)
        cursor.execute("SELECT is_active FROM accounts LIMIT 1")
        account_active_row = cursor.fetchone()
        if account_active_row:
            is_active = account_active_row[0]
            assert isinstance(is_active, (int, bool)) or is_active is None, "is_active should be boolean/integer"
            if isinstance(is_active, int):
                assert is_active in [0, 1], "Boolean stored as integer should be 0 or 1"
        
        # Test timestamp data
        cursor.execute("SELECT created_at FROM things WHERE created_at IS NOT NULL LIMIT 1")
        timestamp_row = cursor.fetchone()
        if timestamp_row:
            created_at = timestamp_row[0]
            assert isinstance(created_at, (int, float)), "Timestamp should be numeric"
            assert created_at > 0, "Timestamp should be positive"
        
        conn.close()
    
    def test_json_data_compatibility(self):
        """Test that JSON data can be properly parsed by iOS."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Test JSON fields in things table (tags)
        cursor.execute("SELECT tags FROM things WHERE tags IS NOT NULL LIMIT 5")
        tag_rows = cursor.fetchall()
        
        for row in tag_rows:
            tags = row[0]
            if tags:
                try:
                    # Should be valid JSON
                    parsed_tags = json.loads(tags)
                    assert isinstance(parsed_tags, list), "Tags should be JSON array"
                except json.JSONDecodeError:
                    pytest.fail(f"Invalid JSON in tags field: {tags}")
        
        # Test JSON fields in requests table (data)
        cursor.execute("SELECT data FROM requests WHERE data IS NOT NULL LIMIT 5")
        data_rows = cursor.fetchall()
        
        for row in data_rows:
            data = row[0]
            if data:
                try:
                    # Should be valid JSON
                    parsed_data = json.loads(data)
                    assert isinstance(parsed_data, dict), "Request data should be JSON object"
                except json.JSONDecodeError:
                    pytest.fail(f"Invalid JSON in request data field: {data}")
        
        conn.close()
    
    def test_primary_key_compatibility(self):
        """Test that primary keys work correctly for iOS models."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Test single primary key (accounts)
        cursor.execute("SELECT account_id FROM accounts")
        account_ids = [row[0] for row in cursor.fetchall()]
        assert len(account_ids) == len(set(account_ids)), "Duplicate account_ids found"
        
        # Test composite primary key (things: account_id + id)
        cursor.execute("SELECT account_id, id FROM things")
        thing_keys = [(row[0], row[1]) for row in cursor.fetchall()]
        assert len(thing_keys) == len(set(thing_keys)), "Duplicate thing composite keys found"
        
        # Test auto-increment primary key (evidence_type)
        cursor.execute("SELECT id FROM evidence_type ORDER BY id")
        type_ids = [row[0] for row in cursor.fetchall()]
        if type_ids:
            # Should be sequential integers starting from 1
            assert type_ids[0] >= 1, "evidence_type.id should start from 1"
            for i in range(1, len(type_ids)):
                assert type_ids[i] > type_ids[i-1], "evidence_type.id should be sequential"
        
        conn.close()
    
    def test_foreign_key_relationships(self):
        """Test that foreign key relationships work for iOS models."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Test things -> accounts relationship
        cursor.execute("""
            SELECT COUNT(*) FROM things t
            LEFT JOIN accounts a ON t.account_id = a.account_id
            WHERE a.account_id IS NULL
        """)
        orphaned_things = cursor.fetchone()[0]
        assert orphaned_things == 0, "Found things without valid accounts"
        
        # Test evidence -> things relationship
        cursor.execute("""
            SELECT COUNT(*) FROM evidence e
            LEFT JOIN things t ON e.thing_id = t.id AND e.thing_account_id = t.account_id
            WHERE e.thing_id IS NOT NULL AND t.id IS NULL
        """)
        orphaned_evidence = cursor.fetchone()[0]
        assert orphaned_evidence == 0, "Found evidence without valid things"
        
        conn.close()
    
    def test_unicode_data_compatibility(self):
        """Test that Unicode data is properly handled."""
        create_database(self.test_db_path)
        
        # Insert test data with Unicode characters
        conn = connect_to_db(self.test_db_path)
        cursor = conn.cursor()
        
        # Insert account with Unicode name
        unicode_name = "测试用户 🎯"
        cursor.execute("""
            INSERT INTO accounts (account_id, name, email)
            VALUES (?, ?, ?)
        """, ("unicode-test", unicode_name, "test@测试.com"))
        
        conn.commit()
        
        # Read back and verify
        cursor.execute("SELECT name, email FROM accounts WHERE account_id = ?", ("unicode-test",))
        result = cursor.fetchone()
        
        assert result[0] == unicode_name, "Unicode name not preserved"
        assert result[1] == "test@测试.com", "Unicode email not preserved"
        
        conn.close()
    
    def test_null_value_handling(self):
        """Test that NULL values are properly handled."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check for proper NULL handling in optional fields
        cursor.execute("""
            SELECT account_id, name, username, email, sms
            FROM accounts LIMIT 5
        """)
        accounts = cursor.fetchall()
        
        for account in accounts:
            account_id, name, username, email, sms = account
            # account_id should never be NULL (primary key)
            assert account_id is not None, "account_id should not be NULL"
            # Other fields can be NULL
            # Just verify they're handled properly (no exceptions)
        
        # Check things with optional fields
        cursor.execute("""
            SELECT id, account_id, upc, asin, brand, model, color
            FROM things LIMIT 5
        """)
        things = cursor.fetchall()
        
        for thing in things:
            thing_id, account_id, upc, asin, brand, model, color = thing
            # Required fields should not be NULL
            assert thing_id is not None, "thing.id should not be NULL"
            assert account_id is not None, "thing.account_id should not be NULL"
            # Optional fields can be NULL
        
        conn.close()
    
    def test_database_size_for_ios(self):
        """Test that database size is reasonable for iOS app."""
        create_database(self.test_db_path)
        
        # Check file size
        file_size = self.test_db_path.stat().st_size
        
        # Should be reasonable for mobile app (< 50MB for test data)
        assert file_size < 50_000_000, f"Database too large for iOS: {file_size:,} bytes"
        
        # Should have meaningful content (> 100KB)
        assert file_size > 100_000, f"Database too small: {file_size:,} bytes"
        
        print(f"Database size: {file_size:,} bytes ({file_size / 1024 / 1024:.2f} MB)")
    
    def test_query_performance_for_ios(self):
        """Test that common queries perform well enough for iOS."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        import time
        
        # Test common queries that iOS app would use
        queries = [
            "SELECT COUNT(*) FROM things",
            "SELECT * FROM things LIMIT 20",
            "SELECT * FROM evidence WHERE thing_id IS NOT NULL LIMIT 20",
            "SELECT * FROM evidence_type WHERE lang = 'en' LIMIT 50",
            "SELECT t.*, e.name as evidence_name FROM things t LEFT JOIN evidence e ON t.id = e.thing_id LIMIT 10"
        ]
        
        for query in queries:
            start_time = time.time()
            cursor.execute(query)
            results = cursor.fetchall()
            query_time = time.time() - start_time
            
            # Queries should complete quickly (< 1 second for test data)
            assert query_time < 1.0, f"Query too slow: {query} took {query_time:.3f}s"
            
            print(f"Query: {query[:50]}... took {query_time:.3f}s, returned {len(results)} rows")
        
        conn.close()
    
    def test_concurrent_access_simulation(self):
        """Test database behavior under concurrent access (simulating iOS background tasks)."""
        create_database(self.test_db_path)
        
        # Simulate multiple read connections (like iOS app with background sync)
        connections = []
        try:
            for i in range(5):
                conn = connect_to_db(self.test_db_path, read_only=True)
                connections.append(conn)
            
            # All connections should work
            for i, conn in enumerate(connections):
                cursor = conn.cursor()
                cursor.execute("SELECT COUNT(*) FROM things")
                count = cursor.fetchone()[0]
                assert count > 0, f"Connection {i} failed to read data"
        
        finally:
            # Clean up connections
            for conn in connections:
                conn.close()


class TestiOSDataValidation:
    """Test data validation for iOS app requirements."""
    
    def setup_method(self):
        """Set up test environment for each test."""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.test_db_path = self.temp_dir / "test-ios-validation.sqlite"
    
    def teardown_method(self):
        """Clean up test environment after each test."""
        shutil.rmtree(self.temp_dir)
    
    def test_required_tables_exist(self):
        """Test that all tables required by iOS app exist."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        tables = get_db_tables(conn)
        conn.close()
        
        required_tables = list(IOS_MODELS.keys())
        missing_tables = [table for table in required_tables if table not in tables]
        
        assert len(missing_tables) == 0, f"Missing required tables: {missing_tables}"
    
    def test_data_completeness_for_ios(self):
        """Test that database has sufficient data for iOS app demo."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Should have at least one account
        cursor.execute("SELECT COUNT(*) FROM accounts")
        account_count = cursor.fetchone()[0]
        assert account_count >= 1, "Need at least one account for iOS app"
        
        # Should have some things to display
        cursor.execute("SELECT COUNT(*) FROM things")
        things_count = cursor.fetchone()[0]
        assert things_count >= 10, f"Need more things for iOS demo: only {things_count}"
        
        # Should have evidence for things
        cursor.execute("SELECT COUNT(*) FROM evidence")
        evidence_count = cursor.fetchone()[0]
        assert evidence_count >= 10, f"Need more evidence for iOS demo: only {evidence_count}"
        
        # Should have evidence types for categorization
        cursor.execute("SELECT COUNT(*) FROM evidence_type")
        type_count = cursor.fetchone()[0]
        assert type_count >= 5, f"Need more evidence types: only {type_count}"
        
        conn.close()
