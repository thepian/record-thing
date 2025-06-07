# Database

## Database Management

The RecordThing app uses different database management strategies depending on the runtime environment to optimize both development workflow and production deployment.

### Production (Device) Database Management

When running on a physical device, the app follows a standard iOS app database pattern:

1. **Default Database Image**: A pre-populated SQLite database is included in the app's bundle assets
2. **Initial Setup**: On first launch, this default database is copied from the app bundle to the app's Documents directory
3. **Runtime Location**: The app operates on the database copy in the Documents directory
4. **Benefits**:
   - Ensures consistent initial state across all installations
   - Provides demo data and onboarding content out-of-the-box
   - Allows for database updates through app updates

### Development (Simulator) Database Management

When running in the iOS Simulator, the app can use an alternative database management approach for development convenience:

1. **Git-Tracked Database**: The runtime database can be configured to use the database file checked into Git
2. **Development Database Path**: Located at a known path that can be shared across the development team
3. **Ease of Development**:
   - Developers can work with a consistent, shared database state
   - Database changes can be version-controlled and shared
   - No need to repeatedly set up test data
   - Faster development iteration cycles

### Database Location Priority

The app's `AppDatasource` follows this priority order when determining which database to use:

1. **Debug Database** (highest priority): For specific debugging scenarios

   - Path: `~/Desktop/record-thing-debug.sqlite`
   - Used when this file exists on the developer's desktop
   - Allows for isolated debugging with custom database states

2. **Development Database**: Git-tracked database for simulator development

   - Path: `libs/record_thing/record-thing.sqlite` (relative to project root)
   - Checked into Git for team collaboration
   - Provides consistent development environment across team members

3. **Production Database** (fallback): Default behavior for device deployment
   - Location: App's Documents directory
   - Initialized from bundled database asset on first launch
   - Standard iOS app data management pattern

### Implementation Details

The database management is implemented in `RecordLib.AppDatasource` with the following key features:

- **Automatic Detection**: The app automatically detects which database to use based on file existence
- **Database Monitoring**: Comprehensive logging and error tracking via `DatabaseMonitor`
- **Environment Awareness**: Different behavior for simulator vs device environments
- **Blackbird Integration**: Uses Blackbird ORM for type-safe database operations
- **Migration Support**: Automatic schema migrations when database structure changes

This flexible approach allows developers to work efficiently while ensuring production deployments remain robust and consistent.

### ShareExtension Database Access

The ShareExtension has its own database access layer that extends the main app's database infrastructure:

- **ShareExtensionDatasource**: Extends `RecordLib.AppDatasource` for shared functionality
- **Database Sharing**: Uses the same database file as the main app through app group containers
- **Monitoring Integration**: Inherits database monitoring and error handling from RecordLib
- **Content Processing**: Handles shared content from other apps and saves to the database
- **Fallback Handling**: Creates "unprocessed shares" when immediate processing fails

The ShareExtension can save shared content directly to the database or create unprocessed entries for the main app to handle later, ensuring no shared content is lost even if the extension encounters issues.

## Freemium Tier Database Architecture

The RecordThing app implements a sophisticated freemium tier system that requires careful database management to support different user tiers, synchronization patterns, and storage strategies.

### Tier-Based Database Features

#### Free Tier Database Characteristics

- **Local Storage Only**: Primary SQLite database stored in App Support folder
- **Limited Synchronization**: No cloud database synchronization
- **Community Contribution**: All recordings uploaded to improve AI (with user consent)
- **Local Backup**: Database backed up to App Documents folder only
- **Demo Data Access**: Can access shared demo database for onboarding
- **Single Device**: Optimized for single-device usage

#### Premium Tier Database Characteristics

- **Cloud Synchronization**: Full bi-directional sync with Storage Bucket
- **Privacy Controls**: Option to mark recordings as private (not used for AI training)
- **Multi-Device Sync**: Database synchronization across iOS, iPadOS, and macOS
- **iCloud Integration**: Additional backup layer through iCloud
- **Advanced Sharing**: Full sharing capabilities with other users
- **Custom Workflows**: Database support for user-defined recording processes

