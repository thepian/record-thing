# Product Requirements Document (PRD)

# Record Thing Server-Side & Data Handling

## 1. Executive Summary

The Record Thing server-side component is a Python library designed to manage data synchronization, authentication, and reference data for the Record Thing mobile application. The library facilitates synchronization between local SQLite databases with associated media recording files and cloud Storage Buckets, manages user authentication via WorkOS, and provides tools for setting up and maintaining reference and demo data. The system architecture emphasizes offline-first functionality with cloud backup and sharing capabilities rather than a traditional REST API approach.

## 2. System Overview

### 2.1 Core Components

1. **Buckia Synchronization Engine**: Manages bidirectional synchronization between local SQLite databases and cloud Storage Buckets
2. **Authentication Module**: Integrates with WorkOS for passkey-based authentication and token management
3. **Database Management**: Handles SQLite database schema, migrations, and consistency
4. **Reference Data Manager**: Sets up and maintains demo and reference data across all storage buckets
5. **Team & User Management**: Manages user accounts, teams, and associated permissions

### 2.2 Architectural Approach

The Record Thing system follows a "storage bucket as server" architecture where:

- Primary data storage occurs locally on user devices in SQLite format
- Cloud synchronization uses Storage Buckets rather than a traditional API
- Full database files are exchanged between app, server, and back-office
- Authentication grants appropriate access tokens to buckets
- Machine learning and computer vision processing occurs primarily on-device

## 3. User Roles & Permissions

### 3.1 Role Definitions

1. **Free Tier Users**

   - Initially granted read-only access to bucket
   - Access to demo team content
   - Limited storage allocation in common storage bucket

2. **Premium Users**

   - Read-write access to personal user folder
   - Access to premium team content
   - Expanded storage allocation in premium storage bucket

3. **Enterprise Users**

   - Read-write access to personal user folder
   - Access to enterprise team content
   - Dedicated storage in enterprise storage bucket

4. **Back-Office Users**
   - Administrative read-write tokens
   - Access to manage reference data
   - Ability to assist users with troubleshooting

### 3.2 Authentication Flows

1. **User Registration**

   - Programmatic creation of user IDs without requiring personal information
   - Passkey (biometric) registration for device authentication
   - Assignment to appropriate team (default: free tier)
   - Generation of appropriate access tokens for bucket access

2. **User Authentication**
   - Passkey-based authentication using WorkOS
   - Token acquisition for Storage Bucket access
   - Token refresh and management

## 4. Data Architecture

### 4.1 Database Schema

The SQLite schema includes the following key entities (based on document analysis):

1. **Accounts**: Users of the Record Thing App

   - Primary Key: account_id (KSUID)
   - Core fields: name, username, email, sms, region

2. **Owners**: The account ID used to create new data on this node

   - Primary Key: account_id (KSUID)

3. **Teams**: (To be implemented) Groups of users with shared access

   - Will define which Storage Bucket the app communicates with

4. **Universe**: Defines a complete set of functionality for the App

   - Supports white-labeling, ML model selection, and user prompting
   - Fields: URL, name, description, enabledMenus, enabledFeatures, flags

5. **Things**: Physical items belonging to the user

   - Primary Key: account_id + id (KSUID)
   - Core fields: UPC, ASIN, brand, model, category, evidence_type

6. **Evidence**: Records that provide evidence of a thing

   - Links to Things via thing_account_id and thing_id
   - Contains evidence data and links to local files

7. **Requests**: Evidence gathering actions that users complete

   - Can be sent by other users or registered third parties
   - Defines delivery methods for completed requests

8. **Products, Brands, Companies**: Reference data for item identification
   - Extensive schema for categorizing and identifying commercial products
   - Support for Wikidata IDs and standardized categorization

### 4.2 Storage Bucket Structure

1. **Common Storage Bucket**

   - `<demo-team-id>/`: Demo content folder
   - `<user-id>/`: Common user folders

2. **Premium Storage Bucket**

   - `<demo-team-id>/`: Demo content folder
   - `<user-id>/`: Premium user folders

3. **Enterprise Storage Bucket**
   - `<demo-team-id>/`: Demo content folder
   - `<user-id>/`: Enterprise user folders

### 4.3 User Folder Structure

Each user folder will contain:

- SQLite database backup
- Inbound additions for the database
- Assets subfolder with images and clips
- ML-related data for that user

## 5. Core Functionality

### 5.1 Buckia Synchronization

