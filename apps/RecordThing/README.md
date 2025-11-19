# RecordThing: A Modern SwiftUI Recording and Knowledge Management App

A multiplatform SwiftUI app for recording, organizing, and sharing knowledge across devices with automatic iCloud syncing.

## Overview

RecordThing is a comprehensive knowledge management application built with SwiftUI that runs on iOS, iPadOS, and macOS. The app enables users to:

- **Record and organize content** using a structured workflow system
- **Share content from other apps** (YouTube, web pages) into strategic focus areas  
- **Manage knowledge** through the integrated Thepia Strategist system
- **Sync data automatically** across all devices using iCloud Documents
- **Access widgets** for quick information display on iOS Home Screen and macOS Notification Center

The app implements modern SwiftUI features including:

- **Cross-platform shared codebase** for iOS, iPadOS, and macOS
- **ShareExtension** for importing content from other apps
- **Widget extensions** for Home Screen and Notification Center integration
- **iCloud Documents syncing** for seamless cross-device data access
- **Comprehensive database management** with debugging and monitoring tools

## Building and Running RecordThing

### Requirements

- **iOS/iPadOS**: iOS 18.4+ (built with Xcode 16+)
- **macOS**: macOS 15.4+ (built with Xcode 16+)
- **Development**: Xcode 16+ with Swift 6.0+

### Quick Start

1. **Clone the repository** and open `RecordThing.xcodeproj`
2. **Select your target**: Choose "RecordThing iOS" for mobile or "RecordThing macOS" for desktop
3. **Configure signing**: Set your development team in Signing & Capabilities
4. **Build and run**: ⌘+R to build and launch the app

### Development Setup

For development with personal Apple ID:
1. In Signing & Capabilities, click "Add Account" and sign in with your Apple ID
2. Select "Your Name (Personal Team)" from the team dropdown
3. Build and run - the app will use the development database automatically

For device testing:
1. On iOS/iPadOS devices, go to Settings > General > VPN & Device Management
2. Trust your developer certificate to run the app

### ShareExtension Setup

The ShareExtension allows importing content from other apps:
1. The extension is automatically included when building the main app
2. Test by sharing a YouTube video or web page to RecordThing
3. Content appears in "Unprocessed Shares" for organization

## Architecture

### SwiftUI App Structure

RecordThing uses a shared SwiftUI app definition that works across all platforms:

```swift
@main
struct RecordThingApp: App {
    @StateObject private var appDatasource = AppDatasource.shared
    
    var body: some Scene {
        WindowGroup {
            AppSplitView()
                .environmentObject(appDatasource)
        }
        .commands {
            SidebarCommands()
        }
    }
}
```

The app leverages SwiftUI's cross-platform capabilities to provide a consistent experience across iOS, iPadOS, and macOS while adapting to each platform's unique characteristics.

### Database Management

RecordThing uses SQLite with Blackbird for database operations:

- **Development Database**: Automatically used when available in the project directory
- **Production Database**: Copied from app bundle to Documents directory
- **iCloud Sync**: Documents directory automatically syncs across devices
- **Debug Tools**: Comprehensive database monitoring and debugging interface

### ShareExtension Integration

The ShareExtension enables content import from other apps:

```swift
// ShareExtension processes shared content
struct ShareExtensionView: View {
    @StateObject private var viewModel = ShareExtensionViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Content preview and organization interface
                SharedContentPreview(content: viewModel.sharedContent)
                StrategistSelector(selectedStrategist: $viewModel.selectedStrategist)
            }
        }
    }
}
```

## Features

### Knowledge Management

- **Things**: Core content items with metadata and relationships
- **Evidence**: Supporting materials and documentation
- **Strategists**: Organizational categories for strategic focus areas
- **Workflows**: Structured processes for content creation and organization

### Cross-Platform Syncing

RecordThing leverages iOS's built-in iCloud Documents functionality:

- **Automatic Syncing**: Files in Documents folder sync automatically across devices
- **Cross-Device Access**: Data appears automatically on iPhone, iPad, and Mac
- **Built-in Conflict Resolution**: iOS handles conflicts by creating versioned files
- **Download on Demand**: Files appear but download when accessed to save storage

### Debugging and Monitoring

Access comprehensive debugging tools via Settings:

- **Database Debug**: Monitor database connections, performance, and errors
- **iCloud Debug**: Track sync status, file states, and troubleshoot issues
- **Performance Monitoring**: Real-time metrics and health checks

## Widget Extensions

RecordThing includes widget extensions for iOS Home Screen and macOS Notification Center:

```swift
struct RecordThingWidget: Widget {
    let kind: String = "RecordThingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RecordThingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("RecordThing")
        .description("Quick access to your latest recordings and knowledge items.")
    }
}
```

For more information, see [WidgetKit](https://developer.apple.com/documentation/widgetkit).

## iCloud Documents Syncing

RecordThing leverages iOS's built-in iCloud Documents functionality to automatically sync user data across devices. With the proper `CloudDocuments` entitlement, files stored in the app's Documents directory are automatically synchronized to iCloud and made available on all devices signed in with the same Apple ID.

### Key Features

- **Automatic Syncing**: Files in Documents folder sync automatically across devices
- **Cross-Device Access**: Data appears automatically on iPhone, iPad, and Mac
- **Built-in Conflict Resolution**: iOS handles conflicts by creating versioned files
- **Download on Demand**: Files appear but download when accessed to save storage
- **Background Optimization**: iOS optimizes sync timing for battery and bandwidth

### Implementation

The app includes the `CloudDocuments` entitlement in `iOS.entitlements`:

```xml
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
    <string>CloudDocuments</string>
</array>
```

### Monitoring and Debugging

Access the iCloud sync debug interface via:
**Settings → Sync & Backup → iCloud Debug**

The debug view provides:

- iCloud availability status
- File-by-file sync status
- Sync statistics and progress
- Test file creation capabilities
- Troubleshooting information

### What Gets Synced

- **Database**: `record-thing.sqlite` - Main app database
- **Assets**: `assets/` folder - User recordings and media files
- **Backups**: Database backup copies
- **User files**: Any files created in Documents directory

### Production Monitoring

Monitor sync health in production code:

```swift
// Check overall sync status
let summary = SimpleiCloudManager.shared.getSyncSummary()

// Monitor specific files
let dbStatus = SimpleiCloudManager.shared.getFileStatus("record-thing.sqlite")

// Get detailed sync states
let allStates = SimpleiCloudManager.shared.documentStates
```

For comprehensive documentation, see [iCloud Sync Documentation](../../docs/ICLOUD_SYNC.md).

## Testing

### ShareExtension Testing

See [ShareExtension Testing Documentation](ShareExtension/TESTING.md) for comprehensive testing instructions.

### Database Testing

The app includes extensive database testing capabilities:

- Unit tests for database operations
- Integration tests for cross-platform compatibility
- Performance benchmarks for large datasets
- Error handling and recovery testing

### iCloud Sync Testing

Test iCloud functionality across devices:

1. Enable iCloud on multiple devices with the same Apple ID
2. Create content on one device and verify it appears on others
3. Test conflict resolution by editing the same content simultaneously
4. Monitor sync status using the debug interface

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with appropriate tests
4. Submit a pull request

## License

See [LICENSE](LICENSE/LICENSE.txt) for details.
