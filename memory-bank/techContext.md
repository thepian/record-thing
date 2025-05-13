# Technical Context: Record Thing

## Technologies Used

### Client Applications

#### Swift/SwiftUI

- **Version**: Swift 5.9+
- **Usage**: Core language for iOS and macOS client applications
- **Components**: UI, business logic, local data management
- **Key Features**: SwiftUI for declarative UI, Combine for reactive programming

#### Blackbird

- **Usage**: Swift ORM for SQLite database
- **Components**: Data persistence, query building, model mapping
- **Key Features**: Async/await support, migrations, type-safe queries

#### Vision Framework

- **Usage**: Apple's computer vision framework
- **Components**: Image analysis, object detection
- **Key Features**: Integration with Core ML, image processing

#### Core ML

- **Usage**: Machine learning model integration
- **Components**: Model execution, prediction
- **Key Features**: On-device ML processing, hardware acceleration

### Backend Components

#### Python

- **Version**: Python 3.9+
- **Usage**: Backend tools, data management, ML processing
- **Components**: CLI tools, database setup, sync utilities
- **Key Features**: Async support, type hints, modern Python practices

#### SQLite

- **Version**: SQLite 3.39+
- **Usage**: Local database storage
- **Components**: Data persistence, vector extensions
- **Key Features**: Full-text search, JSON support, vector similarity search

#### MLX

- **Usage**: Apple's machine learning framework for Apple Silicon
- **Components**: ML model training and inference
- **Key Features**: Optimized for Apple Silicon, high-performance ML

#### DINO v2

- **Usage**: Self-supervised learning model for computer vision
- **Components**: Image recognition, feature extraction
- **Key Features**: Zero-shot classification, feature embedding

### Cloud Services

#### Bunny CDN

- **Usage**: Content delivery network for asset storage
- **Components**: File synchronization, asset delivery
- **Key Features**: Global distribution, edge storage

#### B2 Storage

- **Usage**: Cloud storage for backups and synchronization
- **Components**: Database backups, large file storage
- **Key Features**: Object storage, versioning

## Development Setup

### iOS/macOS Development

```
# Required tools
brew install xcode-build-server xcbeautify swiftformat

# Build iOS app
cd apps/RecordThing
xcodebuild -scheme "RecordThing iOS" -configuration Debug -derivedDataPath ./DerivedData -destination "platform=iOS Simulator,name=iPhone 14 Pro"

# Build macOS app
cd apps/RecordThing
xcodebuild -scheme "RecordThing macOS" -configuration Debug -derivedDataPath ./DerivedData
```

### Python Environment Setup

```
# Using uv (recommended)
uv venv
source .venv/bin/activate
uv pip install -e .

# Using pip
python -m venv .venv
source .venv/bin/activate
pip install -e .
```

### Database Management

```
# Initialize a new database
uv run -m record_thing.cli init-db

# Update database schema
uv run -m record_thing.cli update-db

# Populate with sample data
uv run -m record_thing.cli populate-db
```

### Sync Configuration

```
# Configure sync with storage bucket
uv run buckia --config ./assets
uv run buckia sync --folder=<folder_id>
```

## Technical Constraints

### Cross-Platform Compatibility

- Must work seamlessly on iOS and macOS with shared codebase
- UI must adapt to different screen sizes and input methods
- Platform-specific features must be conditionally implemented

### Performance Requirements

- ML processing must be optimized for on-device execution
- Database operations must be efficient for large collections
- Sync operations must handle large files and intermittent connectivity

### Security Requirements

- All user data must be encrypted at rest and in transit
- Authentication must use modern standards (Passkeys)
- Sharing must respect user privacy settings

### Offline Functionality

- Core features must work without internet connectivity
- Sync must handle conflict resolution for offline changes
- Local storage must be optimized for device constraints

## Dependencies

### Swift Packages

- **Blackbird**: SQLite ORM for Swift
- **SwiftUI**: Apple's UI framework
- **Combine**: Reactive programming framework
- **Vision**: Computer vision framework
- **Core ML**: Machine learning framework

### Python Packages

- **SQLite3**: Database engine
- **MLX**: Machine learning framework
- **NumPy**: Numerical computing
- **Pillow**: Image processing
- **Buckia**: Synchronization utility

### External Services

- **Bunny CDN**: Content delivery network
- **B2 Storage**: Cloud storage
- **together.ai**: Image generation service

## Development Workflow

### Code Organization

- **apps/RecordThing**: iOS and macOS client applications
- **apps/RecordThing/Shared**: Cross-platform Swift code
- **apps/RecordThing/iOS**: iOS-specific code
- **apps/RecordThing/macOS**: macOS-specific code
- **libs/record_thing**: Python backend libraries
- **libs/RecordLib**: Swift library for shared functionality

### Build Process

1. Set up development environment
2. Initialize database
3. Build client application
4. Configure sync services
5. Run tests

### Deployment Process

1. Build release version of client apps
2. Submit to App Store / TestFlight
3. Deploy backend services
4. Configure CDN and storage buckets
5. Set up monitoring and analytics
