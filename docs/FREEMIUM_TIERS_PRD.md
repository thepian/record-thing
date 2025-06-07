# Product Requirements Document: Record Thing Client-Side Component (Revised)

## 1. Overview

### 1.1 Product Definition

Record Thing is a comprehensive solution for recording, recognizing, and organizing physical items using computer vision and machine learning. The client-side component is a Swift library (with future Kotlin support) that manages data synchronization, authentication, and reference data for the Record Thing mobile application.

### 1.2 Purpose

This client-side component enables offline-first functionality with cloud backup and sharing capabilities, facilitating the management of local SQLite databases with associated media recording files and their synchronization with cloud Storage Buckets.

### 1.3 Vision

To provide a robust, efficient framework for recording, organizing, and sharing physical item data across iOS, iPadOS, and macOS (with future Android support), with seamless synchronization and backup capabilities that respect user privacy and tier-based feature access.

## 2. Target Audience

### 2.1 Primary Users

- **Internal Development Team at Thepia**: The direct consumers of the client-side library
- **End Users of Record Thing App**:
  - Corporate employees using predefined recording processes
  - Individual users cataloging personal items
  - Professional users managing business assets

### 2.2 User Personas

#### Corporate User (Premium)

- Records company assets according to predefined workflows
- Needs secure, private storage of sensitive company information
- Requires cross-device synchronization between mobile and desktop apps
- Creates custom workflows for specialized recording processes

#### Individual User (Free Tier)

- Records personal items for insurance or organizational purposes
- Willing to contribute recordings to improve the AI system
- Primarily uses a single iOS device
- Works with predefined recording workflows

#### Professional User (Premium)

- Records client or business-related items
- Requires privacy controls and data ownership
- Needs seamless synchronization between field (mobile) and office (desktop)
- Benefits from custom workflows and advanced organization

## 3. Tier Structure

### 3.1 Free Tier Features

- Basic recording and object recognition capabilities
- Local SQLite database storage in App Support folder
- Access to predefined recording workflows
- Recording uploads to common server for AI improvement
- Recordings backed up locally only
- Limited sharing functionality

### 3.2 Premium Tier Features

- Advanced recording and recognition capabilities
- Local SQLite database storage with cloud synchronization
- Storage Bucket backup of all recordings and database
- iCloud backup integration for additional data security
- Ability to mark recordings as private (not used for AI training)
- Full sharing capabilities
- Custom workflow creation
- Cross-device synchronization (iOS, iPadOS, macOS)

## 4. Technical Architecture

### 4.1 Data Storage Model

#### Local Storage Hierarchy

- **App Support Folder**:
  - Primary SQLite database (for both tiers)
  - Web download cache for CDN URLs
  - Downscaled media files for viewing
- **App Documents Folder**:

  - New recordings (original files)
  - Database backup copy (when app is backgrounded)
  - Synchronized files for Premium tier users (iCloud accessible)

- **App Group Shared Data**:

  - User settings including User ID
  - Shared across Thepia apps (`group.com.thepia.recordthing`)
  - **Persistence**: Settings persist beyond app uninstallation, enabling consistent user experience across reinstalls

- **Keychain**:
  - Passkeys and tokens
  - Configured for iCloud sharing

#### Cloud Storage Structure

- **Storage Bucket Organization**:
  - `/recordings/` - Original recording files
  - `/images/` - Downscaled images for viewing
  - `/inbound/` - Incoming SQLite database diff files for processing user requests and shares
- **iCloud Integration** (Premium):
  - Automatic synchronization of App Documents Folder
  - Additional backup layer for Premium users

### 4.2 Synchronization Mechanism

#### Database Initialization Flow

1. Check for existing local database
2. If not present, create new database based on priority:
   - Copy from App Documents folder
   - Copy from Storage bucket (if user ID exists)
   - Download demo database from cloud
   - Fall back to Assets folder copy in App bundle
3. After database creation:
   - Generate new User ID
   - Create new Account record
   - Change database owner to the new user
4. Display appropriate loading indicators during this process
5. Implement retry mechanisms for network/connection errors

