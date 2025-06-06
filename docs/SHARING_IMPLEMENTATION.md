# RecordThing iOS Sharing Implementation

## Project Overview

This document outlines the implementation of iOS sharing functionality for the RecordThing app, enabling users to share content from other apps (YouTube, Safari, etc.) directly into RecordThing. The implementation introduces the concept of "Strategists" - strategic focus areas in the Thepia knowledge base.

## Architecture Overview

### Core Components

1. **iOS Share Extension**: Handles incoming shared content from other apps
2. **Strategists Data Model**: New knowledge base entity for strategic focus areas
3. **Extended Evidence Model**: Links shared content to either Things or Strategists
4. **Main App Integration**: Views and navigation for managing strategists

### Data Flow

```
Other App (YouTube) → Share Extension → Content Processing → Category Selection → Database Storage → Main App Views
```

## Database Schema Changes

### New Strategists Table

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

### Extended Evidence Table

```sql
-- Added fields to existing evidence table:
strategist_account_id TEXT,
strategist_id TEXT,
```

This allows evidence to be linked to either:
- Things (existing functionality)
- Requests (existing functionality)  
- Strategists (new functionality)

## ShareExtension UI

The share extension UI is built using SwiftUI and provides a simple interface for users to categorize and save shared content. It should visualise the shared content by a hero image extracted from the content or contents of the shared URL. 
The shared item is put in a table using Blackbird for "Unprocessed Shares". They will later be processed and moved to the Evidence table. 

The processing will,

- Identify the content type
- Identify the name of people depicted in the content
- Identify the location of the content
- Identify the date of the content
- Identify the author of the content
- Identify the title of the content
- Identify the description of the content
- Identify the tags of the content
- Identify the image of the content
- Identify the video of the content
- Identify the audio of the content
- Identify the document of the content
- Identify the transcript of the content

Once we identify what we can, it is used to decide,

- Is this for strategist and should be tied to a specific strategist?
- Does this relate to an existing Thing?
- Does this represent a new Thing? (I.e. Personal Belonging recently purchased)
- Does this represent a personal event?
- Does this represent a process/flow the user is currently in?


## Implementation Files

### Share Extension (`apps/RecordThing/ShareExtension/`)

- **ShareViewController.swift**: Main extension controller
  - Extracts shared content (URLs, text)
  - Integrates SwiftUI interface
  - Handles extension lifecycle

- **ShareContentView.swift**: SwiftUI sharing interface
  - Content preview
  - Category selection (Thing vs Strategist)
  - Strategist title input
  - Save/Cancel actions

- **Info.plist**: Extension configuration
  - Supports web URLs, web pages, text content
  - Optimized for YouTube sharing

- **MainInterface.storyboard**: Required minimal storyboard
- **ShareExtension.entitlements**: App group configuration

### Swift Models (`apps/libs/RecordLib/Sources/RecordLib/Model/`)

- **Strategists.swift**: New BlackbirdModel for strategic focus areas
- **Evidence.swift**: Extended with strategist relationship fields
- **Model.swift**: Added selectedStrategistID property

### Main App Views (`apps/RecordThing/Shared/Evidence/`)

- **StrategistsMenu.swift**: Navigation menu entry point
- **StrategistsList.swift**: List view with BlackbirdLiveModels
- **StrategistsRow.swift**: Individual strategist row component
- **StrategistsView.swift**: Detail view showing related evidence

## Key Features

### Content Type Support

1. **YouTube Videos**: Automatic detection and title extraction
2. **Web URLs**: Any web page from Safari or other browsers
3. **Text Content**: Text that may contain URLs

### User Experience Flow

1. User shares content from another app
2. RecordThing appears in share sheet
3. Content preview is displayed
4. User selects category (Thing or Strategist)
5. If Strategist: user enters strategic focus area title
6. Content is saved to RecordThing database
7. User returns to original app

### Strategic Focus Areas (Strategists)

- **Purpose**: Organize content around strategic interests/projects
- **Flexibility**: Create new focus areas on-the-fly during sharing
- **Tagging**: Support for JSON-based tag arrays
- **Evidence Links**: View all shared content related to a strategic area

## Technical Implementation Details

### App Groups Configuration

Required for data sharing between main app and extension:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.thepia.recordthing</string>
</array>
```

### Content Type Detection

The share extension handles:
- `UTType.url.identifier`: Direct URL sharing
- `UTType.text.identifier`: Text content with potential URLs
- Web page metadata extraction

### Database Integration

- Uses existing Blackbird ORM patterns
- Maintains KSUID-based primary keys
- Follows existing relationship patterns (similar to Things/Evidence)

## Implementation Status

### ✅ Completed

- [x] Database schema design and implementation
- [x] Swift models with Blackbird integration
- [x] Share extension structure and SwiftUI interface
- [x] Content extraction and processing logic
- [x] Main app views for strategists
- [x] Category selection and user interface
- [x] Documentation and implementation plan

### 🚧 Pending (Requires Xcode Configuration)

- [ ] Add Share Extension target to Xcode project
- [ ] Configure build settings and dependencies
- [ ] Set up app groups in project settings
- [ ] Implement actual database saving in share extension
- [ ] Test with YouTube app and other sharing sources

### 🔮 Future Enhancements

- [ ] Enhanced metadata extraction (thumbnails, descriptions)
- [ ] Deep linking from share extension to main app
- [ ] Batch sharing support
- [ ] Advanced content categorization
- [ ] Sync with Thepia Strategist cloud service

## Development Guidelines

### Adding New Content Types

1. Update `Info.plist` with new UTType identifiers
2. Add handling logic in `ShareViewController.extractSharedContent`
3. Update UI in `ShareContentView` if needed
4. Test with relevant apps

### Extending Strategist Functionality

1. Follow existing patterns from Things/Requests models
2. Use BlackbirdLiveModels for data binding
3. Maintain consistency with existing navigation patterns
4. Update database schema through Python scripts

### Testing Strategy

1. **Unit Tests**: Test content extraction and processing logic
2. **Integration Tests**: Test database operations and model relationships
3. **Manual Testing**: Test with various apps (YouTube, Safari, Twitter, etc.)
4. **Edge Cases**: Test with malformed URLs, large content, network issues

## Next Steps for Full Implementation

1. **Xcode Project Setup**
   - Add Share Extension target
   - Configure bundle identifiers and entitlements
   - Set up build dependencies

2. **Database Integration**
   - Implement shared database access
   - Add error handling and validation
   - Test data persistence

3. **Enhanced Features**
   - Add metadata extraction for URLs
   - Implement thumbnail/image handling
   - Add progress indicators and loading states

4. **Testing and Polish**
   - Comprehensive testing with various content types
   - User experience refinements
   - Performance optimization

This implementation provides a solid foundation for iOS sharing functionality while maintaining consistency with the existing RecordThing architecture and keeping the Strategists concept minimal as requested.
