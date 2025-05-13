# Proposal for Buckia Swift SDK

# Buckia Integration for RecordThing: Swift Client Library Package

## Overview

Buckia provides a robust foundation for RecordThing's client-side data management through a Swift client library package. This integration layer handles all file management between on-device storage and remote Storage Buckets, supporting both Free and Premium tier requirements while maintaining RecordThing's offline-first architecture.

## Core Functionality

### Unified Storage Interface

Buckia offers a consistent API across local and remote operations, abstracting the complexities of:

- File system operations
- Cloud provider integration
- Synchronization mechanisms
- Authentication and security

This allows RecordThing to focus on its core functionality while delegating storage management to a specialized component.

## Architecture Integration

### Configuration Management

```swift
// Configuration based on user tier
let bucketConfig = BucketConfig(
    provider: "bunny",  // or "s3", "linode" based on team configuration
    bucket_name: userTier == .premium ? "premium-storage" : "free-storage",
    region: userRegion,
    api_key: apiCredentials.key
)

// Initialize the client
let buckiaClient = BuckiaClient(config: bucketConfig)
```

### Team-Based Storage Bucket Mapping

Buckia integrates with RecordThing's database to dynamically determine Storage Bucket endpoints:

1. RecordThing's database maintains team records with corresponding Storage Bucket information
2. When a user logs in, their team affiliation determines which Storage Bucket configuration to use
3. Buckia dynamically configures connectivity based on this mapping:
   - Free tier users → common storage bucket
   - Premium tier users → dedicated premium storage bucket

### Directory Structure Management

Buckia maintains RecordThing's required directory structure:

```
bucket_name/
├── <user-id>/
│   ├── recordings/    # Original recording files
│   ├── images/        # Downscaled images for viewing
│   ├── inbound/       # Incoming SQLite diff files
│   └── App.sqlite     # Database backup
└── <demo-team-id>/
    ├── recordings/    # Demo recordings
    ├── images/        # Demo images
    └── App.sqlite     # Demo database
```

## Tier-Specific Implementation

### Free Tier Support

For Free tier users, Buckia:

- Reads from common storage bucket for demo content
- Maintains local file cache in App Support folder
- Supports sharing by uploading selected files to common bucket
- Enables AI training integration by handling uploads to the specified training buckets
- Provides read-only access to demo team folders
- Implements appropriate access controls to prevent unauthorized modifications

### Premium Tier Support

For Premium tier users, Buckia extends functionality to:

- Enable bi-directional synchronization with dedicated premium storage bucket
- Support selective synchronization based on user preferences
- Implement privacy controls allowing users to mark recordings as private
- Facilitate complete database backup to cloud storage
- Enable cross-device synchronization through cloud storage
- Support device pairing through shared access to cloud resources

## Technical Implementation

### Local File Management

Buckia handles RecordThing's local storage requirements:

```swift
// Store a new recording
try await buckiaClient.storeLocalFile(
    data: recordingData,
    localPath: "\(userID)/recordings/\(fileName)",
    metadata: recordingMetadata
)

// Generate and store preview
try await buckiaClient.storeLocalFile(
    data: previewData,
    localPath: "\(userID)/images/\(fileName)",
    metadata: previewMetadata
)
```

### Database Backup Integration

Buckia seamlessly integrates with RecordThing's APFS Copy-on-Write database backup:

```swift
// After local backup completes
let databasePath = "\(appDocumentsPath)/App.sqlite"
try await buckiaClient.sync(
    localPath: databasePath,
    remotePath: "\(userID)/App.sqlite",
    direction: .upload,
    priority: .high
)
```

### Cloud Synchronization

Buckia implements RecordThing's synchronization requirements:

```swift
// Bi-directional sync for premium users
if userTier == .premium {
    try await buckiaClient.sync(
        localPath: "recordings",
        remotePath: "\(userID)/recordings",
        delete_orphaned: false,
        max_workers: 4
    )
} else {
    // For free tier, only sync specific shared items
    for item in sharedItems {
        try await buckiaClient.sync(
            localPath: "recordings/\(item.id)",
            remotePath: "\(userID)/recordings/\(item.id)",
            direction: .upload,
            delete_orphaned: false
        )
    }
}
```

### KSUID-Based Incremental Updates

Buckia supports RecordThing's KSUID-based incremental SQLite updates:

