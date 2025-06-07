# RecordLib - Shared Database and Core Components

RecordLib is a Swift Package that contains shared database components, models, and utilities for the RecordThing ecosystem. This library enables code reuse across the main app, ShareExtension, and other components.

## Overview

RecordLib provides:
- **Centralized database management** with comprehensive monitoring
- **Shared data models** (Account, Things, Evidence, etc.)
- **Database error handling and debugging tools**
- **Common utilities and extensions**

## Components Moved to RecordLib

### Database Management

#### `AppDatasource.swift`
- **Core database connection and management**
- **Translation loading and caching**
- **Database operations** (reload, reset, update)
- **Health monitoring integration**

#### `DatabaseMonitor.swift`
- **Real-time activity tracking** with timestamps
- **Error logging and SQLite error code interpretation**
- **Health monitoring** with automatic checks
- **Performance statistics** and uptime tracking

#### `DatabaseErrorView.swift`
- **Enhanced error display** for database failures
- **SQLite error code interpretation** with user-friendly descriptions
- **Recovery actions** (retry, reload, reset)
- **Database status information**

#### `DatabaseDebugView.swift`
- **Debug interface** for database operations
- **Real-time statistics** and activity monitoring
- **Quick actions** for database management

### Data Models

#### `Account.swift`
- **Account model** with Blackbird integration
- **Owner model** for account relationships
- **AccountModel** for app-specific logic
- **Extensions** for validation and display

### Assets and Evidence

#### `AssetsViewModel.swift`
- **Asset management** with database integration
- **Error handling** with database monitoring
- **Asset grouping** and organization logic

## Migration Benefits

### ✅ **Code Reuse**
- **Shared across components**: Main app, ShareExtension, future modules
- **Consistent behavior**: Same database logic everywhere
- **Reduced duplication**: Single source of truth

### ✅ **Enhanced Error Handling**
- **Comprehensive monitoring**: All database operations tracked
- **Detailed diagnostics**: SQLite error code interpretation
- **User-friendly errors**: Clear explanations and recovery options

### ✅ **Better Debugging**
- **Real-time monitoring**: Activity tracking with timestamps
- **Performance metrics**: Error rates, uptime, query counts
- **Debug tools**: Built-in database management interface

### ✅ **Maintainability**
- **Centralized logic**: Database operations in one place
- **Easier testing**: Components can be tested independently
- **Consistent APIs**: Same interface across all components

## Usage

### In Main App

The main app now extends RecordLib's AppDatasource:

```swift
import RecordLib

class AppDatasource: RecordLib.AppDatasource {
    // App-specific customizations
    override init(debugDb: Bool = false) {
        super.init(debugDb: debugDb)
        // Additional setup
    }
}
```

### In ShareExtension

The ShareExtension can now use the shared components:

```swift
import RecordLib

class ShareExtensionDatasource: RecordLib.AppDatasource {
    // ShareExtension-specific setup
}
```

### Error Handling in Views

Views can now use the enhanced error handling:

```swift
import RecordLib

struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        Group {
            if let error = viewModel.error {
                DatabaseErrorView(
                    error: error,
                    context: "Failed to load data",
                    onRetry: { viewModel.loadData() }
                )
            } else {
                // Normal content
            }
        }
    }
}
```

### Debug Menu Integration

Add database debugging to any view:

```swift
import RecordLib

struct DebugView: View {
    var body: some View {
        NavigationView {
            DatabaseDebugView()
                .environmentObject(AppDatasource.shared)
        }
    }
}
```

## Database Monitoring

### Activity Tracking

All database operations are automatically tracked:

```swift
// Automatically logged by AppDatasource
DatabaseMonitor.shared.logActivity(.connectionEstablished, details: "Connected to development database")
DatabaseMonitor.shared.logActivity(.queryExecuted, details: "SELECT * FROM things")
DatabaseMonitor.shared.logError(error, context: "Failed to load assets", query: "SELECT created_at FROM things")
```

### Error Analysis

The system provides detailed error analysis:

