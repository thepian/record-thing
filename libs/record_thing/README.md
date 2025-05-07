# Record Thing Library

[![Python Versions](https://img.shields.io/badge/python-3.8%20%7C%203.9%20%7C%203.10-blue)](https://www.python.org/)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)

A comprehensive Python library for managing data synchronization, authentication, and reference data for the Record Thing mobile application. This library facilitates the server-side operations and data handling required to support the Record Thing ecosystem.

## Overview

Record Thing is an application that helps users record, recognize, and organize physical items using computer vision and machine learning. This library provides the server-side components needed to:

- Synchronize data between local SQLite databases and cloud Storage Buckets
- Manage user authentication and team membership
- Set up and maintain reference and demo data
- Process and organize product information and categorization

## Key Features

- **Data Synchronization**: Bi-directional sync between local SQLite databases and cloud storage using the Buckia library
- **Database Management**: SQLite schema creation, migrations, and consistency checks
- **Authentication**: WorkOS integration for secure passkey-based authentication
- **Reference Data**: Tools for managing product types, brands, and categorization
- **Team Management**: User and team setup with appropriate permissions and storage access
- **Demo Support**: Creation and maintenance of demo data for new users

## Installation

```bash
# Basic installation
pip install record-thing

# Development installation
pip install -e ".[dev]"
```

## Project Structure

```
record_thing/
├── __init__.py
├── commons.py           # Common utilities and constants
├── auth/                # Authentication
│   ├── __init__.py
│   ├── workos.py        # WorkOS integration
│   └── tokens.py        # Token management
├── db/                  # Database management
│   ├── __init__.py
│   ├── schema.py        # Schema definition and migrations
│   ├── account.sql      # SQL definitions for accounts
│   ├── evidence.sql     # SQL definitions for evidence
│   └── ...              # Other SQL schema files
├── sync/                # Sync management
│   ├── __init__.py
│   ├── bucket.py        # Storage bucket operations
│   └── local.py         # Local file operations
└── management/          # Management commands
    ├── __init__.py
    ├── setup_demo.py    # Demo data setup
    ├── import_brands.py # Import brand data
    └── ...              # Other management commands
```

## Quick Start

### Initialize a database

```python
import sqlite3
from record_thing.db import schema

# Create and initialize a new database
conn = sqlite3.connect("record-thing.sqlite")
schema.init_db_tables(conn)

# Ensure an owner account exists
schema.ensure_owner_account(conn, dummy_account_data=True)
```

### Sync with a storage bucket

```python
from buckia import BuckiaClient, BucketConfig
from record_thing.sync.bucket import get_bucket_config

# Get configuration for a specific team
config = get_bucket_config(team_id="2siiTeamIdExample123456")

# Create client and sync
client = BuckiaClient(config)
result = client.sync(
    local_path="./assets/user/2siiUserIdExample123456",
    delete_orphaned=True
)

print(f"Sync completed: {result.uploaded} uploaded, {result.downloaded} downloaded")
```

### Set up demo data

```python
from record_thing.management.setup_demo import setup_demo_data

# Initialize demo data in database and prepare for upload
conn = sqlite3.connect("record-thing.sqlite")
setup_demo_data(conn, demo_team_id="2siiDemoTeamIdExample")
```

## Database Schema

The Record Thing library manages an SQLite database with the following core tables:

- **accounts**: Users of the Record Thing app
- **owners**: The account ID used to create new data on a node
- **universe**: Configuration sets that define app functionality
- **things**: Physical items belonging to users
- **evidence**: Records that provide evidence of a thing
- **requests**: Evidence gathering actions users complete
- **products, brands, companies**: Reference data for item identification

For a complete database schema reference, see [DATABASE.md](../../docs/DATABASE.md).

## Storage Bucket Structure

The library manages data in cloud storage buckets with the following structure:

```
storage-bucket/
├── <team-id>/          # Team folder for shared resources
│   ├── App.sqlite      # Reference database
│   ├── models/         # ML models 
│   └── assets/         # Shared assets
└── <user-id>/          # User folders
    ├── user.sqlite     # User database backup
    └── assets/         # User-specific assets
```

## Authentication

Authentication is handled through WorkOS, primarily using passkeys (biometric). The library provides utilities for:

- User registration and credential management
- Authentication and token acquisition
- Access control for storage buckets

## CLI Usage

The library includes command-line tools for common operations:

```bash
# Initialize a new database
uv run -m record_thing.cli init-db

# Import reference data
uv run -m record_thing.cli import-brands

# Set up demo data
uv run -m record_thing.cli setup-demo --team-id 2siiDemoTeamIdExample

# Sync user data
uv run -m record_thing.cli sync-user --user-id 2siiUserIdExample
```

## Development

### Setting up a development environment

```bash
# Clone the repository
git clone https://github.com/yourusername/record-thing.git
cd record-thing

# Create a virtual environment
uv run -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install development dependencies
pip install -e ".[dev]"

# Run tests
pytest
```

### Code Style

This project uses:
- [Black](https://github.com/psf/black) for code formatting
- [Mypy](https://mypy.readthedocs.io/) for type checking
- [Pylint](https://www.pylint.org/) for linting

```bash
# Format code
black libs/record_thing

# Check types
mypy libs/record_thing

# Run linter
pylint libs/record_thing
```

## License

Closed Source.
(c) 2025 Henrik Vendelbo. All rights reserved.

