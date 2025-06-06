# RecordThing Test Suite

A comprehensive, non-destructive test suite for the RecordThing Python codebase with GitHub Actions integration.

## Overview

This test suite provides comprehensive coverage for:

- ✅ **Database Creation**: Testing creation of `libs/record_thing/record-thing.sqlite` from scratch
- ✅ **Schema Migration**: Testing database updates with latest schema changes
- ✅ **Demo Data Generation**: Testing creation of demo account data and realistic test scenarios
- ✅ **iOS Compatibility**: Testing database compatibility with Blackbird models
- ✅ **Performance Testing**: Stress testing and performance validation
- ✅ **Full Integration**: End-to-end workflow testing

## Test Structure

### Test Files

- `test_database_creation.py` - Database creation from scratch
- `test_schema_migration.py` - Schema updates and migrations
- `test_data_generation.py` - Demo data and test data generation
- `test_ios_compatibility.py` - iOS app compatibility with Blackbird models
- `test_performance.py` - Performance and stress testing
- `test_full_integration.py` - Complete integration testing

### Utility Files

- `generate_large_dataset.py` - Generate large datasets for testing
- `generate_test_docs.py` - Generate test coverage documentation
- `conftest.py` - Pytest configuration and fixtures

## Running Tests

### Prerequisites

- Python 3.11 or 3.12
- UV package manager
- Git repository cloned

### Installation

```bash
# Install dependencies
uv sync --all-extras

# Or install test dependencies specifically
uv add pytest pytest-cov pytest-xdist pytest-timeout psutil
```

### Basic Test Execution

```bash
# Run all tests
uv run -m pytest tests/ -v

# Run with coverage
uv run -m pytest tests/ -v --cov=record_thing --cov-report=html

# Run specific test categories
uv run -m pytest tests/test_database_creation.py -v
uv run -m pytest tests/test_ios_compatibility.py -v

# Run tests in parallel
uv run -m pytest tests/ -v -n auto

# Skip slow tests
uv run -m pytest tests/ -v -m "not slow"
```

### Test Categories

```bash
# Integration tests only
uv run -m pytest tests/ -v -m integration

# Performance tests only
uv run -m pytest tests/ -v -m performance

# iOS compatibility tests only
uv run -m pytest tests/ -v -m ios

# Fast tests only (skip slow ones)
uv run -m pytest tests/ -v -m "not slow"
```

### Advanced Options

```bash
# Run with timeout protection
uv run -m pytest tests/ -v --timeout=300

# Generate detailed coverage report
uv run -m pytest tests/ -v --cov=record_thing --cov-report=html --cov-report=xml --cov-report=term-missing

# Run specific test by name
uv run -m pytest tests/ -v -k "test_create_database"

# Show test output (don't capture)
uv run -m pytest tests/ -v -s

# Stop on first failure
uv run -m pytest tests/ -v -x
```

## Test Scenarios

### Database Creation Tests

- Empty database creation
- Database with schema creation
- Database with sample data creation
- Schema integrity validation
- Index creation and performance
- Multiple database creation
- Edge cases (unicode paths, nested directories)

### Schema Migration Tests

- Empty database migration
- Data preservation during migration
- Adding missing tables and columns
- Foreign key constraint handling
- Idempotent migrations
- Large database migration
- Error recovery

### Data Generation Tests

- Demo account creation
- Universe/use case data generation
- Things and evidence data generation
- Product and document type generation
- Data relationship validation
- Data consistency checks
- Multiple test scenarios

### iOS Compatibility Tests

- Blackbird model schema compatibility
- Data type compatibility (String, Int, Bool, Date)
- JSON data compatibility
- Primary key and foreign key compatibility
- Unicode data handling
- NULL value handling
- Query performance for mobile

### Performance Tests

- Database creation performance
- Large query performance
- Concurrent read performance
- Memory usage monitoring
- Database size efficiency
- Index performance
- Stress testing

## GitHub Actions Integration

The test suite is fully integrated with GitHub Actions:

### Workflow Features

