#!/usr/bin/env python
"""
Run all integration tests for the record_thing library.
"""
import sys
import unittest
import logging
from pathlib import Path

# Add the parent directory to the Python path if running directly
parent_dir = Path(__file__).parent.parent.parent
if parent_dir not in sys.path:
    sys.path.insert(0, str(parent_dir))

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

# Set specific module loggers to a higher level to reduce noise during tests
for module in [
    "record_thing.db.connection",
    "record_thing.db.schema",
    "record_thing.db.operations",
]:
    logging.getLogger(module).setLevel(logging.WARNING)


def run_tests():
    """Discover and run all tests."""
    # Discover and run all tests
    test_suite = unittest.defaultTestLoader.discover(
        start_dir=Path(__file__).parent, pattern="test_*.py"
    )

    # Run the tests
    result = unittest.TextTestRunner(verbosity=2).run(test_suite)

    # Return True if all tests passed
    return result.wasSuccessful()


if __name__ == "__main__":
    # Exit with non-zero code if tests failed
    sys.exit(0 if run_tests() else 1)