- **SQLite Error Codes**: Automatic interpretation (e.g., Error 7 = SQLITE_NOMEM)
- **Context Information**: What operation failed and when
- **Recovery Suggestions**: Specific actions based on error type
- **Database Status**: Real-time health and connection information

### Performance Monitoring

Track database performance:

- **Activity Count**: Total operations performed
- **Error Rate**: Percentage of failed operations
- **Uptime**: Time since last connection
- **Query Performance**: Track slow or failing queries

## File Structure

```
RecordLib/Sources/RecordLib/
├── AppDatasource.swift              # Core database management
├── Model/
│   ├── Account.swift                # Account and Owner models
│   ├── Things.swift                 # Things model (existing)
│   ├── Evidence.swift               # Evidence model (existing)
│   └── ...                          # Other models
├── Database/
│   ├── DatabaseMonitor.swift        # Activity tracking and monitoring
│   ├── DatabaseErrorView.swift      # Enhanced error display
│   └── DatabaseDebugView.swift      # Debug interface
├── Assets/
│   ├── AssetsViewModel.swift        # Asset management
│   └── ...                          # Asset-related components
└── README.md                        # This documentation
```

## Migration Checklist

### ✅ **Completed**
- [x] Moved AppDatasource to RecordLib
- [x] Moved Account models to RecordLib
- [x] Created comprehensive database monitoring system
- [x] Enhanced error handling with SQLite error interpretation
- [x] Created debug interface for database operations
- [x] Updated main app to extend RecordLib AppDatasource
- [x] Integrated monitoring into AssetsViewModel

### 🔄 **Next Steps**
- [ ] Update ShareExtension to use RecordLib AppDatasource
- [ ] Add database monitoring to other ViewModels
- [ ] Create unit tests for RecordLib components
- [ ] Add performance benchmarking
- [ ] Create documentation for ShareExtension integration

## Error Handling Examples

### Blackbird Error 7 (SQLITE_NOMEM)

When the "Blackbird.Database.Error error 7" occurs:

1. **Automatic Detection**: Error code 7 is automatically identified as SQLITE_NOMEM
2. **User-Friendly Display**: Shows "Out of memory" with explanation
3. **Recovery Suggestions**: 
   - Close other apps
   - Restart the device
   - Check available storage
4. **Quick Actions**: Retry, reload database, reset to default

### Database Connection Issues

When database connection fails:

1. **Status Monitoring**: Real-time connection status display
2. **Health Checks**: Automatic connectivity testing every 30 seconds
3. **Recovery Options**: Reload, reset, or switch database types
4. **Activity Log**: Complete history of connection attempts

## Testing

### Unit Tests

Test database components independently:

```swift
import XCTest
@testable import RecordLib

class DatabaseMonitorTests: XCTestCase {
    func testErrorLogging() {
        let monitor = DatabaseMonitor.shared
        let error = NSError(domain: "Test", code: 7, userInfo: [:])
        
        monitor.logError(error, context: "Test error")
        
        XCTAssertEqual(monitor.activities.count, 1)
        XCTAssertEqual(monitor.activities.first?.type, .error)
    }
}
```

### Integration Tests

Test database operations with monitoring:

```swift
func testDatabaseOperationWithMonitoring() {
    let datasource = AppDatasource(debugDb: true)
    let monitor = DatabaseMonitor.shared
    
    // Perform database operation
    datasource.reloadDatabase()
    
    // Verify monitoring
    XCTAssertTrue(monitor.activities.contains { $0.type == .databaseReloaded })
}
```

## Performance Considerations

### Memory Usage
- **Activity Limit**: Only keeps last 100 activities in memory
- **Lazy Loading**: Database connections created on demand
- **Weak References**: Prevents retain cycles in monitoring

### Database Performance
- **Connection Pooling**: Reuses database connections
- **Health Checks**: Lightweight queries every 30 seconds
- **Error Recovery**: Automatic reconnection on failures

### UI Responsiveness
- **Background Operations**: Database operations on background queues
- **Main Actor Updates**: UI updates on main thread
- **Progressive Loading**: Assets loaded incrementally

This migration provides a solid foundation for shared database management across the RecordThing ecosystem, with comprehensive monitoring and error handling capabilities.