#### Database Backup Process

- Triggered when app becomes inactive or goes to background
- Can be triggered manually in the iCloud Debug view
- Uses APFS Copy-on-Write for near-instantaneous copying
- No need to check for changes due to the efficiency of Copy-on-Write
- Ensures data safety with minimal performance impact

#### Cloud Synchronization (Premium)

- Bi-directional sync between local files and Storage Bucket
- Selective synchronization options:
  - Auto-sync all recordings
  - Selective sync when sharing with other users
- Incremental update system using SQLite diff files:
  - SQLite database file to hold changes
  - Table definitions from incoming DB used to adjust local DB
  - Additional tables track references to changes
  - Change tracking table to prevent duplicate applications
  - Files named with KSUIDs for easy chronological sorting and application

#### Demo Mode

- Toggle in settings to run with demo user
- Limited database modification capabilities to protect demo data
- "Reset Demo" button to restore original demo data by downloading from Demo Users Storage bucket folder
- No cloud synchronization when in demo mode

### 4.3 Media File Management

#### Media Storage

- Original recordings stored in App Documents Folder
- Downscaled versions generated for UI display
- References maintained in primary SQLite database

#### Media Access

- Recordings fetched from storage bucket using CDN URLs
- Web download cache maintained in App Support folder
- Consistent experience for both demo and normal users

## 5. Core Features and Functionality

### 5.1 Database Management

#### Local Database Operations

- Create, read, update, delete operations for local SQLite database
- Schema migration support for app updates
- Efficient query optimizations for mobile performance
- Background thread operations to prevent UI blocking

#### Database Backup

- **Free Tier**: Local backup to App Documents folder only
- **Premium Tier**: Local backup plus Storage Bucket synchronization
- Differential backup to minimize storage and bandwidth usage
- Recovery mechanisms for corrupted databases

#### Database Synchronization

- Incremental SQLite update implementation:
  - Changes stored in separate SQLite database files
  - Table definitions from incoming files adjust local database structure
  - Reference tables track applied changes
  - KSUID-based file naming for chronological sorting
  - Local database maintains tracking table of applied changes

#### Disaster Recovery

- **Free Tier**: Recovery from local backup
- **Premium Tier**: Recovery from local backup, Storage Bucket, or iCloud
- "Last known good" state tracking for reliable recovery

### 5.2 Media File Management

#### Recording Storage

- Efficient storage of original recordings in appropriate formats
- Automatic generation of downscaled versions for UI display
- Metadata extraction and storage
- Background processing of new recordings

#### File Synchronization

- **Free Tier**: Basic synchronization of required files
- **Premium Tier**: Complete synchronization across all devices
- Bandwidth-efficient transfer with resume capability
- Conflict resolution for simultaneous edits
- Selective synchronization options based on user preference

#### Caching Strategy

- Smart caching of frequently accessed recordings
- CDN URL fetching with local web download cache
- Cache invalidation based on update patterns
- Memory-efficient thumbnail management

### 5.3 Authentication and Security

#### User Identity Management

- Persistent User ID storage in App Group Shared Data
- Account creation and management
- Demo user mode with appropriate restrictions
- Settings persistence beyond app uninstallation

#### Security Measures

- Keychain integration for secure credential storage
- Optional encryption for sensitive recordings (Premium)
- Secure transmission protocols for cloud synchronization
- Privacy controls for user-contributed data

#### iCloud Integration (Premium)

- Keychain sharing across user's devices
- Document synchronization via iCloud
- Backup redundancy using both Storage Bucket and iCloud

### 5.4 User Sharing and Requests

#### Sharing Implementation

- Share recordings with other users through the `inbound` folder
- SQLite diff files facilitate data exchange between users
- Control over shared recording permissions
- Notification of incoming shared content

#### Request Processing

- Receive and process recording requests from other users
- Structured workflow for responding to requests
- Automated synchronization of request-related content

### 5.5 Device Pairing (Premium)

#### iOS/macOS Pairing

