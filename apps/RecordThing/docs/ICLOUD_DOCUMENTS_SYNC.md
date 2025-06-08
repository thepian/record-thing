# iCloud Documents Sync in RecordThing

## Overview

RecordThing now includes **iCloud Documents folder sync** functionality that allows users to manually trigger synchronization of their Documents folder across devices. This feature is available to all users (both Free and Premium tiers) and leverages iOS's built-in iCloud Documents syncing capabilities.

## Features

### ✅ **Available for All Users**
- **Manual Sync Trigger**: Users can manually trigger iCloud Documents sync from Settings
- **Sync Status Monitoring**: Real-time monitoring of file sync states
- **Debug Interface**: Comprehensive debugging view for troubleshooting
- **Automatic Detection**: Automatically detects iCloud availability

### 🎯 **Premium Features**
- **Advanced Sync**: Full database and asset synchronization
- **Selective Sync**: Choose what data to sync
- **Auto Sync**: Automatic background synchronization

## User Interface

### Settings → Sync & Backup

The sync section now includes:

1. **Auto Sync Toggle** (Premium only)
   - Enables automatic background synchronization
   - Disabled for Free tier users

2. **Selective Sync Toggle** (Premium only)
   - Allows users to choose specific data types to sync
   - Only available with Premium plan

3. **iCloud Backup Toggle** (Premium only)
   - Enables comprehensive iCloud backup
   - Premium feature only

4. **Sync iCloud Documents Button** (All users)
   - **NEW**: Manual trigger for iCloud Documents sync
   - Available for all users regardless of plan
   - Shows progress indicator when syncing
   - Disabled when iCloud is not available

5. **Sync Now Button** (Premium only)
   - Triggers comprehensive manual sync
   - Premium feature only

6. **Last Sync Status**
   - Shows when the last sync occurred
   - Updates after manual sync operations

7. **iCloud Debug Link**
   - **NEW**: Direct access to iCloud debugging interface
   - Shows detailed sync status and diagnostics

## Technical Implementation

### SettingsManager Updates

Added new method for iCloud Documents sync:

```swift
/// Trigger iCloud Documents folder sync (available for all users)
func triggeriCloudDocumentsSync() async {
    guard SimpleiCloudManager.shared.isAvailable else {
        logger.warning("iCloud Documents sync attempted but iCloud not available")
        return
    }

    isSyncing = true
    defer { isSyncing = false }

    do {
        let manager = SimpleiCloudManager.shared
        
        // Enable sync if not already enabled
        if !manager.isEnabled {
            manager.enableSync()
        }

        // Force refresh metadata query to check sync status
        await refreshiCloudDocumentsStatus()

        // Update last sync status
        userDefaults.set(Date(), forKey: "last_sync_date")
        lastSyncStatus = "Just now"

        logger.info("iCloud Documents sync triggered successfully")

    } catch {
        logger.error("iCloud Documents sync failed: \(error.localizedDescription)")
        lastSyncStatus = "Failed"
    }
}
```

### SimpleiCloudManager Integration

The implementation leverages the existing `SimpleiCloudManager` which:

- **Monitors iCloud availability** using NSMetadataQuery
- **Tracks file sync states** automatically
- **Provides diagnostic information** for debugging
- **Handles automatic syncing** when iCloud is enabled

## User Experience

### Free Tier Users
- Can manually trigger iCloud Documents sync
- Access to iCloud debug interface
- Basic sync status monitoring
- Automatic file syncing when iCloud is enabled

### Premium Users
- All Free tier features
- Advanced automatic sync capabilities
- Selective sync options
- Comprehensive backup features

## Debugging & Monitoring

### iCloud Debug View

Access via **Settings → Sync & Backup → iCloud Debug**:

- **Status Section**: iCloud availability and sync state
- **Statistics**: Total/synced/pending file counts  
- **Document List**: Individual file sync status
- **Test Actions**: Create test files to verify syncing
- **Diagnostics**: Detailed system information

### Sync Status Indicators

- **Synced**: File is uploaded and available on all devices
- **Syncing**: File is in the process of uploading/downloading
- **Not Downloaded**: File exists in iCloud but not downloaded locally
- **Conflict**: Multiple versions exist (requires user resolution)
- **Error**: Sync failed (check network/storage)

## Benefits

### For Users
- **Easy Access**: One-tap sync trigger in Settings
- **Transparency**: Clear sync status and progress
- **Debugging**: Comprehensive tools for troubleshooting
- **Reliability**: Leverages iOS built-in sync mechanisms

### For Development
- **Freemium Friendly**: Basic sync available to all users
- **Premium Upsell**: Advanced features encourage upgrades
- **Monitoring**: Built-in debugging and diagnostics
- **Maintainable**: Uses existing SimpleiCloudManager infrastructure

## Future Enhancements

- **Automatic Sync Triggers**: Background sync on app launch/background
- **Conflict Resolution**: UI for resolving sync conflicts
- **Bandwidth Management**: Sync only on WiFi options
- **Sync Scheduling**: User-defined sync intervals
- **Progress Notifications**: System notifications for sync completion

## Related Documentation

- [ICLOUD_SYNC.md](../../../docs/ICLOUD_SYNC.md) - Comprehensive iCloud sync documentation
- [FREEMIUM_TIERS_PRD.md](../../../FREEMIUM_TIERS_PRD.md) - Freemium tier specifications
- [SimpleiCloudManager](../../../apps/libs/RecordLib/Sources/RecordLib/Sync/SimpleiCloudManager.swift) - Core sync implementation