### Database Storage Hierarchy

#### App Support Folder (Both Tiers)

```
/App Support/
├── record-thing.sqlite          # Primary database
├── web-cache/                   # CDN download cache
└── thumbnails/                  # Downscaled media for UI
```

#### App Documents Folder (Tier-Dependent)

```
/Documents/
├── record-thing-backup.sqlite   # Backup copy (both tiers)
├── recordings/                  # Original recording files
└── sync/                        # Premium: Synchronized files (iCloud accessible)
```

#### App Group Shared Data (Persistent)

```
group.com.thepia.recordthing/
├── user-settings.plist          # User ID, tier level, preferences
├── sync-state.json             # Premium: Synchronization state
└── demo-mode.flag              # Demo mode toggle
```

### Database Initialization Flow

The app follows a sophisticated initialization process to support different user scenarios:

1. **Check Existing Database**

   - Look for database in App Support folder
   - If found, validate schema and user ownership

2. **Database Creation Priority** (if no local database exists):

   ```
   Priority 1: App Documents folder backup
   Priority 2: Storage Bucket (if User ID exists in settings)
   Priority 3: Demo database from cloud Storage Bucket
   Priority 4: Fallback to bundled demo database in Assets
   ```

3. **User Account Setup**:

   - Generate new User ID (KSUID)
   - Create Account record in database
   - Update database ownership to new user
   - Store User ID in App Group Shared Data (persists beyond uninstall)

4. **Tier Configuration**:
   - Determine tier level from user settings or default to Free
   - Configure synchronization capabilities based on tier
   - Set up appropriate backup and sharing mechanisms

### Database Backup Strategies

#### APFS Copy-on-Write Backup (Both Tiers)

- **Trigger**: App becomes inactive or goes to background
- **Mechanism**: APFS Copy-on-Write for near-instantaneous copying
- **Performance**: Operations complete in under 100ms
- **Efficiency**: No need to check for changes due to CoW efficiency
- **Location**: App Documents folder (`record-thing-backup.sqlite`)

#### Cloud Backup (Premium Only)

- **Storage Bucket Sync**: Full database uploaded to user's cloud folder
- **iCloud Integration**: Additional backup layer for redundancy
- **Incremental Updates**: Only changed data synchronized
- **Conflict Resolution**: Last-write-wins with user notification

### Database Synchronization Architecture

#### Incremental SQLite Update System

The app implements a sophisticated differential synchronization system:

1. **Change Tracking**:

   - Local database maintains `applied_changes` table
   - Tracks KSUID of each applied change file
   - Prevents duplicate application of changes

2. **Change File Format**:

   - SQLite database files containing changes
   - Named with KSUIDs for chronological sorting
   - Stored in Storage Bucket `/inbound/` folder

3. **Synchronization Process**:

   ```
   1. List change files in /inbound/ folder
   2. Sort by KSUID (chronological order)
   3. Filter out already-applied changes
   4. Apply changes sequentially
   5. Update applied_changes tracking table
   ```

4. **Schema Migration Support**:
   - Table definitions from incoming files adjust local schema
   - Reference tables track structural changes
   - Automatic migration during sync process

### Demo Mode Database Management

#### Demo Mode Characteristics

- **Toggle Setting**: Controlled via App Group Shared Data
- **Database Protection**: Limited modification capabilities
- **No Cloud Sync**: Prevents demo data pollution
- **Reset Capability**: "Reset Demo" downloads fresh demo database

#### Demo Database Sources

1. **Primary**: Demo Users Storage Bucket folder
2. **Fallback**: Bundled demo database in App Assets
3. **Cache**: Local copy in App Support folder

### Sharing and Request System

#### Inbound Folder Processing

