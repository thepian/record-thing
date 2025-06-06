"""
Test data generation functionality.
Tests creating Demo Account data and generating other realistic test data.
"""

import pytest
import sqlite3
import tempfile
import shutil
from pathlib import Path
from typing import List, Dict, Any

from libs.record_thing.db.schema import ensure_owner_account, ensure_teams
from libs.record_thing.db.connection import connect_to_db, get_db_tables
from libs.record_thing.db_setup import create_database, insert_sample_data
from libs.record_thing.db.operations import (
    generate_testdata_records, 
    generate_universe_records,
    generate_things,
    generate_evidence_for_things
)
from libs.record_thing.db.test_data import USE_CASES, TEST_SCENARIOS, BRANDS
from libs.record_thing.commons import commons


class TestDataGeneration:
    """Test data generation functionality."""
    
    def setup_method(self):
        """Set up test environment for each test."""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.test_db_path = self.temp_dir / "test-data-gen.sqlite"
    
    def teardown_method(self):
        """Clean up test environment after each test."""
        shutil.rmtree(self.temp_dir)
    
    def test_create_demo_account(self):
        """Test creating demo account data."""
        # Create database with schema only
        from libs.record_thing.db_setup import create_tables
        create_tables(self.test_db_path)
        
        # Add demo account
        conn = connect_to_db(self.test_db_path)
        ensure_owner_account(conn, dummy_account_data=True)
        ensure_teams(conn)
        conn.commit()
        conn.close()
        
        # Verify demo account was created
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check accounts table
        cursor.execute("SELECT COUNT(*) FROM accounts")
        account_count = cursor.fetchone()[0]
        assert account_count > 0, "No demo account created"
        
        # Check owner account
        cursor.execute("SELECT account_id FROM accounts WHERE account_id = ?", 
                      (commons["owner_id"],))
        owner = cursor.fetchone()
        assert owner is not None, "Demo owner account not found"
        
        # Check teams
        cursor.execute("SELECT COUNT(*) FROM teams")
        team_count = cursor.fetchone()[0]
        assert team_count >= 2, "Demo teams not created"
        
        conn.close()
    
    def test_generate_universe_data(self):
        """Test generating universe/use case data."""
        create_tables(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path)
        cursor = conn.cursor()
        
        # Generate universe records
        universe_count = generate_universe_records(cursor, USE_CASES)
        conn.commit()
        
        # Verify universes were created
        cursor.execute("SELECT COUNT(*) FROM universe")
        actual_count = cursor.fetchone()[0]
        assert actual_count == universe_count, "Universe count mismatch"
        assert actual_count == len(USE_CASES), "Not all use cases created"
        
        # Verify universe data quality
        cursor.execute("SELECT url, name, description FROM universe")
        universes = cursor.fetchall()
        
        for url, name, description in universes:
            assert url.startswith("https://"), "Invalid universe URL"
            assert len(name) > 0, "Empty universe name"
            assert len(description) > 0, "Empty universe description"
        
        conn.close()
    
    def test_generate_things_data(self):
        """Test generating things/items data."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check things were generated
        cursor.execute("SELECT COUNT(*) FROM things")
        things_count = cursor.fetchone()[0]
        assert things_count > 0, "No things generated"
        
        # Verify things data quality
        cursor.execute("""
            SELECT id, account_id, title, description, brand, category
            FROM things LIMIT 10
        """)
        things = cursor.fetchall()
        
        for thing in things:
            thing_id, account_id, title, description, brand, category = thing
            assert len(thing_id) > 0, "Empty thing ID"
            assert account_id == commons["owner_id"], "Wrong account ID"
            assert title is None or len(title) > 0, "Invalid title"
            assert brand is None or len(brand) > 0, "Invalid brand"
            assert category is None or len(category) > 0, "Invalid category"
        
        conn.close()
    
    def test_generate_evidence_data(self):
        """Test generating evidence data."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check evidence was generated
        cursor.execute("SELECT COUNT(*) FROM evidence")
        evidence_count = cursor.fetchone()[0]
        assert evidence_count > 0, "No evidence generated"
        
        # Verify evidence data quality
        cursor.execute("""
            SELECT id, thing_account_id, thing_id, name, description
            FROM evidence LIMIT 10
        """)
        evidence_records = cursor.fetchall()
        
        for evidence in evidence_records:
            evidence_id, thing_account_id, thing_id, name, description = evidence
            assert len(evidence_id) > 0, "Empty evidence ID"
            assert thing_account_id == commons["owner_id"], "Wrong account ID"
            assert thing_id is None or len(thing_id) > 0, "Invalid thing ID"
            assert name is None or len(name) > 0, "Invalid evidence name"
        
        conn.close()
    
    def test_generate_requests_data(self):
        """Test generating request data."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check requests were generated
        cursor.execute("SELECT COUNT(*) FROM requests")
        requests_count = cursor.fetchone()[0]
        assert requests_count > 0, "No requests generated"
        
        # Verify requests data quality
        cursor.execute("""
            SELECT id, account_id, url, status, delivery_method
            FROM requests LIMIT 10
        """)
        requests = cursor.fetchall()
        
        for request in requests:
            request_id, account_id, url, status, delivery_method = request
            assert request_id > 0, "Invalid request ID"
            assert account_id == commons["owner_id"], "Wrong account ID"
            assert url is None or url.startswith("https://"), "Invalid request URL"
            assert status is not None, "Missing request status"
        
        conn.close()
    
    def test_generate_product_types(self):
        """Test generating product type data."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check evidence types were generated
        cursor.execute("SELECT COUNT(*) FROM evidence_type")
        evidence_type_count = cursor.fetchone()[0]
        assert evidence_type_count > 0, "No evidence types generated"
        
        # Verify evidence type data quality
        cursor.execute("""
            SELECT id, lang, rootName, name, url
            FROM evidence_type WHERE lang = 'en' LIMIT 10
        """)
        evidence_types = cursor.fetchall()
        
        for evidence_type in evidence_types:
            type_id, lang, root_name, name, url = evidence_type
            assert type_id > 0, "Invalid evidence type ID"
            assert lang == "en", "Wrong language"
            assert len(root_name) > 0, "Empty root name"
            assert len(name) > 0, "Empty name"
        
        conn.close()
    
    def test_generate_document_types(self):
        """Test generating document type data."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check document types were generated
        cursor.execute("SELECT COUNT(*) FROM document_type")
        doc_type_count = cursor.fetchone()[0]
        assert doc_type_count > 0, "No document types generated"
        
        # Verify document type data quality
        cursor.execute("""
            SELECT lang, rootName, name, url
            FROM document_type WHERE lang = 'en' LIMIT 10
        """)
        doc_types = cursor.fetchall()
        
        for doc_type in doc_types:
            lang, root_name, name, url = doc_type
            assert lang == "en", "Wrong language"
            assert len(root_name) > 0, "Empty root name"
            assert len(name) > 0, "Empty name"
        
        conn.close()
    
    def test_data_relationships(self):
        """Test that generated data has proper relationships."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Test thing-evidence relationships
        cursor.execute("""
            SELECT COUNT(*) FROM evidence e
            JOIN things t ON e.thing_id = t.id AND e.thing_account_id = t.account_id
        """)
        linked_evidence = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM evidence WHERE thing_id IS NOT NULL")
        total_thing_evidence = cursor.fetchone()[0]
        
        # Most evidence should be properly linked to things
        if total_thing_evidence > 0:
            link_ratio = linked_evidence / total_thing_evidence
            assert link_ratio > 0.8, f"Poor evidence-thing linking: {link_ratio:.2f}"
        
        # Test account relationships
        cursor.execute("""
            SELECT COUNT(*) FROM things t
            JOIN accounts a ON t.account_id = a.account_id
        """)
        linked_things = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM things")
        total_things = cursor.fetchone()[0]
        
        # All things should be linked to valid accounts
        assert linked_things == total_things, "Not all things linked to valid accounts"
        
        conn.close()
    
    def test_data_volume_scenarios(self):
        """Test different data volume scenarios."""
        for scenario in TEST_SCENARIOS:
            scenario_db_path = self.temp_dir / f"scenario-{scenario['name'].replace(' ', '-').lower()}.sqlite"
            
            # Create database with this scenario's data volume
            create_database(scenario_db_path)
            
            conn = connect_to_db(scenario_db_path, read_only=True)
            cursor = conn.cursor()
            
            # Verify data volumes are reasonable for scenario
            cursor.execute("SELECT COUNT(*) FROM things")
            things_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM evidence")
            evidence_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM requests")
            requests_count = cursor.fetchone()[0]
            
            # Basic sanity checks
            assert things_count > 0, f"No things in scenario {scenario['name']}"
            assert evidence_count > 0, f"No evidence in scenario {scenario['name']}"
            assert requests_count >= 0, f"Invalid requests in scenario {scenario['name']}"
            
            # Evidence should be proportional to things
            if things_count > 0:
                evidence_ratio = evidence_count / things_count
                assert evidence_ratio >= 1, f"Too little evidence per thing in {scenario['name']}"
                assert evidence_ratio <= 20, f"Too much evidence per thing in {scenario['name']}"
            
            conn.close()
    
    def test_data_consistency(self):
        """Test data consistency across tables."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Check for orphaned evidence (evidence without valid things)
        cursor.execute("""
            SELECT COUNT(*) FROM evidence e
            LEFT JOIN things t ON e.thing_id = t.id AND e.thing_account_id = t.account_id
            WHERE e.thing_id IS NOT NULL AND t.id IS NULL
        """)
        orphaned_evidence = cursor.fetchone()[0]
        assert orphaned_evidence == 0, f"Found {orphaned_evidence} orphaned evidence records"
        
        # Check for invalid account references
        cursor.execute("""
            SELECT COUNT(*) FROM things t
            LEFT JOIN accounts a ON t.account_id = a.account_id
            WHERE a.account_id IS NULL
        """)
        invalid_accounts = cursor.fetchone()[0]
        assert invalid_accounts == 0, f"Found {invalid_accounts} things with invalid accounts"
        
        # Check for duplicate IDs
        cursor.execute("""
            SELECT id, COUNT(*) as count FROM things 
            GROUP BY account_id, id HAVING count > 1
        """)
        duplicate_things = cursor.fetchall()
        assert len(duplicate_things) == 0, f"Found duplicate thing IDs: {duplicate_things}"
        
        conn.close()