- **Multi-platform**: Tests run on Ubuntu and macOS
- **Multi-version**: Tests run on Python 3.11 and 3.12
- **UV Integration**: Uses UV package manager for fast dependency management
- **Coverage Reporting**: Generates and uploads coverage reports
- **Artifact Generation**: Creates test databases and documentation
- **Performance Monitoring**: Tracks test execution time
- **Timeout Protection**: Prevents hanging tests

### Workflow Stages

1. **Unit Tests**: Basic functionality and connection tests
2. **Database Creation**: Fresh database creation from scratch
3. **Schema Migration**: Database updates and migrations
4. **Data Generation**: Demo data and realistic test data
5. **iOS Compatibility**: Blackbird model compatibility
6. **Performance Tests**: Stress testing and performance validation
7. **Integration Tests**: Full workflow testing

### Artifacts Generated

- `fresh-database.sqlite` - Clean database with schema only
- `demo-database.sqlite` - Database with demo data
- `large-dataset.sqlite` - Database with substantial test data
- `coverage.xml` - Test coverage report
- `htmlcov/` - HTML coverage report
- `test-documentation/` - Generated documentation

## Test Data and Use Cases

### Use Cases Tested

1. **Home Inventory**: Electronics, furniture, appliances, tools, sports equipment
2. **Business Assets**: Office equipment, vehicles, IT hardware, furniture, tools
3. **Collections**: Art, antiques, collectibles, books, instruments

### Test Scenarios

1. **Complete Home Inventory**: 50 things, 5 evidence per thing, 10 requests
2. **Business Asset Tracking**: 100 things, 3 evidence per thing, 20 requests
3. **Art Collection**: 25 things, 8 evidence per thing, 5 requests
4. **Mixed Use Case**: 75 things, 4 evidence per thing, 15 requests

## iOS Blackbird Model Correlation

The test suite validates compatibility between Swift Blackbird models and SQLite schema:

### Tested Models

- `Account` ↔ `accounts` table
- `Things` ↔ `things` table
- `Evidence` ↔ `evidence` table
- `EvidenceType` ↔ `evidence_type` table
- `Requests` ↔ `requests` table

### Validation Areas

- Column name and type compatibility
- Primary key constraints
- Foreign key relationships
- JSON field serialization
- Unicode character support
- NULL value handling
- Query performance

## Generating Test Documentation

```bash
# Generate comprehensive test documentation
uv run python tests/generate_test_docs.py

# This creates:
# - docs/testing/test_coverage_report.html
# - docs/testing/test_coverage_data.json
# - docs/testing/README.md
```

## Generating Large Datasets

```bash
# Generate large dataset for performance testing
uv run python tests/generate_large_dataset.py artifacts/large-test.sqlite

# This creates a database with:
# - 2000 things
# - 8000 evidence records (4 per thing)
# - 400 requests
# - 150 evidence types
# - 75 document types
```

## Troubleshooting

### Common Issues

1. **Import Errors**: Ensure you're running from the project root and have installed dependencies
2. **Database Lock Errors**: Make sure no other processes are using test databases
3. **Memory Issues**: Performance tests may require sufficient available memory
4. **Timeout Issues**: Increase timeout values for slow systems

### Debug Mode

```bash
# Run with verbose output and no capture
uv run -m pytest tests/ -v -s --tb=long

# Run single test with debugging
uv run -m pytest tests/test_database_creation.py::TestDatabaseCreation::test_create_database_with_schema -v -s

# Keep temporary files for inspection
uv run -m pytest tests/ -v --no-cleanup
```

### Performance Tuning

```bash
# Run tests in parallel for speed
uv run -m pytest tests/ -v -n auto

# Skip slow tests for quick validation
uv run -m pytest tests/ -v -m "not slow"

# Run only fast unit tests
uv run -m pytest libs/record_thing/tests/ -v
```

## Contributing

When adding new tests:

1. Follow the existing test structure and naming conventions
2. Use appropriate pytest markers (`@pytest.mark.slow`, `@pytest.mark.ios`, etc.)
3. Include docstrings explaining what the test validates
4. Use the provided fixtures for database setup
5. Ensure tests are non-destructive and use temporary files
6. Add new test scenarios to the documentation generator

## License

This test suite is part of the RecordThing project and follows the same license terms.