- Protocol for pairing iOS/iPadOS devices with macOS app
- Real-time decision-making between paired devices
- Secure communication channel between paired devices
- Synchronization of actions and updates

#### Multi-device Experience

- Consistent data representation across devices
- Handoff capabilities for in-progress recordings
- Device-appropriate UI adaptations while maintaining workflow continuity

### 5.6 AI and Recognition Services

#### On-device Recognition

- Local model for previous object recognition
- Efficient storage of recognition data
- Model update mechanism

#### Cloud AI Integration

- **Free Tier**: Uploads to improve vision AI with all recordings
- **Premium Tier**: Selective uploads with privacy controls
- Feedback loop for recognition improvement

## 6. Technical Requirements

### 6.1 Performance Requirements

- Database operations complete within 100ms on target devices
- Synchronization operations run in background without impact on UI performance
- Camera and recognition features operate at minimum 15 FPS
- App launch time under 2 seconds, including database initialization
- APFS Copy-on-Write operations to complete in under 100ms

### 6.2 Reliability Requirements

- Zero data loss during synchronization or backup operations
- Graceful handling of network interruptions during cloud operations
- Automatic retry mechanisms with exponential backoff
- Detailed error logging for troubleshooting
- Loading indicators for all network operations with appropriate timeout handling

### 6.3 Compliance Requirements

- Display loading indicators during lengthy operations
- Handle network/connection errors with appropriate retries
- Include required privacy policy statements in app description
- Maintain local fallback mechanisms for all cloud-dependent features
- Clear user consent flows for data sharing and AI training

### 6.4 Compatibility Requirements

- iOS 15.0+ / iPadOS 15.0+
- macOS 12.0+
- Future: Android 9.0+
- Support for iPhone, iPad, and Mac device families
- Efficient operation on devices up to 3 generations old

### 6.5 Security Requirements

- HTTPS for all network communications
- Data encryption for sensitive information
- Secure authentication mechanisms
- Compliance with Apple's App Transport Security
- Privacy-preserving data handling
- Secure deletion capabilities for sensitive data

## 7. API Design

### 7.1 Core API Classes

#### RecordThingClient

- Main entry point for the library
- Configuration and initialization
- Tier management and feature access

#### DatabaseManager

- CRUD operations for the SQLite database
- Schema migration and management
- Query optimization
- APFS Copy-on-Write backup implementation
- Change tracking and differential sync

#### SynchronizationManager

- Cloud storage bucket integration
- Differential sync mechanisms
- Conflict resolution
- Selective synchronization options
- KSUID-based file sorting

#### MediaManager

- Recording file handling
- Thumbnail and preview generation
- Efficient media storage
- CDN URL management and caching

#### AuthenticationManager

- User identity handling
- Secure credential storage
- Demo mode management
- Settings persistence management

#### SharingManager

- User sharing implementation
- Request processing
- Inbound folder management
- Differential file handling

#### DevicePairingManager (Premium)

- Cross-device communication
- Real-time data exchange
- Pairing protocol implementation

### 7.2 Sample API Usage

```swift
// Initialize the client with configuration
let config = RecordThingConfig(
    appGroup: "group.com.thepia.recordthing",
    tierLevel: .premium,
    syncEnabled: true,
    selectiveSyncEnabled: true
)
let client = RecordThingClient(config: config)

// Database operations
let dbManager = client.databaseManager
let things = try await dbManager.fetchThings(category: "Electronics")

// Media operations
let mediaManager = client.mediaManager
try await mediaManager.storeRecording(
    data: recordingData,
    metadata: metadata,
    generatePreviews: true
)

// Synchronization with selective options
let syncManager = client.synchronizationManager
try await syncManager.syncDatabase()
try await syncManager.syncMediaFiles(selective: true, items: selectedItems)

// Sharing implementation
let sharingManager = client.sharingManager
try await sharingManager.shareRecording(
    recordingId: "abc123",
    withUserIds: ["user456"],
    permission: .readOnly
)

// Device pairing (Premium)
let pairingManager = client.devicePairingManager
try await pairingManager.discoverDevices()
try await pairingManager.pairWithDevice(id: macDeviceId)
```

