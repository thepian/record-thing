#!/bin/bash
# Update the database schema to the latest version

# Change to the project root directory
cd "$(dirname "$0")/.." || exit 1

# Define paths
DB_PATH="libs/record_thing/record-thing.sqlite"
BACKUP_PATH="libs/record_thing/record-thing-backup-$(date +%Y%m%d_%H%M%S).sqlite"

# Backup existing database if it exists
if [ -f "$DB_PATH" ]; then
    echo "Backing up existing database to $BACKUP_PATH"
    cp "$DB_PATH" "$BACKUP_PATH"
fi

# Update schema
echo "Updating database schema..."
PYTHONPATH="$PWD" uv run -m libs.record_thing.db_setup --update

# Show database info
echo "Database schema updated. Here's the summary:"
PYTHONPATH="$PWD" uv run -m libs.record_thing.db_setup --info

echo "Done!"