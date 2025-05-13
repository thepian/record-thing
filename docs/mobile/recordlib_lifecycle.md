### Swift RecordLib Integration

The Swift RecordLib package is responsible for handling database interactions, content management, synchronization, and integration with the storage buckets. It serves as the interface between the UI layer and the data layer.

#### Database Interaction

RecordLib's database management includes:

- **Connection Management**:

  - Establishes and maintains Blackbird database connections
  - Handles connection pooling for concurrent operations
  - Implements automatic retry mechanisms for transient failures

- **Transaction Support**:

  - Provides methods for atomic operations using SQLite transactions
  - Supports nested transactions with proper commit/rollback semantics
  - Implements optimistic locking for conflict resolution

- **Schema Upgrades**:

  - Manages database schema versions across app updates
  - Handles migration scripts imported from the backend
  - Implements safe upgrade paths with backup/restore

- **Model Layer**:
  - Defines BlackbirdModel-conforming structs matching database schema
  - Implements type-safe query builders with parameter binding
  - Provides relationship mapping for nested object structures

#### Browser Cache Integration

RecordLib's cache management system controls:

- **Content Cache**:

  - Maintains a two-tier LRU (Least Recently Used) cache system:
    - Memory cache for rapid access to frequently used items
    - Disk cache for persistence across app launches
  - Enforces size limits based on device capabilities and user settings
  - Implements automatic pruning when space is limited

- **Image Optimizations**:

  - Downscales images for display based on device characteristics
  - Uses progressive loading for large media files
  - Implements prefetching based on user navigation patterns

- **Cache Invalidation**:
  - Tracks version metadata for cached content
  - Implements smart invalidation based on content dependencies
  - Supports selective purging of stale data while preserving fresh content

#### Storage Bucket Integration

RecordLib's integration with storage buckets includes:

- **Authentication**:

  - Manages access tokens securely in the keychain
  - Implements token refresh and rotation
  - Supports fallback mechanisms for compromised tokens

- **Endpoint Management**:

  - Dynamically determines CDN endpoints based on team configuration
  - Implements URL generation for content access
  - Handles domain changes and CDN migrations transparently

- **Transfer Management**:
  - Implements intelligent chunking for large file transfers
  - Supports pause/resume for interrupted operations
  - Provides bandwidth throttling based on network conditions

#### App Lifecycle Integration

RecordLib integrates with the app lifecycle to optimize operations:

- **Launch Sequence**:

  - Performs database integrity check on app launch
  - Initializes connection pools and caches
  - Prepares sync state based on previous app state

- **Background Processing**:

  - Completes pending operations when app enters background
  - Schedules background refresh tasks when supported
  - Uses background fetch for critical updates

- **Termination Handling**:

  - Ensures pending transactions are committed or rolled back
  - Performs emergency backup if necessary
  - Updates persistent state for next launch

- **State Restoration**:
  - Preserves user context across app restarts
  - Implements checkpoint system for long-running operations
  - Recovers from interrupted operations intelligently

#### Synchronization Framework

RecordLib's synchronization system includes:

- **Change Tracking**:

  - Maintains a journal of local database modifications
  - Assigns change sequence numbers for ordering
  - Tracks dependencies between related changes

- **Conflict Resolution**:

  - Implements merge strategies for conflicting changes
  - Preserves both versions when automatic merging isn't possible
  - Provides UI hooks for user-driven conflict resolution

- **Batch Processing**:

  - Groups related changes for efficient transmission
  - Implements transactional application of change batches
  - Supports rollback of partially applied batches

- **Status Monitoring**:
  - Tracks sync operations at granular level
  - Provides observers for sync events
  - Implements retry mechanisms with exponential backoff

#### Backup Management

RecordLib's backup system ensures data integrity:

- **Scheduled Backups**:

  - Performs automatic backups on significant data changes
  - Implements differential backups to minimize storage impact
  - Maintains a configurable retention policy

- **On-Demand Backups**:

  - Provides methods for user-triggered backups
  - Supports backup annotation for context
  - Implements verification of backup integrity

- **Restoration**:
  - Supports full and partial restoration
  - Implements point-in-time recovery when possible
  - Provides conflict resolution during restoration

#### Asset and Thing Management

RecordLib provides specialized handling for content:

- **Content Loading**:

  - Implements lazy loading patterns for efficient memory usage
  - Supports progressive rendering of large collections
  - Provides metadata access before full content loading

- **Search and Filtering**:

  - Optimizes queries for performance using SQLite indexes
  - Implements full-text search capabilities
  - Supports complex filtering with multiple criteria