## 8. Implementation Phases

### 8.1 Phase 1: Core Foundation

- Local database implementation with APFS Copy-on-Write
- Basic file storage mechanisms
- Initial tier structure
- Authentication framework with settings persistence
- Compliance guidelines implementation

### 8.2 Phase 2: Synchronization

- Storage bucket integration
- Differential database sync with KSUID file naming
- Media file synchronization with CDN URL management
- Conflict resolution
- Selective synchronization options

### 8.3 Phase 3: Sharing and Requests

- Inbound folder processing
- Differential file handling for shares
- Request workflow implementation
- Notification system

### 8.4 Phase 4: Premium Features

- iCloud integration
- Device pairing mechanism
- Custom workflows
- Advanced privacy controls

### 8.5 Phase 5: Performance Optimization

- Caching improvements
- Background processing optimization
- Memory usage reduction
- Battery efficiency enhancements

## 9. Testing Requirements

### 9.1 Unit Testing

- Complete test coverage for all API classes
- Database migration tests
- Error handling validation
- Mock services for external dependencies
- APFS Copy-on-Write efficiency testing

### 9.2 Integration Testing

- End-to-end synchronization testing
- Cross-device communication
- Network condition simulation
- Tier feature validation
- Demo mode functionality verification

### 9.3 Performance Testing

- Database operation benchmarks
- Synchronization timing under various conditions
- Memory usage profiling
- Battery consumption analysis
- KSUID sorting efficiency validation

### 9.4 User Experience Testing

- Loading indicator display and timing
- Error handling and retry flows
- Demo mode limitations
- Settings persistence across reinstalls

## 10. Deployment and Distribution

### 10.1 Dependency Management

- Swift Package Manager integration
- Minimal external dependencies
- Version pinning for stability

### 10.2 Documentation

- Comprehensive API documentation
- Integration guides for internal teams
- Sample code and usage examples
- Architecture diagrams

### 10.3 Release Process

- Semantic versioning
- Release notes for each version
- Migration guides for breaking changes
- Internal testing before release

## 11. Known Limitations and Constraints

### 11.1 Technical Limitations

- SQLite concurrent access limitations
- Network bandwidth constraints for large media files
- On-device storage constraints for extensive catalogs
- Processing power limitations for complex recognition tasks
- APFS Copy-on-Write requires APFS filesystem (standard on modern iOS devices)

### 11.2 Business Constraints

- Clear separation of Free and Premium tier capabilities
- Storage cost considerations for cloud backup
- Privacy regulations compliance
- AI training data quality management

## 12. Future Considerations

### 12.1 Platform Expansion

- Kotlin implementation for Android
- Web client integration
- API access for third-party integrations

### 12.2 Feature Expansion

- Enhanced AI recognition capabilities
- Augmented reality integration
- Advanced analytics for usage patterns
- Enterprise-specific features

### 12.3 Scale Considerations

- Performance at high user counts
- Storage optimization for extensive media catalogs
- Synchronization efficiency improvements
- Optimization of KSUID-based sorting for large file sets

## 13. App Store Compliance

### 13.1 Privacy Descriptions

- Camera usage: "This app requires camera access to scan and record physical objects"
- Photo library access: "Optional access to import existing photos of your items"
- Location access: "Optional to tag items with location information"

### 13.2 Required Notices

- App Description Statement: "RecordThing is a free App for recording objects in the world for personal records and sharing with Thepia User Community. It will download a community showcase along with your personal recordings on the first install."
- AI Training Notice: "Free tier recordings are used to improve our object recognition AI. Premium users can opt-out of AI training contributions."

### 13.3 User Controls

- Clear settings for data sharing preferences
- Easily accessible privacy policy
- Simple tier upgrade/downgrade process
- Straightforward demo mode toggle

## 14. Appendix

### 14.1 Glossary

- **Storage Bucket**: Cloud storage repository for user data
- **KSUID**: K-Sortable Unique Identifier used for file naming and chronological ordering
- **App Support Folder**: Local storage location for application data
- **App Documents Folder**: Local storage location for user-created content
- **SQLite Diff**: Differential file containing database changes for synchronization
- **APFS**: Apple File System with Copy-on-Write capabilities

