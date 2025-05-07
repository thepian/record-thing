#!/bin/bash
# Run tests for the record-thing library

# Change to the project root directory
cd "$(dirname "$0")/.." || exit 1

echo "Installing test dependencies..."
uv pip install -q pytest pytest-cov

echo "Running tests..."
PYTHONPATH="$PWD" uv run -m pytest libs/record_thing/tests -v

# Exit with the same code as pytest
exit $?