```swift
// Check for new updates in inbound folder
let inboundUpdates = try await buckiaClient.listFiles(
    remotePath: "\(userID)/inbound/",
    pattern: "*.sqlite"
)

// Sort updates by KSUID (chronologically)
let sortedUpdates = inboundUpdates.sorted(by: { $0.name < $1.name })

// Download and process updates
for update in sortedUpdates {
    try await buckiaClient.sync(
        localPath: "temp/\(update.name)",
        remotePath: "\(userID)/inbound/\(update.name)",
        direction: .download
    )

    // Process update
    // ...

    // Mark as processed
    try await buckiaClient.deleteFile(
        remotePath: "\(userID)/inbound/\(update.name)"
    )
}
```

### CDN Integration

Buckia provides CDN URL management for efficient content delivery:

```swift
// Get CDN URL for a recording
let cdnUrl = try await buckiaClient.getCdnUrl(
    remotePath: "\(userID)/images/\(fileName)",
    expiration: 3600  // URL valid for 1 hour
)

// Use URL in RecordThing's UI
imageView.load(url: cdnUrl)
```

## Security Implementation

### Authentication

Buckia handles the authentication requirements:

- Secure API key storage in Keychain
- Token refresh management
- Rate limiting compliance
- Permission-based access controls

### Data Protection

For RecordThing's sensitive data:

- End-to-end encryption for Premium tier content
- Secure transmission protocols
- Access control based on user identity
- Privacy tagging support for AI training opt-out

## Operational Features

### Background Operations

Buckia enables RecordThing's background processes:

```swift
// Register background sync task
buckiaClient.registerBackgroundTask(
    identifier: "com.thepia.recordthing.sync",
    sync: {
        // Sync critical data
        try await buckiaClient.syncCriticalData()
    }
)
```

### Progress Reporting

Detailed progress for RecordThing's user interface:

```swift
// Sync with progress reporting
try await buckiaClient.sync(
    localPath: "recordings",
    remotePath: "\(userID)/recordings",
    progress: { current, total, action, path in
        let percentage = Float(current) / Float(total)
        DispatchQueue.main.async {
            self.updateProgressBar(percentage, action: action)
        }
    }
)
```

### Error Handling

Robust error management for RecordThing's reliability requirements:

```swift
do {
    try await buckiaClient.sync(/*...*/)
} catch BuckiaError.networkError(let error) {
    // Handle network issues
    recordThingApp.handleNetworkError(error)
} catch BuckiaError.authenticationError(let error) {
    // Handle authentication issues
    recordThingApp.refreshCredentials()
} catch {
    // Handle other errors
    recordThingApp.logError(error)
}
```

## Implementation Benefits

1. **Separation of Concerns**: RecordThing can focus on its core object recognition and user experience while Buckia handles the storage infrastructure

2. **Future-Proofing**: Storage provider changes can be implemented by updating Buckia configuration without modifying RecordThing's core code

3. **Cross-Platform Consistency**: As RecordThing expands to Android, Buckia's unified API ensures consistent behavior across platforms

4. **Simplified Tier Management**: Bucket configurations can be updated server-side to reflect tier changes without app updates

5. **Scalability**: Buckia's multi-worker architecture handles increasing file volumes as RecordThing's user base grows

6. **Operational Efficiency**: Optimized transfer algorithms reduce bandwidth usage and improve battery life

## Integration Example

Integrating Buckia with RecordThing's existing architecture:

```swift
// In RecordThingClientLib initialization
func initialize() async throws {
    // Get user's team information
    let userTeam = await databaseManager.getUserTeam()

    // Configure Buckia based on team storage settings
    let bucketConfig = BucketConfig(
        provider: userTeam.storageProvider,
        bucket_name: userTeam.bucketName,
        region: userTeam.region,
        api_key: await keychainManager.getApiKey(for: userTeam.storageProvider)
    )

    // Initialize Buckia client
    self.storageClient = BuckiaClient(config: bucketConfig)

    // Configure paths based on tier
    if userTeam.tier == .premium {
        // Set up premium paths with full synchronization
        try await configureStorageForPremium()
    } else {
        // Set up free tier paths with limited synchronization
        try await configureStorageForFreeTier()
    }

    // Initialize database using Buckia for retrieval
    try await initializeDatabase()
}
```

## Conclusion

Buckia provides the ideal foundation for RecordThing's storage and synchronization needs, offering a dedicated Swift package that handles the complexities of file management while supporting the distinct requirements of both Free and Premium tiers. By abstracting storage operations through a consistent API, Buckia enables RecordThing to focus on its core competencies while ensuring reliable, efficient, and secure data management across local and cloud environments.