The library will use Buckia to provide:

1. **Client directed Bi-directional Synchronization**

   - Local client integrates a stream of server originated changes
   - Local SQLite DB is the source of truth
   - The local DB is uploaded to the Storage Bucket as a backup
   - New clients can be set up by copying from the Storage Bucket
   - New recordings are uploaded to the Storage Bucket
   - Clients can use the Storage Bucket to share recordings with other users

2. **Provider Support**

   - Buckia is used to communicate with the Storage Bucket and sync
   - Initial support for Bunny.net and Backblaze B2
   - Extensible design for adding S3 support for Cubbit and Linode
   - Common interface across providers

3. **Sync Configuration**

   - Path mapping between local and remote systems
   - Directory structure preservation
   - Include/exclude patterns for file selection

4. **Authentication & Connection**
   - Support for API keys, access tokens
   - Connection pooling for performance
   - Automatic retries and rate limiting

### 5.2 Database Management

1. **Schema Creation and Migrations**

   - Initialize database tables in correct dependency order
   - Manage migrations for schema changes
   - Ensure cross-platform compatibility (iOS, macOS, Python)

2. **Reference Data Management**

   - Populate product types, document types from standard sources
   - Import brand and company data from Wikidata
   - Manage translations for UI elements

3. **Demo Data Setup**
   - Create realistic sample data for demo users
   - Set up example "things" with associated evidence
   - Configure universe settings for demonstration

### 5.3 User & Team Management

1. **User Creation**

   - Generate KSUID for new users
   - Associate with appropriate team
   - Set up initial database structure

2. **Team Setup**

   - Configure team settings
   - Associate with appropriate Storage Bucket
   - Set up team-specific reference data

3. **Authentication Integration**
   - Integrate with WorkOS for passkey authentication
   - Manage access tokens for Storage Buckets
   - Handle permission levels based on user tier

### 5.4 ML Model Management

1. **Model Packaging**

   - Package vision models as zip bundles (mlprogram for iOS)
   - Store in team folder for distribution
   - Version management for models

2. **Reference Data Collection**
   - Collect and organize product reference data
   - Process user submissions for new product information
   - Integrate with external sources (Wikidata, etc.)

## 6. Technical Implementation

### 6.1 Core Technologies

1. **Primary Language**: Python with type hints
2. **Database**: SQLite
3. **Storage**: Bunny.net (initial), S3 and Linode (planned)
4. **Authentication**: WorkOS
5. **Data Formats**: SQLite, JSON, ZIP (for ML models)

### 6.2 Project Structure

```
buckia/                  # Synchronization package
├── __init__.py
├── client.py            # Main client interface
├── config.py            # Configuration handling
├── cli.py               # Command-line interface
└── sync/
    ├── __init__.py
    ├── base.py          # Base synchronization classes
    ├── factory.py       # Backend factory
    ├── bunny.py         # Bunny.net implementation
    ├── s3.py            # S3 implementation
    └── linode.py        # Linode implementation

record_thing/
├── db/                  # Database management
│   ├── schema.py        # Schema definition and migrations
│   ├── account.sql      # SQL definitions for accounts
│   ├── evidence.sql     # SQL definitions for evidence
│   └── ...              # Other SQL schema files
├── sync/                # Sync management
│   ├── bucket.py        # Storage bucket operations
│   └── local.py         # Local file operations
├── auth/                # Authentication
│   ├── workos.py        # WorkOS integration
│   └── tokens.py        # Token management
└── management/          # Management commands
    ├── setup_demo.py    # Demo data setup
    ├── import_brands.py # Import brand data
    └── ...              # Other management commands
```

### 6.3 Key Interfaces

1. **Buckia Client Interface**

```python
from buckia import BuckiaClient, BucketConfig

config = BucketConfig(
    provider="bunny",
    bucket_name="record-thing-premium",
    credentials={...}
)

client = BuckiaClient(config)
result = client.sync(
    local_path="/path/to/user/data",
    sync_paths=["images/", "database/"],
    delete_orphaned=True
)
```

2. **Database Management Interface**

```python
from record_thing.db import schema

# Initialize database
conn = sqlite3.connect("record-thing.sqlite")
schema.init_db_tables(conn)

# Ensure owner account
schema.ensure_owner_account(conn, account_id="2siiVeL3SRmN4zsoVI1FjBlizix")
```

3. **WorkOS Authentication Interface**

