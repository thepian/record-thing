# Demo Content Management

This document outlines the process for managing demo content, including demo accounts, assets, database initialization, and team configurations for the Record Thing application. It covers the complete workflow from content creation to distribution.

## Overview

The Record Thing application uses a combination of:

- A SQLite database with predefined schema and demo data
- Media assets stored in cloud storage buckets
- Team and user account configurations

When rolling out new content or making updates, we need to coordinate these components to ensure consistency across all environments.

```
Demo Content Flow
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│                 │     │                  │     │                 │
│ Content Creation│────►│ Sync & Validation│────►│ Distribution    │
│                 │     │                  │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## Content Components

### 1. Demo Database

The demo database (`record-thing.sqlite`) contains:

- Demo account information
- Demo team configurations
- Sample items, evidence, and requests
- Reference data (categories, product types, etc.)

### 2. Demo Assets

Media assets include:

- Images for sample items
- Document scans for evidence records
- UI illustrations and icons

These assets are stored in the `recordthing-demo` bucket and are referenced in the database.

### 3. Team Configuration

Team configurations determine bucket access and tier capabilities:

- `FREE_TEAM_ID` - Free tier users (uses `recordthing-common` bucket)
- `PREMIUM_TEAM_ID` - Premium tier users (uses `recordthing-premium` bucket)

## Content Update Process

### Step 1: Download Current Content

Start by downloading the current demo content from the central storage bucket:

```bash
# Set up authentication credentials
export BUNNY_API_KEY="your-api-key"
export BUNNY_STORAGE_ZONE="recordthing-demo"

# Download the current database
uv run -m record_thing.bunny.sync download --source database/record-thing.sqlite --dest ./temp/record-thing.sqlite

# Download demo assets folder
uv run -m record_thing.bunny.sync download-dir --source demo_assets/ --dest ./temp/demo_assets/
```

### Step 2: Make Local Changes

#### Database Updates

1. Create a local working copy of the database:

```bash
cp ./temp/record-thing.sqlite ./working/record-thing.sqlite
```

2. Make changes to the database schema or content:

```bash
# Update the database schema
uv run -m record_thing.cli update-db --db-path ./working/record-thing.sqlite

# Populate with updated content
uv run -m record_thing.cli populate-db --db-path ./working/record-thing.sqlite
```

3. For custom SQL modifications:

```bash
sqlite3 ./working/record-thing.sqlite
```

#### Asset Updates

1. Organize new assets in the appropriate folder structure:

   - `/demo_assets/things/` - Item images
   - `/demo_assets/evidence/` - Evidence documents
   - `/demo_assets/ui/` - UI elements

2. Ensure assets are properly named and optimized:
   - Use consistent naming conventions
   - Compress images appropriately
   - Remove metadata if necessary

### Step 3: Validate Content

Before distribution, validate the updated content:

```bash
# Check database integrity
uv run -m record_thing.cli test-db --db-path ./working/record-thing.sqlite -v

# Verify team configurations
sqlite3 ./working/record-thing.sqlite "SELECT * FROM teams;"

# Check for missing assets
uv run -m record_thing.bunny.sync verify-refs --db-path ./working/record-thing.sqlite --assets-dir ./working/demo_assets/
```

### Step 4: Update Team Configurations

Ensure the teams table contains the required entries for FREE_TEAM_ID and PREMIUM_TEAM_ID:

```bash
# If using the CLI
uv run -m record_thing.cli update-db --db-path ./working/record-thing.sqlite

# Directly using SQLite
sqlite3 ./working/record-thing.sqlite << EOF
INSERT OR REPLACE INTO teams (
    team_id, name, region, tier, is_demo, is_active,
    storage_domain, storage_bucket_name, storage_bucket_region,
    fallback_domain, fallback_bucket_name, fallback_bucket_region,
    created_at, updated_at
) VALUES (
    '2wokkB1WCfyZq3lcahGCMd53zZ7', -- FREE_TEAM_ID
    'Free Tier',
    'EU',
    'free',
    0,
    1,
    'storage.bunnycdn.com',
    'recordthing-demo',
    'eu',
    'storage.bunnycdn.com',
    'recordthing-demo',
    'eu',
    0.0,
    0.0
);

