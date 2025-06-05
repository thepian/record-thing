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

# Future CLI buckia commands

# Future CLI enhancement ideas

TODO move to record-thing

# Buckia Python Package and CLI: BackOffice Management Capabilities

## Overview

The Buckia Python package and CLI provide comprehensive backoffice management capabilities to support RecordThing's team-based architecture. These tools enable administrators to efficiently manage users, content, and system resources across different teams, with each team maintaining its own storage configuration, tier settings, and administrative controls.

## Core Functionality

### Team-Centric Management

The backoffice tools are designed around a team-centric approach, recognizing that:

- Teams are the primary organizational unit in RecordThing
- Each team has its own storage configuration and server locations
- Users belong to specific teams that determine their available features
- Administrative actions typically target specific teams rather than global tiers

This architecture ensures proper isolation, security, and customization while maintaining a consistent management interface.

## Backoffice Tasks and Capabilities

### User Management

The backoffice tools support the complete user lifecycle within teams:

**User Tier Migration**

- Migrate users between tiers while preserving their content and sharing relationships
- Ensure appropriate storage allocation based on team settings
- Handle permission changes and feature access updates
- Maintain integrity of user data during transitions

```bash
buckia user migrate --user-id="user123" --target-tier="premium" --team-id="team456" --preserve-shares --preserve-recordings
```

**Batch User Operations**

- Import multiple users from external systems with team assignments
- Apply bulk changes to user groups within specified teams
- Generate reports on user status and activities
- Automate onboarding processes for new team members

```bash
buckia bulk import-users --source="new_users.csv" --mapping-column="team_name" --default-tier="free"
```

**Account Management**

- Temporarily suspend user access without data loss
- Merge duplicate accounts within teams
- Implement access controls based on team policies
- Handle account transitions during organizational changes

```bash
buckia user suspend --user-id="user123" --team-id="team456" --reason="Payment lapsed" --duration="14d" --notification="email"
```

### Content and Data Management

Tools for ensuring data integrity and optimizing content across team environments:

**Database Maintenance**

- Scan and repair corrupted SQLite databases for specific users
- Apply schema updates across team databases
- Manage differential updates and synchronization
- Ensure consistency between local and cloud storage

```bash
buckia db repair --user-id="user123" --team-id="team456" --corruption-check="deep" --auto-fix --backup-first
```

**Content Optimization**

- Identify and remove duplicate recordings within user accounts
- Implement storage optimizations based on team policies
- Move infrequently accessed content to cold storage
- Maintain proper references in database after content changes

```bash
buckia content deduplicate --user-id="user123" --team-id="team456" --similarity-threshold="0.95" --strategy="keep-newest"
```

**Content Moderation and Classification**

- Flag potentially prohibited content for review within teams
- Correct AI classification errors across content libraries
- Apply consistent categorization for similar items
- Update AI training sets based on corrected data

```bash
buckia content moderate --team-id="team456" --sensitivity="high" --queue="content-review" --auto-notify-admins
```

### System Maintenance

Tools for optimizing performance and resource utilization:

**Storage Optimization**

- Move infrequently accessed recordings to cold storage
- Remove content from CDN while preserving in backend storage
- Apply team-specific retention policies
- Optimize storage costs while maintaining access when needed

```bash
buckia storage optimize --team-id="team456" --access-pattern="inactive-90d" --target-storage="cold" --remove-from-cdn
```

**Usage Analytics**

- Generate detailed storage utilization reports by team
- Track access patterns to optimize caching strategies
- Monitor growth trends to plan capacity
- Identify anomalous usage patterns

```bash
buckia system stats --report="storage-utilization" --team-id="team456" --period="last-month" --format="pdf"
```

**Demo Environment Management**

- Apply security updates to team demo environments
- Create customized demos for potential clients
- Maintain consistent demo experiences across teams
- Track demo usage and engagement

```bash
buckia demo update-security --team-id="team456" --patch-version="1.2.3" --all-versions --validate-after-update
```

### Investigation and Auditing

Tools for troubleshooting issues and ensuring compliance:

**Content Sharing Analysis**

- Track content sharing across users within teams
- Visualize sharing relationships and access patterns
- Identify potential security or privacy concerns
- Optimize sharing workflows based on usage data

```bash
buckia audit sharing --team-id="team456" --content-id="rec123" --include-views --timeline --visualize-graph
```

**Synchronization Diagnostics**

- Investigate sync failures for specific users
- Generate comprehensive diagnostic reports
- Identify patterns in sync issues across devices
- Recommend solutions for persistent problems

```bash
buckia diagnose sync --user-id="user123" --team-id="team456" --last-days=7 --include-device-logs --generate-report
```

**AI Performance Analysis**

- Analyze classification failures within specific teams
- Generate targeted training sets to improve accuracy
- Track AI performance metrics over time
- Implement team-specific model improvements

```bash
buckia training analyze-failures --team-id="team456" --period="last-month" --min-confidence=0.8 --group-by="object-type"
```

**Access Pattern Analysis**

- Generate detailed reports on content access
- Optimize CDN configuration based on team usage patterns
- Identify geographic distribution of access
- Determine peak usage times for capacity planning

