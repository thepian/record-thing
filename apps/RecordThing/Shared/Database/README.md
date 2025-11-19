# Database Monitoring and Error Handling System

This directory contains a comprehensive database monitoring and error handling system for the RecordThing app, designed to provide detailed diagnostics and error recovery for database-related issues.

## Overview

The system provides:
- **Real-time database activity tracking**
- **Detailed error analysis and SQLite error code interpretation**
- **Comprehensive error dashboard with diagnostics**
- **Enhanced error views for user-facing database failures**
- **Debug menu integration for development and troubleshooting**

## Components

### Core Monitoring

#### `DatabaseMonitor.swift`
- **Singleton class** that tracks all database activities and errors
- **Real-time health monitoring** with automatic health checks
- **Activity logging** with timestamps and detailed context
- **Error tracking** with SQLite error code interpretation
- **Statistics collection** for performance monitoring

Key features:
- Tracks connection establishment, queries, errors, and maintenance operations
- Provides SQLite error code interpretation (e.g., Error 7 = SQLITE_NOMEM)
- Maintains connection information and uptime statistics
- Automatic health checks every 30 seconds

#### `DatabaseConnectionInfo`
Data structure containing:
- Database path and type (development, debug, production, bundled)
- Connection timestamp and file size
- Read-only status and other metadata

### User Interface Components

#### `DatabaseErrorDashboard.swift`
- **Comprehensive dashboard** with multiple tabs:
  - **Overview**: Connection info, statistics, recent activities
  - **Activities**: Complete activity log with filtering
  - **Errors**: Error history with detailed analysis
  - **Diagnostics**: System information and database file status

#### `DatabaseErrorView.swift`
- **Enhanced error view** for user-facing database failures
- **SQLite error code interpretation** with user-friendly descriptions
- **Database status display** with real-time health information
- **Quick action buttons** for retry, reload, and reset operations
- **Recent activity preview** for context

#### `DatabaseDetailViews.swift`
- **Activity detail view** with complete activity information
- **Error detail view** with troubleshooting suggestions
- **Metadata display** for debugging purposes

### Debug Integration

#### `DatabaseDebugMenu.swift`
- **Debug menu** for development and troubleshooting
- **Database actions**: Reload, Reset, Update, Health Check
- **Real-time statistics** and status monitoring
- **Activity log preview** with quick access to full dashboard

## Integration with AppDatasource

The monitoring system is integrated into `AppDatasource.swift` to track:

### Connection Events
```swift
// Logs when database connections are established
let connectionInfo = DatabaseConnectionInfo(
    path: databasePath,
    type: .development, // or .debug, .production, .bundled
    connectedAt: Date(),
    fileSize: fileSize,
    isReadOnly: false
)
monitor.updateConnectionInfo(connectionInfo)
```

### Error Tracking
```swift
// Logs database errors with context
monitor.logError(error, context: "Failed to open database", query: nil)
```

### Activity Logging
```swift
// Logs database operations
monitor.logActivity(.databaseReset, details: "Database reset initiated")
```

## SQLite Error Code Interpretation

The system provides detailed interpretation of SQLite error codes:

| Code | Name | Description | Common Causes |
|------|------|-------------|---------------|
| 1 | SQLITE_ERROR | Generic error | SQL syntax errors, constraint violations |
| 5 | SQLITE_BUSY | Database locked | Concurrent access, long-running transactions |
| 7 | SQLITE_NOMEM | Out of memory | Insufficient RAM, large queries |
| 8 | SQLITE_READONLY | Read-only database | File permissions, disk full |
| 11 | SQLITE_CORRUPT | Database corrupted | File system errors, power loss |
| 14 | SQLITE_CANTOPEN | Cannot open file | Missing file, permissions |

## Usage Examples

### In Views with Database Errors

```swift
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                DatabaseErrorView(
                    error: error,
                    context: "Failed to load data",
                    onRetry: { viewModel.loadData() }
                )
            } else {
                // Normal content
                ContentView(data: viewModel.data)
            }
        }
    }
}
```

### In ViewModels

```swift
class MyViewModel: ObservableObject {
    func loadData() {
        Task {
            do {
                // Database operation
                let data = try await database.query("SELECT * FROM table")
                // Handle success
            } catch {
                // Log to monitoring system
                DatabaseMonitor.shared.logError(
                    error, 
                    context: "MyViewModel failed to load data",
                    query: "SELECT * FROM table"
                )
                
                // Update UI
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
}
```

### Debug Menu Integration

```swift
struct DebugView: View {
    var body: some View {
        List {
            NavigationLink("Database Debug") {
                DatabaseDebugMenu()
            }
            
            NavigationLink("Error Dashboard") {
                DatabaseErrorDashboard()
            }
        }
    }
}
```

## Database Activity Types

The system tracks various activity types:

- **connectionEstablished**: Database connection created
- **connectionLost**: Database connection lost
- **databaseReset**: Database reset to default state
- **databaseReloaded**: Database reconnected
- **queryExecuted**: SQL query performed
- **error**: Database error occurred
- **migrationStarted**: Schema migration began
- **migrationCompleted**: Schema migration finished
- **debugAction**: Debug operation performed

## Performance Monitoring

The system provides performance statistics:

- **Total Activities**: Count of all logged activities
- **Error Count**: Number of errors encountered
- **Connection Count**: Number of connection attempts
- **Query Count**: Number of queries executed
- **Uptime**: Time since last connection
- **Error Rate**: Percentage of operations that failed

## Troubleshooting Features

### Automatic Suggestions
The error views provide context-specific troubleshooting suggestions:

- **SQLITE_BUSY**: Wait and retry, check for other app instances
- **SQLITE_NOMEM**: Close other apps, restart device, check storage
- **SQLITE_READONLY**: Check permissions, verify location, reset database
- **SQLITE_CORRUPT**: Reset database, restore from backup, contact support

### Quick Actions
- **Retry**: Attempt the failed operation again
- **Reload Database**: Reconnect to the current database
- **Reset Database**: Reset to the default bundled database
- **Health Check**: Test database connectivity
- **View Dashboard**: Open the comprehensive error dashboard

## Development Workflow

1. **Monitor Activities**: Use the debug menu to watch real-time database activities
2. **Analyze Errors**: Use the error dashboard to investigate failures
3. **Test Recovery**: Use quick actions to test error recovery scenarios
4. **Performance Tuning**: Monitor statistics to identify performance issues

## Best Practices

### Error Handling
- Always log database errors to the monitoring system
- Provide context and query information when available
- Use the enhanced error views for user-facing failures

### Activity Logging
- Log significant database operations (connections, resets, migrations)
- Include relevant details in activity descriptions
- Use appropriate activity types for categorization

### User Experience
- Show the enhanced error view instead of generic error messages
- Provide retry and recovery options
- Display database status information for transparency

## Future Enhancements

Potential improvements to the monitoring system:

- **Export functionality** for activity logs and error reports
- **Performance metrics** with query timing and optimization suggestions
- **Automated recovery** for common error scenarios
- **Remote logging** for production error tracking
- **Custom alert thresholds** for proactive monitoring

## Files Overview

```
Database/
├── README.md                    # This documentation
├── DatabaseMonitor.swift        # Core monitoring system
├── DatabaseErrorDashboard.swift # Comprehensive error dashboard
├── DatabaseErrorView.swift      # User-facing error view
├── DatabaseDetailViews.swift    # Detail views for activities/errors
└── ../Debug/DatabaseDebugMenu.swift # Debug menu integration
```

This system provides comprehensive database monitoring and error handling, making it easier to diagnose and resolve database issues in the RecordThing app.