- **Location**: Storage Bucket `/inbound/` folder
- **File Format**: SQLite diff files with KSUID naming
- **Content Types**: User shares, recording requests, workflow updates
- **Processing**: Automatic application during sync cycles

#### Sharing Workflow

1. **Share Creation**: Generate SQLite diff file with changes
2. **File Naming**: Use KSUID for chronological ordering
3. **Upload**: Place in recipient's `/inbound/` folder
4. **Notification**: Trigger sync on recipient device
5. **Application**: Recipient applies changes during next sync

### Implementation Plan for Freemium Database Support

#### Phase 1: Core Database Infrastructure

1. **Tier Detection System**

   - Implement tier-aware AppDatasource
   - Add tier configuration to App Group Shared Data
   - Create tier-specific database initialization logic

2. **APFS Copy-on-Write Backup**

   - Implement background backup triggers
   - Add backup validation and recovery mechanisms
   - Performance monitoring for backup operations

3. **User ID Management**
   - KSUID generation and storage in App Group
   - Account creation and ownership transfer
   - Persistence across app reinstalls

#### Phase 2: Synchronization Infrastructure

1. **Change Tracking System**

   - Create `applied_changes` table schema
   - Implement KSUID-based change file naming
   - Build change detection and application logic

2. **Storage Bucket Integration**

   - Cloud storage API integration
   - Upload/download mechanisms for database files
   - Error handling and retry logic

3. **Incremental Sync Engine**
   - SQLite diff file generation
   - Schema migration during sync
   - Conflict resolution strategies

#### Phase 3: Premium Features

1. **Multi-Device Synchronization**

   - Cross-device change propagation
   - Device pairing and authentication
   - Real-time sync notifications

2. **iCloud Integration**

   - Documents folder iCloud sync
   - Keychain sharing across devices
   - Backup redundancy management

3. **Advanced Sharing**
   - User-to-user sharing workflows
   - Request processing system
   - Privacy controls for shared content

#### Phase 4: Demo Mode and Compliance

1. **Demo Mode Implementation**

   - Database protection mechanisms
   - Demo data reset functionality
   - Sync prevention in demo mode

2. **Compliance Features**
   - Loading indicators for all operations
   - Network error handling and retries
   - Privacy policy integration

### Technical Requirements for Database Implementation

#### Performance Requirements

- **Database Operations**: Complete within 100ms on target devices
- **APFS Backup**: Complete in under 100ms using Copy-on-Write
- **Sync Operations**: Background processing without UI impact
- **App Launch**: Under 2 seconds including database initialization

#### Reliability Requirements

- **Zero Data Loss**: During synchronization or backup operations
- **Network Resilience**: Graceful handling of interruptions
- **Automatic Recovery**: From corrupted databases or failed syncs
- **Change Tracking**: Prevent duplicate application of changes

#### Security Requirements

- **Data Encryption**: For sensitive recordings (Premium tier)
- **Secure Transmission**: HTTPS for all cloud operations
- **Privacy Controls**: User consent for AI training contributions
- **Access Control**: Tier-based feature restrictions

#### Compatibility Requirements

- **iOS/iPadOS**: 15.0+ with APFS support
- **macOS**: 12.0+ for cross-device sync
- **Storage**: Efficient operation with limited device storage
- **Backward Compatibility**: Schema migration support

## Database Schema

The database contains the following tables:

|---------------|------------------------------|
| Table | Description |
|===============|==============================|
| Universe | Each is defined by a downloading a ZIP file that contains a description and assets. It describes a complete set of functionality for the App. |
| Things | Things belonging to the user. It has been identified by the user by scanning and recording. |
| Evidence | Evidence is a set of records that are evidence of the thing. |
| Requests | Requests are a set of Evidence Gathering actions that the user is asked to complete. |
| Accounts | Accounts are the users of the RecordThing App. RecordThing App has a single account. |
| Owners | Owners are the owners of the things. |
| ProductType | Global product types with common identifiers and iconic images. |
| DocumentType | Global document types with common identifiers and iconic images. |
|===============|==============================|