- **Relationship Management**:
  - Handles parent-child relationships between items
  - Implements reference counting for shared assets
  - Provides cascading operations for related items

#### Request Processing

RecordLib's request handling system manages:

- **Request Lifecycle**:

  - Tracks request state from creation to completion
  - Implements timeout and expiration handling
  - Provides notification hooks for status changes

- **Prioritization**:

  - Supports priority levels for competing requests
  - Implements fair scheduling to prevent starvation
  - Allows urgency override for critical operations

- **Batching and Queueing**:
  - Groups compatible requests for efficient processing
  - Implements persistent queues for reliability
  - Supports request dependencies and ordering constraints

---

Buckia folder structure.

|- <user-id>
| | - backup.sqlite
| | - originals
| | - reworked
| | - inbound

The local file structure is managed by the Buckia library. The `user-id` folder is created when the user is created. This folder is used to store a local copy that can be sync'ed 1-to-1 with the user's folder in the Storage Bucket. The `backup.sqlite` file is a backup of the local SQLite database. It is used to restore the local database if needed. The `originals` folder holds the original recording files. The `reworked` folder holds the downscaled recordings for viewing. The `inbound` folder holds the incoming SQLite database diff files used to update the local database. This is used to send requests and shares between users.

The client App uses a local primary SQLite database(in App Support Folder) to store data and downscaled media thumbnails. New recordings are saved under `originals` and referenced in the database. When the App becomes inactive or goes to the background, the App calls the library to back up the database to the `backup.sqlite` in case changes have been made since the last backup. This will be done using APFS Copy-on-Write which is nearly instantanious. It should mean that there is no need to check if changes have been made since the last backup.

The local user folder can be configured to be stored under the App Support folder or the App Documents folder. If the folder isn't present, the other location is checked. If the folder is in the wrong location, it is moved to the correct location.

The `inbound` folder holds incremental changes to the local SQLite database. This is used to send requests and shares between users. These files are used to update the local database with changes from other users. The local DB has a table tracking past applied changes. The files are named using KSUIDs. This allows for quick sorting of files that have to be applied. The table definitions from the incoming DB file is used to adjust the local DB file. Additional tables are used to hold references to the changes.

Buckia folder syncing.

- List the filenames in `inbound` folder within the Storage Bucket. Download only IDs bigger than the last applied ID to the local `inbound` folder.
- Apply the changes to the local SQLite database. Drop applied files as needed to save space.
- Upload the `backup.sqlite` file to the Storage Bucket under the `user-id` folder.
- If enabled, upload new files in the `originals` folder to the Storage Bucket under the `user-id` folder.
- Upload new files in the `reworked` folder to the Storage Bucket under the `user-id` folder.

---

---

The Record Thing client-side component is a Swift/Kotlin library designed to manage data synchronization, authentication, and reference data for the Record Thing mobile application. The library facilitates synchronization between local SQLite databases with associated media recording files and cloud Storage Buckets. The system architecture emphasizes offline-first functionality with cloud backup and sharing capabilities rather than a traditional REST API approach.

The client settings are persisted beyond the uninstall of the App. User settings including the User ID is saved in the App Group Shared Data(`group.com.thepia.recordthing`). This means that other Thepia Apps can access the same settings. Passkeys and tokens are stored in the keychain and set up for iCloud sharing.

When the client App is first launched, it will check if the local database exists. If it does not, the App will create a new database based on:

1. Copying the existing database from the App Documents folder.
2. Copying the database from the Storage bucket folder if the user id is set in the App settings.
3. Downloading the demo database from the cloud storage bucket.
4. If the download fails, it will copy the demo database from the Assets folder in the App bundle.

It then creates a new User ID and creates a new Account record, changing the database owner. It will ensure guidelines compliance by,

- Loading indicator shown
- Handles network/Connection errors (retries)
- Privacy Policy: The App Description states "RecordThing is a free App for recording objects in the world for personal records and sharing with Thepia User Community. It will download a community showcase along with your personal recordings on the first install.
- Local Fallback database copied from Assets

The client App can be set up to run with a demo user. This can be done with a toggle in settings.
This will limit the ability to modify the database to protect the demo data.
Demo data can be updated by the user under settings. A button "Reset Demo" will be available to reset the demo data by downloading the original from the Demo Users Storage bucket folder.

When running with the demo user, no syncing is done with the cloud storage bucket.

The client App views of recordings are fetched from the storage bucket using CDN URLs. A web download cache directory is the App Support folder is used. This works the same with demo user and normal user.
