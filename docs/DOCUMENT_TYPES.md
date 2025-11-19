# RecordThing Document Types Strategy

## Overview

RecordThing supports various document types for import, export, and iCloud Documents integration. This document outlines the complete strategy for file handling and document type registration.

## Supported Document Types

### Container Types (Future Implementation)

#### Evidence Containers (`.evidence`)
- **Purpose**: Bundle evidence files with metadata
- **Content**: Multiple media files, metadata, relationships
- **Use Cases**: 
  - Import evidence bundles from external sources
  - Export evidence collections for sharing
  - Backup evidence with complete context

#### Things Containers (`.things`)
- **Purpose**: Complete Thing definitions with all associated data
- **Content**: Thing metadata, evidence files, relationships, categories
- **Use Cases**:
  - Import complete item definitions
  - Export Things for backup or sharing
  - Transfer data between users

### Database Files

#### SQLite Files (`.sqlite`)
- **Purpose**: Database import with schema validation
- **Validation**: Checks for RecordThing-compatible schema
- **Use Cases**:
  - Import data from other RecordThing instances
  - Support investigation and troubleshooting
  - Database migration and backup restoration
- **Error Handling**: Clear messaging for incompatible schemas

### Media Files

#### Images
- **Formats**: JPEG, PNG, HEIF, and other standard formats
- **Sources**: Photos app, Files app, camera capture
- **Processing**: Local metadata extraction, thumbnail generation
- **Use Cases**: Evidence documentation, item photography

#### Videos
- **Formats**: MP4, MOV, and other standard formats
- **Sources**: Photos app, Files app, camera recording
- **Processing**: Local analysis, frame extraction
- **Use Cases**: Item demonstrations, evidence recording

#### Audio
- **Formats**: MP3, AAC, WAV, and other standard formats
- **Sources**: Microphone recording, Files app import
- **Processing**: Local analysis, metadata extraction
- **Use Cases**: Voice notes, evidence documentation

### Email Files (Planned)

#### Email Messages
- **Formats**: `.eml`, Apple Mail formats
- **Purpose**: Evidence collection from email communications
- **Processing**: Local content extraction, attachment handling
- **Use Cases**: Receipt documentation, correspondence evidence

## File Opening Behavior

### From Files App

When users open files in RecordThing from the Files app:

#### Database Files
1. **Schema Validation**: Automatic compatibility check
2. **Import Options**:
   - Add to existing topics/strategists
   - Import as backup for investigation
3. **Error Handling**: User-friendly messages for incompatible files

#### Media Files
1. **Import Workflow**: 
   - Select existing Thing or create new
   - Add as evidence with metadata
   - Batch processing for multiple files
2. **Metadata Preservation**: Original file metadata retained
3. **Quality Options**: Original quality or optimized versions

#### Container Files (Future)
1. **Validation**: Check container integrity and format
2. **Conflict Resolution**: Handle duplicates and conflicts
3. **Selective Import**: Choose specific items from containers

### Document Browser Integration

RecordThing includes limited document browser functionality:

- **Scope**: Only for RecordThing-specific file types
- **Purpose**: Not a general document browser
- **Focus**: Import/export of app-specific content

## iCloud Documents Integration

### Automatic Syncing

Files in the Documents directory sync automatically:

- **Database**: `record-thing.sqlite`
- **Assets**: `assets/` folder with media files
- **Backups**: Automatic database backups
- **User Files**: Any files created in Documents

### Cross-Device Access

- **iPhone ↔ iPad ↔ Mac**: Seamless data access
- **Offline Availability**: Files cached locally after download
- **Conflict Resolution**: iOS handles conflicts automatically

## Privacy and Security

### Local Processing

All file processing occurs on-device:

- **No Cloud Analysis**: Files not sent to external servers
- **Metadata Extraction**: Local analysis only
- **Schema Validation**: Database checks performed locally
- **Privacy Preserved**: File contents remain private

### iCloud Integration

- **User Control**: Managed through iOS Settings
- **Apple Infrastructure**: Uses Apple's secure iCloud
- **No Third-Party Access**: RecordThing cannot access iCloud data
- **Encryption**: Apple provides end-to-end encryption

## Implementation Details

### Info.plist Configuration

Both iOS and macOS Info.plist files include:

- **CFBundleDocumentTypes**: Supported document types
- **UTExportedTypeDeclarations**: Custom type definitions
- **LSSupportsOpeningDocumentsInPlace**: Document editing support
- **UISupportsDocumentBrowser**: Document browser integration (iOS only)

### File Type Registration

Custom types registered with the system:

- `com.thepia.recordthing.evidence` - Evidence containers
- `com.thepia.recordthing.things` - Things containers
- Standard types: `public.sqlite3-database`, `public.image`, etc.

### User Activity Types

Document activities for Handoff and Spotlight:

- `$(PRODUCT_BUNDLE_IDENTIFIER).container` - Container files
- `$(PRODUCT_BUNDLE_IDENTIFIER).database` - Database files
- `$(PRODUCT_BUNDLE_IDENTIFIER).media` - Media files

## Future Enhancements

### Planned Features

1. **Container Format Implementation**: Define and implement `.evidence` and `.things` formats
2. **Email Import**: Support for email file processing
3. **Batch Operations**: Enhanced multi-file import/export
4. **Encryption Options**: Optional file encryption for sensitive data

### Considerations

1. **Performance**: Large file handling optimization
2. **Storage**: Efficient space usage for media files
3. **Compatibility**: Backward compatibility for format changes
4. **User Experience**: Intuitive import/export workflows

## Testing Strategy

### File Type Registration

- Verify file types appear in Files app
- Test opening files from external apps
- Validate document browser integration

### Import/Export Workflows

- Test various file formats and sizes
- Verify error handling for invalid files
- Check metadata preservation

### iCloud Sync

- Test cross-device synchronization
- Verify conflict resolution
- Check offline access functionality

---

*This document outlines the complete document types strategy for RecordThing, covering current implementation and future plans.*