The database is a SQLite database, created by running(in order):

- `libs/record_thing/db/account.sql`
- `libs/record_thing/db/evidence.sql`
- `libs/record_thing/db/assets.sql`
- `libs/record_thing/db/auth.sql`
- `libs/record_thing/db/product.sql`
- `libs/record_thing/db/agreements.sql`
- `libs/record_thing/db/translations.sql`

One file is skipped for now as it breaks Blackbird support.

- `libs/record_thing/db/vector.sql`

## Account (accounts)

The RecordThing App will be tied to a single account at a time. Servers can work across accounts. The owners table points to the active account on the Phone.

### Team

The team is defines by the account information

- Team name
- Team DB URL
- Team Primary Bucket URL
- Team Fallback Bucket URL
- Team invite token
- Team access token

The user can backup the local SQLite DB to the Team Buckets.
The user can reset the local SQLite DB to a state saved/published on the Team Buckets.
The user can sync certain content in the local SQLite DB with the Team Postgres DB Server.
The user can sync recording files with the Team Buckets(per user home folder)

The initial database contains a demo user account and owner with data for onboarding and demo purposes. As part of the onboarding a new user is created within the free tier.

Two teams are defined in the initial database:

1. Free tier team
2. Premium tier team

The team_id for these teams are generated, but must be maintained the same across all devices.

A demo user is created, belonging to the free tier team, with generated Sample recordings and Belongings.

## Feed

The Feed is a table that contains the user's feed. It is used to show the main feed for a user in the app. A feed entry can be a Thing, a Request, an Agreement, an Event, a single piece of evidence, or a Chat.

## Universe

Each universe is defined by a downloading a ZIP file that contains a description and assets. It describes a complete set of functionality for the App.

Universes are remote sources of MLPrograms, Processes and Configuration. They are identified by a URL and points to a ZIP file. It has fields for URL, name, description, isDownloaded, enabledMenus, enabledFeatures, flags.

The URL field is unique per record.
The Primary Key is a locally generated integer.

## Products

Products in the world are identified by a ProductType and a Brand. The cannonical descriptions is constructed by a node in the network. Descriptions are compared by text embedding to merge duplicate products. A central product database is maintained and replicated among users based on their reference from things.

A thing might be constructed and be tied to a product later.
The product might be constructed based on the first piece of evidence after which the thing is created.
Products have a canonical URL for the official product website, support website, Canonical Wikipedia page, Wikidata page.

## Brands

Brands are the manufacturers of products. They are identified by a name and an iconic image.
The website of the brand is a URL with a DNS domain that has been verified to belong to the correct company.
The record can hold contact information, support information, legal status, etc.
Brands can be grouped under a common name by a parent_brand_id.
The brand description is a text field that can be used to store information about the brand. The description is used to merge duplicate brand records.
Brands have canonical URLs for official brand websites, support website, Canonical Wikipedia page, Wikidata page, isni code.

## Things

Things belonging to the user. It has been identified by the user by scanning and recording. They tend to be luxury goods or high status belongings that the user wants to keep track of for insurance purposes.
Multiple records can be made for the same thing.
The owner of the thing is identified by the account_id.

The Things Primary Key is the account_id plus a locally generated text id(KSUID)

## Evidence

Evidence is a set of records that are evidence of the thing or event.
Evidence will often relate to a thing.
Evidence can relate to a request.
Evidence can relate to an event.

## Requests

Requests are a set of Evidence Gathering actions that the user is asked to complete.

A request can be sent by another user or registered 3rd party. It can be sent as a card or link in a message or e-mail.
The link points to a custom state in the RecordThing App. The RecordThing App translates this to a Universe like URL.
It works like a Universe with refinements. The outcome of the request is a set of Evidence, which is wrapped up and sent as an e-mail or HTTP POST.

The URL field is unique per record.
The Requests Primary Key is a locally generated integer.

## Agreements