### 14.2 References

- SQLite Documentation
- Apple File System (APFS) Documentation
- iCloud Documentation
- Swift Concurrency Documentation

---

This revised PRD now fully incorporates all the previously missing elements, with particular attention to:

1. Persistence of client settings beyond app uninstallation
2. APFS Copy-on-Write mechanism and its efficiency benefits
3. Detailed database initialization flow including user ID creation
4. Specific app compliance guidelines with loading indicators and error handling
5. Comprehensive demo user functionality with modification limitations
6. CDN URL fetching for recordings with web download cache
7. Detailed incremental SQLite update implementation
8. KSUID file naming for chronological sorting advantages
9. Complete sharing process using the inbound folder
10. Selective synchronization options based on user preferences

---

The Record Thing client-side component is a Swift/Kotlin library designed to manage data synchronization, authentication, and reference data for the Record Thing mobile application. The library facilitates synchronization between local SQLite databases with associated media recording files and cloud Storage Buckets. The system architecture emphasizes offline-first functionality with cloud backup and sharing capabilities rather than a traditional REST API approach.

The client settings are persisted beyond the uninstall of the App. User settings including the User ID is saved in the App Group Shared Data(`group.com.thepia.recordthing`). This means that other Thepia Apps can access the same settings. Passkeys and tokens are stored in the keychain and set up for iCloud sharing.

The client App uses a local primary SQLite database(in App Support Folder) to store data and downscaled media files. New recordings are saved as local files(in App Documents Folder) and referenced in the database. When the App becomes inactive or goes to the background, the database is backed up to the App Documents folder in case changes have been made since the last backup. This would initially be done by copying, using APFS Copy-on-Write which is nearly instantanious. It should mean that there is no need to check if changes have been made since the last backup.

When the client App is first launched, it will check if the local database exists. If it does not, the App will create a new database based on:

1. Copying the existing database from the App Documents folder.
2. Copying the database from the Storage bucket folder if the user id is set in the App settings.
3. Downloading the demo database from the cloud storage bucket.
4. If the download fails, it will copy the demo database from the Assets folder in the App bundle.

It then creates a new User ID and creates a new Account record, chainging the database owner. It will ensure guidelines compliance by,

- Loading indicator shown
- Handles network/Connection errors (retries)
- Privacy Policy: The App Description states "RecordThing is a free App for recording objects in the world for personal records and sharing with Thepia User Community. It will download a community showcase along with your personal recordings on the first install.
- Local Fallback database copied from Assets

The client App can download DB records for a specific user and replace existing records in the local database.
The client App can backup the local database to the cloud storage bucket under the user's Storage bucket folder.
The client App can sync recording files between the App Documents folder and the Users Storage bucket folder. The user can set up autosync of all recordings or selective when sharing with other users.

The client App can be set up to run with a demo user. This can be done with a toggle in settings.
This will limit the ability to modify the database to protect the demo data.
Demo data can be updated by the user under settings. A button "Reset Demo" will be available to reset the demo data by downloading the original from the Demo Users Storage bucket folder.

When running with the demo user, no syncing is done with the cloud storage bucket.

The client App views of recordings are fetched from the storage bucket using CDN URLs. A web download cache directory is the App Support folder is used. This works the same with demo user and normal user.

The `recordings` folder in the Storage Bucket folder holds the original recording files.
The `images` folder in the Storage Bucket folder holds the downscaled images for viewing.
The `inbound` folder in the Storage Bucket folder holds the incoming SQLite database diff files used to update the local database. This is used to send requests and shares between users.

A common incremental file approach is needed for updating SQLite databases. It needs to be carefully explored and tested. The initial approach will use an SQLite database file to hold the changes. The table definitions from the incoming DB file is used to adjust the local DB file. Additional tables are used to hold references to the changes. The local DB has a table tracking past applied changes. The change files are named using KSUIDs. This allows for quick sorting of files that have to be applied.
