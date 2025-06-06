"""
Test performance and stress testing of the database system.
"""

import pytest
import sqlite3
import tempfile
import shutil
import time
import threading
from pathlib import Path
from typing import List, Dict, Any
from concurrent.futures import ThreadPoolExecutor, as_completed

from libs.record_thing.db.connection import connect_to_db, get_db_tables
from libs.record_thing.db_setup import create_database, create_tables, insert_sample_data
from libs.record_thing.db.operations import generate_testdata_records
from libs.record_thing.commons import commons


class TestPerformance:
    """Test database performance."""
    
    def setup_method(self):
        """Set up test environment for each test."""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.test_db_path = self.temp_dir / "test-performance.sqlite"
    
    def teardown_method(self):
        """Clean up test environment after each test."""
        shutil.rmtree(self.temp_dir)
    
    def test_database_creation_performance(self):
        """Test database creation performance."""
        start_time = time.time()
        
        create_database(self.test_db_path)
        
        creation_time = time.time() - start_time
        
        # Database creation should complete in reasonable time
        assert creation_time < 30, f"Database creation too slow: {creation_time:.2f}s"
        
        # Verify database was created successfully
        assert self.test_db_path.exists()
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        tables = get_db_tables(conn)
        conn.close()
        
        assert len(tables) > 5, "Database creation incomplete"
        
        print(f"Database creation took {creation_time:.2f}s")
    
    def test_large_query_performance(self):
        """Test performance of large queries."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Test various query types
        queries = [
            ("Count all things", "SELECT COUNT(*) FROM things"),
            ("Get all things", "SELECT * FROM things"),
            ("Get all evidence", "SELECT * FROM evidence"),
            ("Join things and evidence", """
                SELECT t.id, t.title, e.name as evidence_name
                FROM things t
                LEFT JOIN evidence e ON t.id = e.thing_id
            """),
            ("Complex aggregation", """
                SELECT t.category, COUNT(*) as thing_count, COUNT(e.id) as evidence_count
                FROM things t
                LEFT JOIN evidence e ON t.id = e.thing_id
                WHERE t.category IS NOT NULL
                GROUP BY t.category
                ORDER BY thing_count DESC
            """),
        ]
        
        for query_name, query in queries:
            start_time = time.time()
            cursor.execute(query)
            results = cursor.fetchall()
            query_time = time.time() - start_time
            
            # Queries should complete in reasonable time
            assert query_time < 5.0, f"{query_name} too slow: {query_time:.3f}s"
            
            print(f"{query_name}: {query_time:.3f}s, {len(results)} rows")
        
        conn.close()
    
    def test_concurrent_read_performance(self):
        """Test performance under concurrent read load."""
        create_database(self.test_db_path)
        
        def read_worker(worker_id: int) -> Dict[str, Any]:
            """Worker function for concurrent reads."""
            start_time = time.time()
            
            conn = connect_to_db(self.test_db_path, read_only=True)
            cursor = conn.cursor()
            
            # Perform multiple queries
            queries_performed = 0
            for i in range(10):
                cursor.execute("SELECT COUNT(*) FROM things")
                cursor.fetchone()
                
                cursor.execute("SELECT * FROM things LIMIT 10")
                cursor.fetchall()
                
                cursor.execute("SELECT * FROM evidence LIMIT 10")
                cursor.fetchall()
                
                queries_performed += 3
            
            conn.close()
            
            worker_time = time.time() - start_time
            return {
                'worker_id': worker_id,
                'time': worker_time,
                'queries': queries_performed
            }
        
        # Run concurrent workers
        num_workers = 5
        start_time = time.time()
        
        with ThreadPoolExecutor(max_workers=num_workers) as executor:
            futures = [executor.submit(read_worker, i) for i in range(num_workers)]
            results = [future.result() for future in as_completed(futures)]
        
        total_time = time.time() - start_time
        
        # All workers should complete in reasonable time
        assert total_time < 10, f"Concurrent reads too slow: {total_time:.2f}s"
        
        # Individual workers should not be significantly slower than single-threaded
        max_worker_time = max(result['time'] for result in results)
        assert max_worker_time < 5, f"Slowest worker took {max_worker_time:.2f}s"
        
        total_queries = sum(result['queries'] for result in results)
        print(f"Concurrent reads: {total_queries} queries in {total_time:.2f}s ({total_queries/total_time:.1f} queries/s)")
    
    def test_memory_usage_during_operations(self):
        """Test memory usage during database operations."""
        import psutil
        import os
        
        process = psutil.Process(os.getpid())
        initial_memory = process.memory_info().rss
        
        # Create database and monitor memory
        create_database(self.test_db_path)
        
        after_creation_memory = process.memory_info().rss
        memory_increase = after_creation_memory - initial_memory
        
        # Memory increase should be reasonable (< 100MB for test data)
        assert memory_increase < 100_000_000, f"Excessive memory usage: {memory_increase:,} bytes"
        
        # Perform some operations
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Read all data
        cursor.execute("SELECT * FROM things")
        things = cursor.fetchall()
        
        cursor.execute("SELECT * FROM evidence")
        evidence = cursor.fetchall()
        
        conn.close()
        
        after_operations_memory = process.memory_info().rss
        operation_memory_increase = after_operations_memory - after_creation_memory
        
        # Operations should not cause significant additional memory usage
        assert operation_memory_increase < 50_000_000, f"Operations used too much memory: {operation_memory_increase:,} bytes"
        
        print(f"Memory usage - Creation: {memory_increase:,} bytes, Operations: {operation_memory_increase:,} bytes")
    
    def test_database_size_efficiency(self):
        """Test database storage efficiency."""
        create_database(self.test_db_path)
        
        # Get database size
        file_size = self.test_db_path.stat().st_size
        
        # Count records
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM things")
        things_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM evidence")
        evidence_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM evidence_type")
        types_count = cursor.fetchone()[0]
        
        total_records = things_count + evidence_count + types_count
        
        conn.close()
        
        # Calculate efficiency metrics
        bytes_per_record = file_size / total_records if total_records > 0 else 0
        
        # Should be reasonably efficient (< 10KB per record on average)
        assert bytes_per_record < 10_000, f"Database not efficient: {bytes_per_record:.0f} bytes per record"
        
        print(f"Database efficiency: {file_size:,} bytes for {total_records} records ({bytes_per_record:.0f} bytes/record)")
    
    def test_index_performance(self):
        """Test that indexes improve query performance."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path)
        cursor = conn.cursor()
        
        # Test query performance without explicit indexes
        start_time = time.time()
        cursor.execute("SELECT * FROM things WHERE account_id = ?", (commons["owner_id"],))
        results_without_index = cursor.fetchall()
        time_without_index = time.time() - start_time
        
        # Create index on account_id if it doesn't exist
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_things_account_id ON things(account_id)")
        
        # Test query performance with index
        start_time = time.time()
        cursor.execute("SELECT * FROM things WHERE account_id = ?", (commons["owner_id"],))
        results_with_index = cursor.fetchall()
        time_with_index = time.time() - start_time
        
        conn.close()
        
        # Results should be the same
        assert len(results_without_index) == len(results_with_index), "Index changed query results"
        
        # With small test data, timing differences might be minimal, but index should not make it slower
        assert time_with_index <= time_without_index * 2, "Index made query significantly slower"
        
        print(f"Query performance - Without index: {time_without_index:.4f}s, With index: {time_with_index:.4f}s")
    
    def test_vacuum_performance(self):
        """Test VACUUM operation performance."""
        create_database(self.test_db_path)
        
        # Get initial size
        initial_size = self.test_db_path.stat().st_size
        
        # Perform VACUUM
        start_time = time.time()
        
        conn = connect_to_db(self.test_db_path)
        cursor = conn.cursor()
        cursor.execute("VACUUM")
        conn.close()
        
        vacuum_time = time.time() - start_time
        
        # VACUUM should complete quickly for test database
        assert vacuum_time < 10, f"VACUUM too slow: {vacuum_time:.2f}s"
        
        # Get size after VACUUM
        final_size = self.test_db_path.stat().st_size
        
        # Database should still be functional
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM things")
        count = cursor.fetchone()[0]
        assert count > 0, "Database corrupted after VACUUM"
        conn.close()
        
        print(f"VACUUM: {vacuum_time:.2f}s, size change: {initial_size:,} -> {final_size:,} bytes")