```python
from record_thing.auth.workos import WorkOSAuth

auth = WorkOSAuth(api_key="...")
passkey_credential = auth.register_passkey(
    account_id="2siiVeL3SRmN4zsoVI1FjBlizix",
    credential_data=credential_data
)

# Authenticate user
auth_result = auth.authenticate_passkey(credential_id, authentication_data)
if auth_result.is_valid:
    # Get storage bucket tokens
    tokens = auth.get_storage_tokens(auth_result.account_id)
```

## 7. Implementation Phases

### 7.1 Phase 1: Core Infrastructure

1. **Buckia Integration**

   - Implement Bunny.net provider
   - Develop core synchronization logic
   - Create CLI interface

2. **Database Schema**

   - Finalize initial schema
   - Implement schema migration system
   - Create database initialization tools

3. **Basic Authentication**
   - Implement WorkOS integration
   - Set up token management
   - Create user creation flow

**Timeline**: 4-6 weeks

### 7.2 Phase 2: Reference Data & Management

1. **Product & Brand Data**

   - Import data from Wikidata
   - Set up reference data models
   - Implement categorization system

2. **Demo Data**

   - Create realistic demo data sets
   - Implement demo setup tools
   - Test with mobile applications

3. **Team Management**
   - Implement team structure
   - Set up bucket associations
   - Configure permission levels

**Timeline**: 4-6 weeks

### 7.3 Phase 3: Extended Features

1. **Additional Storage Providers**

   - Implement S3 provider
   - Implement Linode provider
   - Test provider interoperability

2. **Universe System**

   - Develop universe configuration
   - Implement ML model packaging
   - Create universe deployment tools

3. **Advanced Synchronization**
   - Implement delta sync for large files
   - Add encryption for sensitive data
   - Optimize performance for large datasets

**Timeline**: 6-8 weeks

## 8. Testing & Validation

### 8.1 Test Categories

1. **Unit Tests**

   - Test core functionality components
   - Verify database operations
   - Validate authentication flows

2. **Integration Tests**

   - Test synchronization with actual storage buckets
   - Verify end-to-end authentication
   - Test database migrations

3. **Performance Tests**
   - Measure synchronization performance with large datasets
   - Test concurrent operations
   - Evaluate resource utilization

### 8.2 Testing Tools

1. **Python Testing**

   - pytest for unit and integration tests
   - pytest-cov for coverage reports
   - mock for simulating external dependencies

2. **Database Testing**

   - In-memory SQLite for unit tests
   - Test fixtures for database scenarios
   - Migration testing with schema versions

3. **Synchronization Testing**
   - Test buckets for different providers
   - Simulated network conditions
   - Time-based performance metrics

## 9. Deployment & Operations

### 9.1 Package Distribution

1. **PyPI Publishing**

   - Package core library for pip installation
   - Set up versioning and release process
   - Create documentation for installation

2. **CLI Tool**
   - Bundle CLI tools for system installation
   - Create user documentation
   - Set up update mechanisms

### 9.2 Monitoring & Maintenance

1. **Logging**

   - Implement comprehensive logging
   - Configure log levels for different environments
   - Create log analysis tools

2. **Error Handling**

   - Develop robust error handling
   - Create retry mechanisms for transient failures
   - Implement self-healing for common issues

3. **Updates**
   - Schema migration for database updates
   - Backward compatibility for API changes
   - Gradual rollout of new features

## 10. Future Considerations

1. **PostgreSQL Integration**

   - Plan for potential PostgreSQL backend
   - Design schema compatibility layer
   - Consider migration strategies

2. **Advanced ML Capabilities**

   - Server-side ML processing for complex tasks
   - Federated learning from user submissions
   - Improved product recognition

3. **Extended API**

   - REST API for additional integration options
   - WebSocket for real-time updates
   - GraphQL for flexible querying

4. **Scalability**
   - Horizontal scaling for large user bases
   - Sharding strategies for data distribution
   - Performance optimization for enterprise users

## 11. Glossary

- **KSUID**: K-Sortable Unique Identifier - A globally unique identifier with time ordering
- **Storage Bucket**: Cloud storage container (Bunny.net, S3, etc.)
- **Universe**: Configuration set defining app functionality, ML models, and branding
- **WorkOS**: Authentication provider supporting passkeys and other login methods
- **Thing**: Physical item recorded by a user in the Record Thing app
- **Evidence**: Supporting documentation or media for a Thing (receipts, photos, etc.)
- **Team**: Group of users with shared settings and Storage Bucket access
