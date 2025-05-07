# Record Thing CLI

The Record Thing CLI provides commands for managing the database and performing other tasks related to the Record Thing application.

## Installation

The CLI is part of the Record Thing package. To use it, first set up the Python environment:

```bash
# Using uv (faster)
uv venv
source .venv/bin/activate
uv pip install -e .

# Or using pip
python -m venv .venv
source .venv/bin/activate
pip install -e .
```

## Commands

### Database Management

#### Initialize Database

Initialize a new database with the Record Thing schema or view information about an existing one:

```bash
uv run -m record_thing.cli init-db

# With custom database path
uv run -m record_thing.cli init-db --db-path /path/to/database.sqlite
```

#### Force Reset Database

Force reset an existing database:

```bash
uv run -m record_thing.cli init-db --force
```

#### Update Database Schema

Update the database schema without losing data:

```bash
uv run -m record_thing.cli update-db

# With custom database path
uv run -m record_thing.cli update-db --db-path /path/to/database.sqlite
```

This command is useful when:
- New tables have been added to the schema
- You've upgraded to a newer version of the application
- Your database is missing tables that should be there

#### Create Tables Only

Create database tables without adding sample data:

```bash
uv run -m record_thing.cli tables-db

# With custom database path
uv run -m record_thing.cli tables-db --db-path /path/to/database.sqlite
```

#### Populate with Sample Data

Add sample data to an existing database:

```bash
uv run -m record_thing.cli populate-db

# With custom database path
uv run -m record_thing.cli populate-db --db-path /path/to/database.sqlite
```

#### Test Database Connection

Test the connection to the database and display information about it:

```bash
# Basic connection test
uv run -m record_thing.cli test-db

# Verbose output (includes table information)
uv run -m record_thing.cli test-db -v

# Custom database path
uv run -m record_thing.cli test-db --db-path /path/to/database.sqlite -v
```

## VSCode Integration

The Record Thing workspace includes launch configurations for running CLI commands:

1. Open the Run view in VSCode (Ctrl+Shift+D)
2. Select one of the "Record Thing CLI" configurations from the dropdown:
   - "Record Thing CLI: Initialize Database"
   - "Record Thing CLI: Initialize Database (Force)"
   - "Record Thing CLI: Test Database"
   - "Record Thing CLI: Test Database (Custom Path)"
3. Click the Run button (green triangle) or press F5

## Usage in Scripts

You can use the CLI in your own scripts:

```bash
#!/bin/bash
# Example script to initialize the database

# Set PYTHONPATH to find the record_thing package
export PYTHONPATH="/path/to/record-thing"

# Initialize the database
uv run -m record_thing.cli init-db --force

# Test the connection
uv run -m record_thing.cli test-db -v
```

## Troubleshooting

If you encounter issues with the CLI, try the following:

1. Make sure your Python environment is activated
2. Check that the package is installed correctly with `pip list | grep record-thing`
3. Verify the database path is correct
4. Check the application logs for error messages