class TestStressTesting:
    """Stress testing for database operations."""
    
    def setup_method(self):
        """Set up test environment for each test."""
        self.temp_dir = Path(tempfile.mkdtemp())
        self.test_db_path = self.temp_dir / "test-stress.sqlite"
    
    def teardown_method(self):
        """Clean up test environment after each test."""
        shutil.rmtree(self.temp_dir)
    
    def test_many_concurrent_connections(self):
        """Test handling many concurrent connections."""
        create_database(self.test_db_path)
        
        def connection_worker(worker_id: int) -> bool:
            """Worker that creates connection and performs queries."""
            try:
                conn = connect_to_db(self.test_db_path, read_only=True)
                cursor = conn.cursor()
                
                # Perform some queries
                cursor.execute("SELECT COUNT(*) FROM things")
                cursor.fetchone()
                
                cursor.execute("SELECT * FROM things LIMIT 5")
                cursor.fetchall()
                
                conn.close()
                return True
            except Exception as e:
                print(f"Worker {worker_id} failed: {e}")
                return False
        
        # Test with many concurrent connections
        num_workers = 20
        
        with ThreadPoolExecutor(max_workers=num_workers) as executor:
            futures = [executor.submit(connection_worker, i) for i in range(num_workers)]
            results = [future.result() for future in as_completed(futures)]
        
        # Most connections should succeed
        success_rate = sum(results) / len(results)
        assert success_rate >= 0.9, f"Too many connection failures: {success_rate:.2%} success rate"
        
        print(f"Concurrent connections: {success_rate:.2%} success rate with {num_workers} workers")
    
    def test_rapid_connection_cycling(self):
        """Test rapid connection creation and destruction."""
        create_database(self.test_db_path)
        
        start_time = time.time()
        
        # Rapidly create and close connections
        for i in range(100):
            conn = connect_to_db(self.test_db_path, read_only=True)
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchone()
            conn.close()
        
        cycle_time = time.time() - start_time
        
        # Should handle rapid cycling efficiently
        assert cycle_time < 10, f"Connection cycling too slow: {cycle_time:.2f}s for 100 cycles"
        
        print(f"Connection cycling: 100 cycles in {cycle_time:.2f}s ({100/cycle_time:.1f} cycles/s)")
    
    def test_long_running_connection(self):
        """Test long-running connection stability."""
        create_database(self.test_db_path)
        
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        
        # Perform many operations on the same connection
        start_time = time.time()
        
        for i in range(1000):
            cursor.execute("SELECT COUNT(*) FROM things")
            cursor.fetchone()
            
            if i % 100 == 0:
                # Periodically check that connection is still working
                cursor.execute("SELECT * FROM things LIMIT 1")
                result = cursor.fetchone()
                assert result is not None, f"Connection failed at iteration {i}"
        
        operation_time = time.time() - start_time
        
        conn.close()
        
        # Should handle many operations efficiently
        assert operation_time < 30, f"Long-running operations too slow: {operation_time:.2f}s"
        
        print(f"Long-running connection: 1000 operations in {operation_time:.2f}s")
    
    def test_database_corruption_resistance(self):
        """Test database resistance to corruption scenarios."""
        create_database(self.test_db_path)
        
        # Test 1: Sudden connection termination
        conn = connect_to_db(self.test_db_path)
        cursor = conn.cursor()
        cursor.execute("BEGIN TRANSACTION")
        cursor.execute("SELECT COUNT(*) FROM things")
        # Simulate sudden termination by not committing and closing abruptly
        conn.close()
        
        # Database should still be accessible
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        cursor.execute("PRAGMA integrity_check")
        integrity_result = cursor.fetchone()[0]
        assert integrity_result == "ok", f"Database integrity compromised: {integrity_result}"
        conn.close()
        
        # Test 2: Multiple overlapping transactions (read-only)
        connections = []
        try:
            for i in range(5):
                conn = connect_to_db(self.test_db_path, read_only=True)
                connections.append(conn)
                cursor = conn.cursor()
                cursor.execute("SELECT COUNT(*) FROM things")
                cursor.fetchone()
        finally:
            for conn in connections:
                conn.close()
        
        # Database should still be functional
        conn = connect_to_db(self.test_db_path, read_only=True)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM things")
        count = cursor.fetchone()[0]
        assert count > 0, "Database became non-functional"
        conn.close()
    
    def test_large_result_set_handling(self):
        """Test handling of large result sets."""
        # Create database with more data for this test
        create_database(self.test_db_path)
        
        # Add additional test data
        conn = connect_to_db(self.test_db_path)
        cursor = conn.cursor()
        
        from libs.record_thing.db.uid import create_uid
        
        # Add many more things
        for i in range(500):
            thing_id = create_uid()
            cursor.execute("""
                INSERT INTO things (id, account_id, title, description, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (thing_id, commons["owner_id"], f"Stress Test Thing {i}", 
                  f"Description for stress test thing {i}", time.time(), time.time()))
        
        conn.commit()
        
        # Test large query
        start_time = time.time()
        cursor.execute("SELECT * FROM things")
        all_things = cursor.fetchall()
        query_time = time.time() - start_time
        
        conn.close()
        
        # Should handle large result set efficiently
        assert len(all_things) >= 500, "Not all records retrieved"
        assert query_time < 5, f"Large query too slow: {query_time:.2f}s for {len(all_things)} records"
        
        print(f"Large result set: {len(all_things)} records in {query_time:.2f}s")
