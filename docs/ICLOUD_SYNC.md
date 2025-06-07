# iCloud Documents Syncing

## Overview

RecordThing leverages iOS's built-in iCloud Documents functionality to automatically sync user data across devices. With proper entitlements, files stored in the app's Documents directory are automatically synchronized to iCloud and made available on all devices signed in with the same Apple ID.

## How It Works

### Automatic Syncing (Standard iOS Behavior)

iCloud Documents syncing happens **automatically** without custom sync logic:

1. **Files in Documents folder sync automatically** across devices
2. **Cross-device access is automatic** with same Apple ID  
3. **Conflict resolution is built-in** (iOS creates .icloud conflict files)
4. **Download on demand** - files appear but download when accessed
5. **Background optimization** - iOS handles timing and bandwidth

### What Gets Synced

- **Database**: `record-thing.sqlite` - Main app database
- **Assets**: `assets/` folder - User recordings and media files
- **Backups**: `record-thing-backup.sqlite` - Database backup copies
- **User files**: Any files created in Documents directory

## Implementation

### Required Entitlements

The app includes CloudDocuments entitlement in `iOS.entitlements`:

```xml
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
    <string>CloudDocuments</string>
</array>
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.thepia.recordthing</string>
</array>
```

### SimpleiCloudManager

The `SimpleiCloudManager` provides monitoring and utilities without implementing custom sync logic:

```swift
// Get Documents directory (automatically synced)
let documentsURL = SimpleiCloudManager.shared.getDocumentsURL()

// Create files (will sync automatically)
let fileURL = try SimpleiCloudManager.shared.createTextFile(
    named: "example.txt", 
    content: "This will sync automatically"
)

// Monitor sync status
let syncStatus = SimpleiCloudManager.shared.getFileStatus("example.txt")
```

### Key Features

- **Availability Detection**: Checks if iCloud is enabled
- **Sync Status Monitoring**: Uses NSMetadataQuery to track file sync states
- **File Management**: Convenience methods for creating and managing files
- **Debug Interface**: Comprehensive debugging view for troubleshooting

## Monitoring & Debugging

### SimpleiCloudDebugView

Access via Settings → Sync & Backup → iCloud Debug:

- **Status Section**: iCloud availability and sync state
- **Statistics**: Total/synced/pending file counts
- **Document List**: Individual file sync status
- **Test Actions**: Create test files to verify syncing

### Sync Status Indicators

- **Synced**: File is uploaded and available on all devices
- **Syncing**: File is in the process of uploading/downloading
- **Not Downloaded**: File exists in iCloud but not downloaded locally
- **Conflict**: Multiple versions exist (requires user resolution)
- **Error**: Sync failed (check network/storage)

### Production Monitoring

Monitor sync health in production:

```swift
// Check overall sync status
let summary = SimpleiCloudManager.shared.getSyncSummary()
// Returns: "15/20 files synced (5 pending)"

// Monitor specific files
let dbStatus = SimpleiCloudManager.shared.getFileStatus("record-thing.sqlite")

// Get detailed document states
let allStates = SimpleiCloudManager.shared.documentStates
```

## User Experience

### Freemium Integration

- **Free Tier**: Local storage only, no iCloud sync
- **Premium Tier**: Full iCloud sync enabled
- **Settings Control**: Users can enable/disable sync
- **Status Visibility**: Clear indication of sync state

### Cross-Device Workflow

1. **User creates content** on Device A (iPhone)
2. **File saves to Documents** folder locally
3. **iOS automatically uploads** to iCloud in background
4. **File appears on Device B** (iPad) automatically
5. **User accesses file** → iOS downloads if needed

### Conflict Resolution

When the same file is modified on multiple devices:

1. **iOS detects conflict** during sync
2. **Creates conflict versions** with timestamps
3. **User sees conflict indicator** in debug view
4. **Manual resolution required** - choose which version to keep

## Testing

### Automated Tests

The test suite verifies real iCloud functionality:

```swift
// Test automatic sync setup
func testAutomaticSyncSetup() async throws {
    guard iCloudManager.isAvailable else {
        throw XCTSkip("iCloud not available")
    }
    
    // Create file - will sync automatically
    let fileURL = try iCloudManager.createTextFile(
        named: "sync-test.txt", 
        content: "Auto sync test"
    )
    
    // Verify sync status monitoring works
    let syncStatus = iCloudManager.getFileStatus("sync-test.txt")
    XCTAssertNotEqual(syncStatus, "Unknown")
}
```

### Manual Testing

1. **Enable iCloud** on test devices with same Apple ID
2. **Create test files** using debug interface
3. **Verify files appear** on other devices
4. **Test conflict resolution** by editing same file on multiple devices
5. **Monitor sync status** in debug view

### Test Requirements

- **Physical devices** with iCloud enabled (simulator has limitations)
- **Same Apple ID** across test devices
- **Network connectivity** for cloud operations
- **iCloud storage space** available

## Troubleshooting

### Common Issues

**iCloud Not Available**
- Check iOS Settings → [Your Name] → iCloud
- Ensure iCloud Drive is enabled
- Verify sufficient iCloud storage

**Files Not Syncing**
- Check network connectivity
- Verify app has CloudDocuments entitlement
- Monitor sync status in debug view
- Check for storage quota limits

**Sync Conflicts**
- Use debug view to identify conflicted files
- Manually resolve by choosing preferred version
- Consider implementing automatic conflict resolution

### Debug Information

The debug view provides comprehensive information:

- iCloud container URL and availability
- Individual file sync states
- Error messages and timestamps
- Network and storage status
- Test file creation capabilities

## Architecture Benefits

### Leveraging iOS Built-ins

- **No custom sync logic** - reduces complexity and bugs
- **Battery efficient** - iOS optimizes sync timing
- **Bandwidth aware** - respects cellular data settings
- **Privacy compliant** - follows user's iCloud preferences
- **Conflict handling** - built-in resolution mechanisms

### Production Advantages

- **Reliable syncing** - battle-tested iOS infrastructure
- **Automatic optimization** - iOS handles network conditions
- **User control** - respects iCloud settings and preferences
- **Cross-platform** - works on iPhone, iPad, Mac automatically
- **Maintenance-free** - no custom sync servers to maintain

## Integration with RecordThing

### Database Syncing

The main SQLite database automatically syncs:

```swift
// Database is stored in Documents directory
let dbURL = documentsURL.appendingPathComponent("record-thing.sqlite")
// This file will sync automatically across devices
```

### Asset Management

Media files and recordings sync seamlessly:

```swift
// Assets folder syncs automatically
let assetsURL = documentsURL.appendingPathComponent("assets")
// All recordings and media files sync across devices
```

### Backup Strategy

Multiple backup layers:

1. **Local backup**: `record-thing-backup.sqlite` in Documents
2. **iCloud sync**: Automatic cloud backup via Documents syncing
3. **Version history**: iOS maintains file versions automatically

This comprehensive iCloud integration ensures users have seamless access to their RecordThing data across all their Apple devices while maintaining the simplicity and reliability of iOS's built-in syncing infrastructure.