```bash
buckia audit access --team-id="team456" --content-type="recordings" --period="last-week" --geo-distribution --peak-hours
```

### Advanced Administrative Functions

Tools for handling complex organizational changes and compliance requirements:

**Custom Demo Creation**

- Build specialized demo environments for potential clients
- Customize content based on industry verticals
- Create targeted demonstrations of key features
- Optimize demo performance for sales presentations

```bash
buckia demo create-custom --team-id="team456" --base-version="v2.5" --client-name="Acme Corp" --vertical="manufacturing"
```

**Team Restructuring**

- Split teams due to organizational changes
- Reassign users to new team structures
- Maintain data integrity during transitions
- Ensure appropriate access controls after changes

```bash
buckia team split --team-id="team123" --new-teams="engineering,marketing" --user-mapping="team_split.csv" --notify-users
```

**Privacy Compliance**

- Implement GDPR right-to-be-forgotten requests
- Apply team-specific compliance requirements
- Generate compliance certificates and documentation
- Preserve aggregate data while removing personal information

```bash
buckia privacy forget-user --user-id="user123" --team-id="team456" --compliance="gdpr" --preserve-aggregate-data
```

**Storage Provider Migration**

- Migrate team data between storage providers
- Validate data integrity during transitions
- Optimize transfer processes for efficiency
- Update references and access paths after migration

```bash
buckia system migrate-storage --team-id="team456" --source-provider="s3" --target-provider="bunny" --validate-integrity
```

## Technical Implementation

### Configuration Structure

The `.buckia` configuration file supports team-based management with hierarchical settings:

```yaml
teams:
  TEAM_ID:
    name: "Team Name"
    storage:
      primary_provider: "provider_type"
      bucket_name: "bucket_name"
      region: "region_name"
    tiers:
      free:
        # Tier-specific settings
      premium:
        # Tier-specific settings
    # Additional team settings
```

### Authentication and Authorization

The backoffice tools implement role-based access control:

- Administrators can be assigned to specific teams
- Permissions are granular and can be limited to specific operation types
- All actions are logged for audit purposes
- Multi-factor authentication for sensitive operations

### Integration with RecordThing

The backoffice tools integrate seamlessly with RecordThing's architecture:

- Respect the team-based organization structure
- Maintain consistency with the RecordThing database schema
- Support the same storage bucket structure used by client applications
- Ensure backward compatibility with existing deployments

## Benefits for RecordThing Operations

The backoffice management capabilities provide significant operational advantages:

1. **Efficient Team Management**: Administrators can focus on their specific teams without affecting other parts of the system

2. **Granular Control**: Actions can target specific users, content, or system components within teams

3. **Consistency**: Standard operations are implemented consistently across all management interfaces

4. **Auditability**: All administrative actions are logged and traceable to specific administrators

5. **Automation**: Common tasks can be scripted and scheduled, reducing manual intervention

6. **Scalability**: The team-based approach allows the system to scale to support many teams without performance degradation

## Conclusion

The Buckia Python package and CLI provide a comprehensive suite of backoffice management capabilities designed specifically for RecordThing's team-based architecture. These tools enable administrators to efficiently manage users, content, and system resources while maintaining proper isolation between teams. By focusing on team-specific operations rather than global changes, the backoffice tools ensure that administrative actions are targeted, efficient, and secure, supporting RecordThing's unique operational requirements across free and premium tiers.

---

# Refined Backoffice Tasks for RecordThing

Based on your feedback, I've refined the list to focus on valid tasks with the correct team-based approach, rather than tier-based. Here's the updated list of backoffice tasks that align with your requirements:

## User Management Tasks

1. **Migrate a user from Free tier to Premium tier while preserving all their recordings and sharing relationships**

   ```bash
   buckia user migrate --user-id="user123" --target-tier="premium" --team-id="team456" --preserve-shares --preserve-recordings
   ```

2. **Import a batch of users from a CSV file and assign them to specific teams**

   ```bash
   buckia bulk import-users --source="new_users.csv" --mapping-column="team_name" --default-tier="free"
   ```

3. **Temporarily suspend a user's access without deleting their data**

   ```bash
   buckia user suspend --user-id="user123" --team-id="team456" --reason="Payment lapsed" --duration="14d" --notification="email"
   ```

4. **Merge two user accounts when a user has accidentally created duplicates**
   ```bash
   buckia user merge --source-id="user123" --target-id="user456" --team-id="team789" --conflict-resolution="newest-wins"
   ```

## Content Management Tasks

5. **Scan and repair corrupted SQLite database files for a specific user**

   ```bash
   buckia db repair --user-id="user123" --team-id="team456" --corruption-check="deep" --auto-fix --backup-first
   ```

6. **Identify and remove duplicate recordings across a user's account**

   ```bash
   buckia content deduplicate --user-id="user123" --team-id="team456" --similarity-threshold="0.95" --strategy="keep-newest"
   ```

7. **Flag recordings containing potential prohibited content for review**

   ```bash
   buckia content moderate --team-id="team456" --sensitivity="high" --queue="content-review" --auto-notify-admins
   ```

