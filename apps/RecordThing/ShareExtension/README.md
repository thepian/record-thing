# RecordThing Share Extension

## Overview

This share extension allows users to share content from other iOS apps (like YouTube, Safari, etc.) directly into the RecordThing app. The shared content can be categorized as either a "Thing" (physical item) or a "Strategist" (strategic focus area in the Thepia knowledge base).

## Features

- **YouTube Video Sharing**: Share YouTube videos directly from the YouTube app
- **Web URL Sharing**: Share any web page URL from Safari or other browsers
- **Text Content Sharing**: Share text content that may contain URLs
- **Categorization**: Choose whether to add content to Things or Strategists
- **Strategic Focus Areas**: Create new strategic focus areas on-the-fly when sharing

## Implementation Status

### ✅ Completed
- [x] Basic share extension structure
- [x] SwiftUI-based sharing interface
- [x] URL and text content extraction
- [x] YouTube URL detection
- [x] Category selection (Thing vs Strategist)
- [x] Strategist title input
- [x] Database schema extension (Strategists table)
- [x] Swift models for Strategists
- [x] Evidence model extension for strategist relationships
- [x] Basic UI views for Strategists in main app

### 🚧 To Be Implemented
- [ ] Actual database saving in share extension
- [ ] App group configuration for data sharing
- [ ] Xcode project target configuration
- [ ] Metadata extraction from URLs (titles, thumbnails)
- [ ] Deep linking from share extension to main app
- [ ] Error handling and user feedback
- [ ] Testing with various content types

## Architecture

### Share Extension Components

1. **ShareViewController.swift**: Main controller that handles the sharing flow
2. **ShareContentView.swift**: SwiftUI view for the sharing interface
3. **Info.plist**: Extension configuration and supported content types
4. **MainInterface.storyboard**: Required storyboard (minimal implementation)
5. **ShareExtension.entitlements**: App group entitlements for data sharing

### Database Schema

The implementation adds a new `strategists` table:

```sql
CREATE TABLE IF NOT EXISTS strategists (
    id TEXT NOT NULL DEFAULT '',  -- KSUID
    account_id TEXT NOT NULL DEFAULT '',
    title TEXT NULL DEFAULT NULL,
    description TEXT NULL DEFAULT NULL,
    tags TEXT NULL DEFAULT NULL, -- JSON array
    created_at FLOAT NULL DEFAULT NULL,
    updated_at FLOAT NULL DEFAULT NULL,
    PRIMARY KEY (account_id, id)
);
```

The `evidence` table is extended to support strategist relationships:

```sql
-- Added fields to evidence table:
strategist_account_id TEXT,
strategist_id TEXT,
```

### Swift Models

- **Strategists.swift**: BlackbirdModel for strategic focus areas
- **Evidence.swift**: Extended to include strategist relationships
- **Model.swift**: Updated to include selectedStrategistID

### Main App Views

- **StrategistsMenu.swift**: Navigation menu for strategists
- **StrategistsList.swift**: List view of all strategists
- **StrategistsRow.swift**: Individual strategist row component
- **StrategistsView.swift**: Detail view for a strategist with related evidence

## Usage Flow

1. **User shares content** from another app (e.g., YouTube video)
2. **Share extension opens** with RecordThing option
3. **Content preview** shows the shared URL/text
4. **User selects category**: Thing or Strategist
5. **If Strategist selected**: User enters title for strategic focus area
6. **User taps Save**: Content is saved to RecordThing database
7. **Extension closes**: User returns to original app

## Next Steps for Full Implementation

### 1. Xcode Project Configuration
- Add Share Extension target to RecordThing.xcodeproj
- Configure build settings and dependencies
- Set up proper bundle identifiers
- Configure app groups

### 2. Database Integration
- Implement actual database saving in ShareViewController
- Set up shared database access between main app and extension
- Handle database initialization and migration

### 3. Enhanced Metadata Extraction
- Implement YouTube API integration for video metadata
- Add web scraping for page titles and descriptions
- Extract and store thumbnail images

### 4. Testing and Polish
- Test with various content types and apps
- Add proper error handling and user feedback
- Implement loading states and progress indicators
- Add accessibility support

### 5. Deep Linking
- Implement URL schemes for opening specific content in main app
- Add "Open in RecordThing" functionality from share extension

## Configuration Requirements

### App Groups
The share extension requires app groups to share data with the main app:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.thepia.recordthing</string>
</array>
```

### Supported Content Types
The extension is configured to handle:
- Web URLs (NSExtensionActivationSupportsWebURLWithMaxCount)
- Web pages (NSExtensionActivationSupportsWebPageWithMaxCount)  
- Text content (NSExtensionActivationSupportsText)

## Development Notes

- The implementation follows the existing RecordThing patterns (Things/Evidence/Requests)
- Uses Blackbird ORM for database operations
- Maintains consistency with existing SwiftUI views and navigation
- Keeps the Strategists implementation minimal as requested
- Focuses on YouTube sharing as the primary use case

This provides a solid foundation for iOS sharing functionality while keeping the implementation focused and minimal.
