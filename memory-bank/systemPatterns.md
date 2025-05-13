# System Patterns: Record Thing

## System Architecture

Record Thing follows a hybrid architecture that combines local processing with cloud synchronization:

### Client-Side Architecture

```
┌─────────────────────────────────────────────┐
│                  UI Layer                   │
│  (SwiftUI Views, Navigation, Components)    │
├─────────────────────────────────────────────┤
│               Application Layer             │
│  (View Models, State Management, Services)  │
├─────────────────────────────────────────────┤
│                Domain Layer                 │
│  (Business Logic, Models, ML Processing)    │
├─────────────────────────────────────────────┤
│               Persistence Layer             │
│  (SQLite/Blackbird, File Storage)           │
├─────────────────────────────────────────────┤
│              Synchronization Layer          │
│  (B2/Bunny CDN Integration)                 │
└─────────────────────────────────────────────┘
```

### Server-Side Architecture

```
┌─────────────────────────────────────────────┐
│               Storage Buckets               │
│  (Asset Storage, File Synchronization)      │
├─────────────────────────────────────────────┤
│               Python Backend                │
│  (Data Management, ML Processing)           │
└─────────────────────────────────────────────┘
```

## Key Technical Decisions

### 1. Cross-Platform Swift/SwiftUI

- **Decision**: Use Swift and SwiftUI for both iOS and macOS clients
- **Rationale**: Maximizes code reuse while providing native experience on both platforms
- **Implementation**: Shared codebase with platform-specific adaptations where necessary

### 2. Local-First Database with Sync

- **Decision**: Use SQLite with Blackbird ORM for local storage with cloud sync capabilities
- **Rationale**: Provides offline functionality while enabling multi-device synchronization
- **Implementation**: SQLite database with Vector Extensions for ML features, synced to cloud storage

### 3. ML Vision Processing

- **Decision**: Use DINO v2 for computer vision and scene recognition
- **Rationale**: Provides state-of-the-art object recognition with minimal training requirements
- **Implementation**: MLX framework integration for optimized performance on Apple Silicon

### 4. Universe-Based Feature Deployment

- **Decision**: Package features as downloadable "Universes"
- **Rationale**: Enables modular feature deployment and customization
- **Implementation**: ZIP-based packages containing ML models, processes, and configurations

### 5. Evidence-Based Data Model

- **Decision**: Center data model around "Evidence" connected to "Things"
- **Rationale**: Provides flexibility for various types of documentation and verification
- **Implementation**: Relational database schema with Things, Evidence, Requests, and Accounts

## Design Patterns in Use

### MVVM (Model-View-ViewModel)

- **Usage**: Primary UI architecture pattern
- **Implementation**: SwiftUI views bound to ViewModels that manage state and business logic
- **Example Components**: ThingsView, ThingsViewModel, ThingsModel

### Repository Pattern

- **Usage**: Data access abstraction
- **Implementation**: Repository classes that encapsulate database operations
- **Example Components**: EvidenceRepository, ThingsRepository

### Service Pattern

- **Usage**: Business logic encapsulation
- **Implementation**: Service classes that implement specific functionality
- **Example Components**: RecognitionService, SyncService

### Observer Pattern

- **Usage**: State change notifications
- **Implementation**: Combine framework for reactive programming
- **Example Components**: State publishers, subscribers in ViewModels

### Factory Pattern

- **Usage**: Object creation
- **Implementation**: Factory methods for creating complex objects
- **Example Components**: EvidenceTypeFactory, RecognitionModelFactory

## Component Relationships

### Core Data Flow

1. **UI Components** capture user input and display data
2. **ViewModels** process user actions and update state
3. **Services** implement business logic and interact with repositories
4. **Repositories** handle data persistence and retrieval
5. **Sync Services** manage data synchronization with cloud storage

### ML Processing Flow

1. **Camera Service** captures images/videos
2. **Recognition Service** processes media using ML models
3. **Results Processor** extracts and structures recognized information
4. **Evidence Creator** generates evidence records from processed data
5. **UI Components** display recognition results and allow user verification

### Synchronization Flow

1. **Local Database** stores all user data
2. **Sync Service** identifies changes to be synchronized
3. **B2/Bunny CDN Client** uploads/downloads files to/from cloud storage
4. **Conflict Resolution Service** handles synchronization conflicts
5. **Database Updater** applies synchronized changes to local database

## Module Dependencies

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Views    │────▶│ View Models │────▶│  Services   │
└─────────────┘     └─────────────┘     └─────────────┘
                          │                    │
                          ▼                    ▼
                    ┌─────────────┐     ┌─────────────┐
                    │   Models    │◀────│Repositories │
                    └─────────────┘     └─────────────┘
                                             │
                                             ▼
                                      ┌─────────────┐
                                      │  Database   │
                                      └─────────────┘
```