INSERT OR REPLACE INTO teams (
    team_id, name, region, tier, is_demo, is_active,
    storage_domain, storage_bucket_name, storage_bucket_region,
    fallback_domain, fallback_bucket_name, fallback_bucket_region,
    created_at, updated_at
) VALUES (
    '2wokwJClVrkYDmyT5jGZliWR924', -- PREMIUM_TEAM_ID
    'Premium Tier',
    'EU',
    'premium',
    0,
    1,
    'storage.bunnycdn.com',
    'recordthing-premium',
    'eu',
    'storage.bunnycdn.com',
    'recordthing-demo',
    'eu',
    0.0,
    0.0
);
EOF
```

### Step 5: Distribute to Storage Buckets

Once validated, distribute the updated content to all relevant storage buckets:

```bash
# Upload database to the demo bucket
uv run -m record_thing.bunny.sync upload --source ./working/record-thing.sqlite --dest database/record-thing.sqlite --bucket recordthing-demo

# Upload new assets to demo bucket
uv run -m record_thing.bunny.sync upload-dir --source ./working/demo_assets/ --dest demo_assets/ --bucket recordthing-demo

# Copy demo database to premium bucket (ensuring it's available in both tiers)
uv run -m record_thing.bunny.sync copy --source database/record-thing.sqlite --from-bucket recordthing-demo --dest database/record-thing.sqlite --to-bucket recordthing-premium
```

### Step 6: Update App Bundle Database

For new app releases, update the bundled database:

1. Copy the validated database to the app's resource directory:

```bash
cp ./working/record-thing.sqlite apps/RecordThing/Shared/Resources/default-record-thing.sqlite
```

2. Rebuild the app to include the updated database file.

## App Database Update Process

The Record Thing app handles database updates as follows:

1. **Initial Installation**: The app is bundled with a default database file located at `default-record-thing.sqlite`.

2. **First Launch**: The app:

   - Copies the bundled database to the app's documents directory
   - Establishes connection to the account's team bucket
   - Downloads any available updates

3. **Subsequent Updates**:
   - The app periodically checks for database updates in the team's bucket
   - If found, it downloads the updated database
   - Performs schema migration to preserve user data while adding new tables/columns
   - Updates the teams configuration if necessary

## Managing Team Buckets

Teams determine which storage bucket users have access to:

1. **Free Tier Users**:

   - `recordthing-demo` bucket
   - Limited to demo content only

2. **Premium Tier Users**:

   - `recordthing-premium` bucket
   - Access to premium assets and features
   - Falls back to `recordthing-demo` for core content

3. **Future Enterprise Tier**:
   - Team-specific buckets (`recordthing-enterprise-{team_id}`)
   - Custom content uploaded by enterprise administrators
   - Falls back to premium and demo buckets as needed

## Versioning and Migration

Database versioning is handled using schema migrations:

1. **Schema Migrations Table**:

   ```sql
   CREATE TABLE IF NOT EXISTS schema_migrations (
       version INTEGER PRIMARY KEY,
       description TEXT NOT NULL,
       applied_at TEXT DEFAULT CURRENT_TIMESTAMP
   )
   ```

2. **Migration Process**:
   - The app detects new tables/columns in the updated database file
   - It applies these changes to the user's database
   - Teams ensure the app downloads the correct database version

## Troubleshooting

Common issues and solutions:

1. **Missing Teams Configuration**:

   - Run `uv run -m record_thing.cli update-db` to ensure teams are configured
   - Check that `FREE_TEAM_ID` and `PREMIUM_TEAM_ID` match the constants in `commons.py`

2. **Asset References Not Found**:

   - Ensure all assets referenced in the database exist in the appropriate bucket
   - Use the verification tool to find missing references

3. **Database Schema Mismatch**:
   - Run `sqlite3 ./path/to/db.sqlite .schema` to inspect the schema
   - Compare with expected schema in SQL files
   - Use `migrate_schema` function to update to latest schema

## Best Practices

1. **Documentation**:

   - Document all changes to the demo database and assets
   - Include screenshots and descriptions of new content

2. **Versioning**:

   - Version all database updates incrementally
   - Use comments in SQL scripts to indicate which version changes were introduced

3. **Testing**:

   - Test database updates on all supported platforms
   - Verify that migrations work correctly for existing users

4. **Backup**:

   - Always backup the current database before making changes
   - Keep multiple versions of the database to allow rollbacks if needed

5. **Content Guidelines**:
   - Use realistic but non-sensitive data for demo content
   - Follow naming conventions for assets and database entries
   - Optimize assets for mobile devices

## Future Improvements

1. **Admin Panel**:

   - Develop a web-based admin panel for managing demo content
   - Allow non-technical team members to update content

2. **Automatic Asset Optimization**:

   - Implement tools to automatically optimize and process assets
   - Generate multiple resolutions for different device types

3. **Content Analytics**:

   - Track which demo content is most frequently used
   - Use analytics to guide content improvements

4. **Multi-Region Support**:
   - Distribute content to multiple regions for better performance
   - Implement region-specific content for localization
