# macOS Database Connectivity & Debugging Guide

## Overview

This document provides a comprehensive guide to the enhanced database connectivity system for RecordThing on macOS, including debugging tools and fallback strategies to handle App Sandbox restrictions and other connectivity issues.

## Table of Contents

1. [macOS Database Challenges](#macos-database-challenges)
2. [Enhanced Connectivity Manager](#enhanced-connectivity-manager)
3. [Database Connection Modes](#database-connection-modes)
4. [Debugging Tools](#debugging-tools)
5. [Troubleshooting Guide](#troubleshooting-guide)
6. [Implementation Details](#implementation-details)

## macOS Database Challenges

### App Sandbox Restrictions

macOS App Sandbox creates several challenges for SQLite database access:

#### **1. Container Isolation**
- Apps run in isolated containers: `~/Library/Containers/YourAppBundleIdentifier/`
- Database must be within the sandbox container for write access
- App Support directory: `~/Library/Containers/YourAppBundleIdentifier/Data/Library/Application Support/`

#### **2. SQLite Journal Files**
- SQLite creates temporary journal files (`.sqlite-journal`, `.sqlite-wal`) during transactions
- These files must be created in the same directory as the main database
- Sandbox prevents journal file creation outside the container

#### **3. Quarantine Attributes**
- Bundled databases may have `com.apple.quarantine` extended attributes
- These attributes prevent Blackbird from opening the database
- Must be removed programmatically: `xattr -d com.apple.quarantine database.sqlite`

#### **4. File Permissions**
- Standard POSIX permissions still apply within the sandbox
- Read-only locations prevent SQLite write operations
- Directory permissions affect journal file creation

## Enhanced Connectivity Manager

### **DatabaseConnectivityManager**

The `DatabaseConnectivityManager` provides intelligent database connection with automatic fallback:

```swift
// Automatic connection with fallback strategy
let (database, mode) = await DatabaseConnectivityManager.shared.connectWithFallback()

// Test specific connection mode
let database = await connectivityManager.attemptConnection(mode: .production)

// Comprehensive diagnostics
let diagnostics = await connectivityManager.performDiagnostics()
```

### **Key Features**

#### **1. Automatic Fallback Strategy**
- Tries connection modes in priority order
- Falls back to in-memory database if all file-based connections fail
- Provides detailed logging for each attempt

#### **2. Comprehensive Diagnostics**
- File existence and permission checks
- Quarantine attribute detection
- Sandbox path validation
- Journal file creation testing
- Database integrity verification

#### **3. Quarantine Attribute Removal**
- Automatic detection of quarantine attributes
- Programmatic removal using `xattr` command
- Fallback handling if removal fails

#### **4. In-Memory Database Clone**
- Creates in-memory copy of bundled database
- Preserves all data and schema
- Provides full read/write access without file system issues

## Database Connection Modes

### **1. Debug Mode** (Highest Priority)
```
Path: ~/Desktop/record-thing-debug.sqlite
Use Case: Development debugging with custom database states
Requirements: File must exist on developer's desktop
```

### **2. Development Mode**
```
Path: /Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite
Use Case: Git-tracked database for simulator development
Requirements: Project directory must be accessible
```

### **3. Production Mode**
```
Path: ~/Library/Containers/[BundleID]/Data/Library/Application Support/record-thing.sqlite
Use Case: Normal app operation with user data
Requirements: App Sandbox container access
```

### **4. In-Memory Mode**
```
Path: :memory:
Use Case: Fallback when file-based access fails
Requirements: Bundled database for cloning
Features: Full read/write access, no persistence
```

### **5. Bundled Mode** (Last Resort)
```
Path: Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite")
Use Case: Read-only access to default data
Requirements: Bundled database in app resources
Limitations: Read-only access
```

## Debugging Tools

### **DatabaseConnectivityDebugView**

Comprehensive debugging interface accessible from Database Debug Menu:

#### **Connection Status**
- Real-time connection status indicator
- Current database mode display
- Issue count and severity

#### **Mode Testing**
- Test connection to any database mode
- Real-time success/failure feedback
- Detailed error information

#### **Diagnostics Panel**
- File existence and permissions
- Quarantine attribute status
- Sandbox container information
- Database integrity checks
- Available disk space

#### **System Information**
- Platform details (macOS/iOS)
- App Sandbox status
- Bundle identifier
- Container paths

#### **Action Buttons**
- Run comprehensive diagnostics
- Attempt fallback connection
- Remove quarantine attributes (macOS)
- Create in-memory clone
- Reset to bundled database

### **Enhanced Database Debug Menu**

Updated debug menu with new connectivity features:

```swift
// Access from app settings or debug menu
DatabaseDebugMenu()
  .environmentObject(datasource)
```

#### **New Features**
- **Connectivity Debug**: Opens detailed connectivity diagnostics
- **Mode Selection**: Test different database connection modes
- **Real-time Status**: Live connection status updates
- **Action Results**: Immediate feedback on debug actions

## Troubleshooting Guide

### **Common Issues and Solutions**

#### **1. "Operation not permitted" Error**
```
Issue: SQLite cannot create journal files
Cause: Database outside sandbox container or insufficient permissions
Solution: Ensure database is in App Support folder within sandbox
```

#### **2. "Blackbird.Database.Error error 7" (NOMEM)**
```
Issue: Memory allocation failure or corrupted database
Cause: Insufficient memory or database corruption
Solution: Use in-memory clone or reset database
```

#### **3. Quarantine Attributes Preventing Access**
```
Issue: Bundled database cannot be opened
Cause: com.apple.quarantine extended attributes
Solution: Use removeQuarantineAttributes() method
```

#### **4. Sandbox Permission Denied**
```
Issue: Cannot access database outside container
Cause: App Sandbox restrictions
Solution: Move database to App Support folder
```

### **Diagnostic Commands**

#### **Check Quarantine Attributes**
```bash
xattr -l /path/to/database.sqlite
```

#### **Remove Quarantine Attributes**
```bash
xattr -d com.apple.quarantine /path/to/database.sqlite
```

#### **Check File Permissions**
```bash
ls -la /path/to/database.sqlite
```

#### **Verify Sandbox Container**
```bash
ls -la ~/Library/Containers/com.thepia.recordthing/Data/Library/Application\ Support/
```

## Implementation Details

### **Integration with AppDatasource**

The enhanced connectivity is integrated into the existing `AppDatasource`:

```swift
// Enhanced setup with fallback strategy
private func setupDatabase() {
    let connectivityManager = DatabaseConnectivityManager.shared
    
    Task {
        let (database, mode) = await connectivityManager.connectWithFallback()
        
        await MainActor.run {
            if let db = database {
                self.db = db
                self.updateConnectionInfo(for: mode)
                logger.info("✅ Database connected in \(mode) mode")
            } else {
                logger.error("❌ All connection attempts failed")
                self.setupFallbackDatabase() // Original implementation
            }
        }
    }
}
```

### **Monitoring Integration**

The connectivity manager integrates with the existing `DatabaseMonitor`:

```swift
// Update connection info for monitoring
private func updateConnectionInfo(for mode: DatabaseConnectivityManager.DatabaseMode) {
    let monitor = DatabaseMonitor.shared
    let connectionInfo = DatabaseConnectionInfo(
        path: getDatabasePath(for: mode),
        type: connectionType,
        connectedAt: Date(),
        fileSize: getFileSize(at: path),
        isReadOnly: mode == .bundled
    )
    monitor.updateConnectionInfo(connectionInfo)
}
```

### **Error Handling**

Comprehensive error handling with specific issue identification:

```swift
public enum ConnectivityIssue {
    case sandboxPermissions      // App Sandbox prevents access
    case fileNotFound           // Database file missing
    case quarantineAttributes   // Extended attributes blocking access
    case journalFileBlocked     // Cannot create SQLite journal files
    case diskSpace             // Insufficient disk space
    case corruptedDatabase     // Database integrity issues
    case unknownError(Error)   // Other errors
}
```

### **Fallback Strategy**

Intelligent fallback with priority ordering:

1. **Debug Database**: For development debugging
2. **Development Database**: Git-tracked database
3. **Production Database**: App Support folder
4. **In-Memory Clone**: Memory-based fallback
5. **Bundled Database**: Read-only last resort

### **Performance Considerations**

- **Lazy Loading**: Connectivity manager initializes on first use
- **Async Operations**: All database operations are async to prevent UI blocking
- **Caching**: Diagnostics results are cached to avoid repeated checks
- **Background Processing**: Heavy operations run on background queues

## Usage Examples

### **Basic Connection**
```swift
// Simple connection with automatic fallback
let connectivityManager = DatabaseConnectivityManager.shared
let (database, mode) = await connectivityManager.connectWithFallback()

if let db = database {
    // Use database normally
    let results = try await db.query("SELECT * FROM things")
}
```

### **Diagnostic Check**
```swift
// Run comprehensive diagnostics
let diagnostics = await connectivityManager.performDiagnostics()

if !diagnostics.issues.isEmpty {
    for issue in diagnostics.issues {
        print("Issue: \(issue.description)")
        print("Recommendation: \(issue.recommendation)")
    }
}
```

### **Manual Mode Testing**
```swift
// Test specific connection mode
let database = await connectivityManager.attemptConnection(mode: .production)

if database != nil {
    print("✅ Production mode connection successful")
} else {
    print("❌ Production mode connection failed")
}
```

### **In-Memory Clone Creation**
```swift
// Create in-memory database clone
let memoryDB = await connectivityManager.createInMemoryClone()

if let db = memoryDB {
    // Full read/write access without file system issues
    try await db.query("INSERT INTO things (id, title) VALUES (?, ?)", "test", "Test Item")
}
```

## Benefits

### **For Developers**
- **Comprehensive Debugging**: Detailed diagnostics and logging
- **Automatic Fallbacks**: Reduces development friction
- **Clear Error Messages**: Specific issue identification and recommendations
- **Visual Tools**: User-friendly debugging interface

### **For Users**
- **Reliable Operation**: Automatic fallback ensures app functionality
- **Better Performance**: Optimized connection strategies
- **Data Safety**: Multiple backup and recovery options
- **Transparent Operation**: Issues handled automatically

### **For Production**
- **Robust Error Handling**: Graceful degradation on connection failures
- **Monitoring Integration**: Real-time connection status tracking
- **Performance Optimization**: Efficient connection management
- **Maintenance Tools**: Built-in diagnostic and repair capabilities

This enhanced database connectivity system ensures reliable operation on macOS while providing comprehensive debugging tools for development and troubleshooting.