Agreements are rights and obligations the user is involved in. It can be insurance, lease, purchase, etc. They will be valid for a period of time, and have renewal dates.

## Accounts, Owners, Passkey_credentials

Accounts are the users of the RecordThing App. The database used by the RecordThing App has a single account.

The Accounts Primary Key(id) is a locally generated text KSUID

The Owners Primary Key(account_id) is a locally generated text KSUID

The Passkey_credentials Primary Key is a locally generated text KSUID

## ProductType

Global product types with common identifiers and iconic images.
ProductTypes are categories of objects identified by various naming conventions. They are tied to individual images.

## DocumentType

Global document types with common identifiers and iconic images.
DocumentTypes are categories of documents identified by various naming conventions. They are tied to individual images.

## Translations

I would like to extend the translations in a SwiftUI application by loading them from a SQLite table. The database(record-thing.sqlite) is stored in the App Documents folder. If no database is found a default image is copied from the App Resources. How do I do it so the application loads fast and translations are applied to all translated texts in the application. I want to use the text localisation built into SwiftUI labels. Use Blackbird to access the SQLite Database.

## Image Asset

`libs/record_thing/db/assets.sql` contains the image assets for the application. Small versions of the images are stored in a SQLite database. The images are stored in a table with a unique path and a binary iconic_png blob. The images are loaded from the database and displayed in the application. The original image is saved in the Apps documents directory and in the associated remote Bucket.
`alt_url` and `original_url` are used to manage where to download originals missing from the local cache, and where to find the original locally. Columns sha1/md5 save hashes for the original.

## Collecting brands

The brands are collected from Wikidata. The script is in `libs/record_thing/db/collect_brands.py`.

Added multiple entity types:
Q431289 (brand)
Q167270 (trademark)
Q4830453 (business with industry)
Q2088357 (retail chain) 2. Reduced statement count filter from 10 to 5
Used UNION to combine different types
Maintained all existing property fetching
This should capture:
Traditional brands
Registered trademarks
Notable businesses
Retail chains
More niche or regional brands

## Generating examples

Add brand lists in addition to types for brand names that produce the types of products

Add 10 showcase product examples to each group with name, product description, designed year, product shot description (pose, background, subject, style)

Add 10 showcase product examples to each group with name, product description, designed year, product shot description (pose, background, subject, style)

I'll help add showcase examples for each category. Let's start with watches and cameras as examples:
documentation

Add showcase product examples to watches with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to cameras with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to musical instruments with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to art with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to collectibles with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to fine jewelry with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to vehicles with name, product description, designed year, product shot description (pose, background, subject, style)

TODO the rest...

### Example of adding fields to a table

```sql
PRAGMA foreign_keys = OFF;

BEGIN;

CREATE TABLE _teams_new (
    team_id TEXT PRIMARY KEY
  , name TEXT
  , region TEXT
  , tier TEXT
  , is_demo BOOLEAN DEFAULT(0)
  , is_active BOOLEAN DEFAULT(1)
  , storage_domain TEXT
  , storage_bucket_name TEXT
  , storage_bucket_region TEXT
  , fallback_domain TEXT
  , fallback_bucket_name TEXT
  , fallback_bucket_region TEXT
  , created_at FLOAT DEFAULT(0.0)
  , updated_at FLOAT DEFAULT(0.0)
);

INSERT INTO _teams_new (
    team_id
  , name
  , region
  , tier
  , is_demo
  , is_active
  , storage_domain
  , storage_bucket_name
  , storage_bucket_region
  , created_at
  , updated_at
)
SELECT
    team_id
  , name
  , region
  , tier
  , is_demo
  , is_active
  , storage_domain
  , storage_bucket_name
  , storage_bucket_region
  , created_at
  , updated_at
FROM teams;

DROP TABLE teams;

PRAGMA legacy_alter_table = ON;

ALTER TABLE _teams_new RENAME TO teams;

PRAGMA legacy_alter_table = OFF;

COMMIT;

PRAGMA foreign_keys = ON;

```
