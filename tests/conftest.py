"""
Configuration for pytest.
This file helps with importing modules and setting up fixtures for the test suite.
"""

import os
import sys
import tempfile
import shutil
from pathlib import Path
import pytest

# Add the project root to the Python path
# This allows imports like 'from libs.record_thing.db import ...' to work
root_dir = Path(__file__).parent.parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

# Also add the library directory to allow relative imports in tests
lib_dir = Path(__file__).parent.parent / "libs"
if str(lib_dir) not in sys.path:
    sys.path.insert(0, str(lib_dir))


@pytest.fixture(scope="session")
def temp_test_dir():
    """Create a temporary directory for the entire test session."""
    temp_dir = Path(tempfile.mkdtemp(prefix="recordthing_tests_"))
    yield temp_dir
    shutil.rmtree(temp_dir, ignore_errors=True)


@pytest.fixture
def temp_db_path(temp_test_dir):
    """Create a temporary database path for a single test."""
    import uuid
    db_name = f"test_{uuid.uuid4().hex[:8]}.sqlite"
    return temp_test_dir / db_name


@pytest.fixture
def sample_database(temp_db_path):
    """Create a sample database with test data."""
    from libs.record_thing.db_setup import create_database
    
    create_database(temp_db_path)
    yield temp_db_path
    
    # Cleanup is handled by temp_test_dir fixture


@pytest.fixture
def empty_database(temp_db_path):
    """Create an empty database with schema only."""
    from libs.record_thing.db_setup import create_tables
    
    create_tables(temp_db_path)
    yield temp_db_path
    
    # Cleanup is handled by temp_test_dir fixture


@pytest.fixture
def mock_commons():
    """Mock commons data for testing."""
    return {
        "owner_id": "test-owner-id-12345",
        "demo_account_id": "demo-account-id-67890"
    }


# Configure pytest markers
def pytest_configure(config):
    """Configure pytest with custom markers."""
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )
    config.addinivalue_line(
        "markers", "integration: marks tests as integration tests"
    )
    config.addinivalue_line(
        "markers", "performance: marks tests as performance tests"
    )
    config.addinivalue_line(
        "markers", "ios: marks tests as iOS compatibility tests"
    )


# Configure test collection
def pytest_collection_modifyitems(config, items):
    """Modify test collection to add markers based on test names."""
    for item in items:
        # Add slow marker to tests that might take longer
        if any(keyword in item.name.lower() for keyword in ["large", "stress", "performance", "concurrent"]):
            item.add_marker(pytest.mark.slow)
        
        # Add integration marker to integration tests
        if "integration" in item.name.lower() or "full" in item.name.lower():
            item.add_marker(pytest.mark.integration)
        
        # Add performance marker to performance tests
        if "performance" in item.name.lower() or "stress" in item.name.lower():
            item.add_marker(pytest.mark.performance)
        
        # Add iOS marker to iOS compatibility tests
        if "ios" in item.name.lower() or "blackbird" in item.name.lower():
            item.add_marker(pytest.mark.ios)


# Test environment setup
@pytest.fixture(autouse=True)
def setup_test_environment():
    """Set up test environment for each test."""
    # Set environment variables for testing
    os.environ["TESTING"] = "1"
    os.environ["LOG_LEVEL"] = "WARNING"  # Reduce log noise during tests
    
    yield
    
    # Cleanup environment
    os.environ.pop("TESTING", None)
    os.environ.pop("LOG_LEVEL", None)


# Database connection helpers
@pytest.fixture
def db_connection():
    """Create a database connection helper."""
    connections = []
    
    def _connect(db_path, **kwargs):
        from libs.record_thing.db.connection import connect_to_db
        conn = connect_to_db(db_path, **kwargs)
        connections.append(conn)
        return conn
    
    yield _connect
    
    # Cleanup all connections
    for conn in connections:
        try:
            conn.close()
        except:
            pass


# Test data helpers
@pytest.fixture
def test_data_generator():
    """Helper for generating test data."""
    class TestDataGenerator:
        @staticmethod
        def create_test_account(account_id="test-account", name="Test User"):
            return {
                'account_id': account_id,
                'name': name,
                'email': f"{account_id}@example.com",
                'is_active': True
            }
        
        @staticmethod
        def create_test_thing(thing_id="test-thing", account_id="test-account"):
            return {
                'id': thing_id,
                'account_id': account_id,
                'title': f"Test Thing {thing_id}",
                'description': f"Description for {thing_id}",
                'brand': 'Test Brand',
                'category': 'Test Category',
                'created_at': 1640995200.0,
                'updated_at': 1640995200.0
            }
        
        @staticmethod
        def create_test_evidence(evidence_id="test-evidence", thing_id="test-thing", account_id="test-account"):
            return {
                'id': evidence_id,
                'thing_account_id': account_id,
                'thing_id': thing_id,
                'name': f"Test Evidence {evidence_id}",
                'description': f"Description for {evidence_id}",
                'url': f"https://example.com/evidence/{evidence_id}",
                'created_at': 1640995200.0,
                'updated_at': 1640995200.0
            }
    
    return TestDataGenerator()


# Performance monitoring
@pytest.fixture
def performance_monitor():
    """Monitor performance during tests."""
    import time
    import psutil
    import os
    
    class PerformanceMonitor:
        def __init__(self):
            self.process = psutil.Process(os.getpid())
            self.start_time = None
            self.start_memory = None
        
        def start(self):
            self.start_time = time.time()
            self.start_memory = self.process.memory_info().rss
        
        def stop(self):
            if self.start_time is None:
                return None
            
            end_time = time.time()
            end_memory = self.process.memory_info().rss
            
            return {
                'duration': end_time - self.start_time,
                'memory_delta': end_memory - self.start_memory,
                'peak_memory': end_memory
            }
    
    return PerformanceMonitor()


# Skip conditions
def pytest_runtest_setup(item):
    """Set up individual test runs with skip conditions."""
    # Skip slow tests if --fast flag is used
    if item.config.getoption("--fast", default=False):
        if "slow" in item.keywords:
            pytest.skip("Skipping slow test due to --fast flag")
    
    # Skip performance tests if system resources are limited
    if "performance" in item.keywords:
        import psutil
        available_memory = psutil.virtual_memory().available
        # Skip if less than 1GB available memory
        if available_memory < 1024 * 1024 * 1024:
            pytest.skip("Skipping performance test due to limited memory")


# Add custom command line options
def pytest_addoption(parser):
    """Add custom command line options."""
    parser.addoption(
        "--fast",
        action="store_true",
        default=False,
        help="Skip slow tests"
    )
    parser.addoption(
        "--no-cleanup",
        action="store_true",
        default=False,
        help="Don't cleanup temporary files (for debugging)"
    )


# Test reporting
@pytest.fixture(autouse=True)
def test_reporter(request):
    """Report test progress and results."""
    test_name = request.node.name
    
    # Log test start
    print(f"\n🧪 Starting test: {test_name}")
    
    yield
    
    # Log test completion
    if hasattr(request.node, 'rep_call') and request.node.rep_call.failed:
        print(f"❌ Test failed: {test_name}")
    else:
        print(f"✅ Test passed: {test_name}")


@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Make test reports available to fixtures."""
    outcome = yield
    rep = outcome.get_result()
    setattr(item, f"rep_{rep.when}", rep)