8. **Mass update metadata for objects incorrectly categorized by the AI**
   ```bash
   buckia content update-metadata --team-id="team456" --filter="category:electronics" --correct-category="smartphones" --update-ai-model
   ```

## System Maintenance Tasks

10. **Perform storage optimization by moving infrequently accessed recordings to cold storage**

    ```bash
    buckia storage optimize --team-id="team456" --access-pattern="inactive-90d" --target-storage="cold" --remove-from-cdn --estimate-savings
    ```

11. **Generate monthly storage utilization reports broken down by team**

    ```bash
    buckia system stats --report="storage-utilization" --team-id="team456" --period="last-month" --format="pdf"
    ```

12. **Apply a security patch to all demo database files for a specific team**
    ```bash
    buckia demo update-security --team-id="team456" --patch-version="1.2.3" --all-versions --validate-after-update
    ```

## Data Investigation Tasks

13. **Track the sharing history of a specific recording across users within a team**

    ```bash
    buckia audit sharing --team-id="team456" --content-id="rec123" --include-views --timeline --visualize-graph
    ```

14. **Investigate sync failures for a specific user across devices**

    ```bash
    buckia diagnose sync --user-id="user123" --team-id="team456" --last-days=7 --include-device-logs --generate-report
    ```

15. **Analyze failed AI classification patterns to improve the recognition model for a specific team**

    ```bash
    buckia training analyze-failures --team-id="team456" --period="last-month" --min-confidence=0.8 --group-by="object-type" --generate-training-set
    ```

16. **Generate an access patterns report for a team's recordings to optimize CDN caching**
    ```bash
    buckia audit access --team-id="team456" --content-type="recordings" --period="last-week" --geo-distribution --peak-hours
    ```

## Advanced Admin Tasks

17. **Create a custom demo environment for a potential enterprise client**

    ```bash
    buckia demo create-custom --team-id="team456" --base-version="v2.5" --client-name="Acme Corp" --vertical="manufacturing" --recordings-count=50
    ```

18. **Split a team into two separate teams due to organizational changes**

    ```bash
    buckia team split --team-id="team123" --new-teams="engineering,marketing" --user-mapping="team_split.csv" --notify-users
    ```

19. **Apply GDPR right-to-be-forgotten request for a specific user**

    ```bash
    buckia privacy forget-user --user-id="user123" --team-id="team456" --compliance="gdpr" --preserve-aggregate-data --generate-certificate
    ```

20. **Migrate all storage for a specific team from one provider to another**
    ```bash
    buckia system migrate-storage --team-id="team456" --source-provider="s3" --target-provider="bunny" --parallel-transfers=20 --validate-integrity
    ```

## Updated `.buckia` Configuration to Support These Tasks

```yaml
# Base bucket configuration
buckia:
  version: 2.0 # Configuration schema version

# Team-based configuration (primary organization unit)
teams:
  TEAM456:
    name: "Enterprise Solutions"
    storage:
      primary_provider: "s3"
      bucket_name: "recordthing-team456"
      region: "us-west-2"
      cdn_domain: "cdn.team456.example.com"
      fallback_provider: "bunny"
      cold_storage:
        provider: "s3-glacier"
        retention_days: 730
    tiers:
      free:
        storage_quota_gb: 50
        user_limit: 100
        enabled_features: ["basic_recording", "ai_recognition"]
      premium:
        storage_quota_gb: 500
        user_limit: 50
        enabled_features: ["all"]
    demo:
      enabled: true
      version: "v2.5"
      custom_demos:
        - name: "manufacturing"
          description: "Demo for manufacturing clients"
          recording_count: 50
    ai_training:
      contribute_recordings: true
      opt_out_allowed: true
    compliance:
      gdpr_enabled: true
      ccpa_enabled: true
      retention_policy_days: 90
      audit_trail_enabled: true

# Admin permissions (role-based)
admins:
  ADMIN123:
    name: "Jane Smith"
    email: "jane@example.com"
    role: "team_admin"
    teams: ["TEAM456"]
    permissions:
      user_management: true
      content_management: true
      system_maintenance: true
      auditing: true
    notification:
      email: true
      slack: true
      webhook_url: "https://example.com/webhook"

# Operation rules
operations:
  user_migration:
    require_approval: false
    preserve_shares: true
    preserve_recordings: true
    backup_before_migration: true
  content_moderation:
    sensitivity_levels:
      low: 0.6
      medium: 0.8
      high: 0.95
    auto_notification: true
    review_queue: "content_team@example.com"
  storage_optimization:
    auto_optimize_days: 90
    cdn_removal_threshold_days: 60
    deduplication_similarity: 0.95
    compression_enabled: true
  diagnostics:
    sync_failure_threshold: 3
    performance_metrics_retention_days: 30
    error_logs_retention_days: 90
    generate_reports: true
```

These configurations and tasks properly respect the team-based architecture where team settings determine server locations and tier features, rather than applying changes across all tiers indiscriminately. The focus is on specific users and teams, with appropriate controls for managing the RecordThing ecosystem based on your feedback.
