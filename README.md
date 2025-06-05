# Record Thing

## Overview

A comprehensive solution for recording, recognizing, and organizing physical items using computer vision and machine learning. It presents the user with a iOS/Android/macOS app to record things and events in the world and organise the recordings so they can be used for various purposes.
Recorded things can be used to prove claims, be shared with other users, and be used to create a community showcase. As a user you can request a recording from another user.

Record Thing helps users:

- Scan and catalogue physical items
- Organize items by categories
- Collect evidence about items (receipts, photos, etc.)
- Manage requests related to items
- Make a recording based on a pre-defined workflow
- Share content from other apps (YouTube, web pages) into strategic focus areas
- Organize knowledge around strategic interests through the Thepia Strategist system

## Project Structure

The project consists of both client applications and backend tools:

- **iOS and macOS Apps** - Swift/SwiftUI applications in [apps/RecordThing](apps/RecordThing)
- **Android App** - TBD
- **Python Backend** - Data management, ML processing, and sync in [libs/record_thing](libs/record_thing)

## Technology Stack

- **Swift/SwiftUI**: Main iOS and macOS app implementation
- **Python**: Backend tools, database setup, and ML processing
- **SQLite/Blackbird**: Database with Blackbird as Swift ORM
- **[MLX](https://github.com/ml-explore/mlx)**: Apple's machine learning framework for Apple Silicon
- **[DINO v2](https://huggingface.co/mlx-vision/vit_small_patch14_518.dinov2-mlxim)**: Self-supervised learning model for computer vision
- **B2/Bunny CDN**: Asset synchronization and storage

## Getting Started

### Setting Up the Database

```bash
# Initialize a new database or view existing one
uv run -m record_thing.cli init-db

# Force reset an existing database
uv run -m record_thing.cli init-db --force

# Update database schema without losing data
uv run -m record_thing.cli update-db

# Create tables only (no sample data)
uv run -m record_thing.cli tables-db

# Populate database with sample data
uv run -m record_thing.cli populate-db

# Test database connection with verbose output
uv run -m record_thing.cli test-db -v
```

For more detailed CLI commands, see [CLI Documentation](docs/CLI.md).

Alternatively, open the Jupyter notebook: `docs/record-thing.ipynb`

### Sync with Server

The server storage is a Storage Bucket (Bunny CDN) that syncs with the local database and local recording files.

```bash
uv run buckia --config ./assets
uv run buckia sync --folder=13434535345
```

### Building the iOS/macOS App

iOS:

```bash
cd apps/RecordThing
xcodebuild -scheme "RecordThing iOS" -configuration Debug -derivedDataPath ./DerivedData -destination "platform=iOS Simulator,name=iPhone 14 Pro"
```

macOS:

```bash
cd apps/RecordThing
xcodebuild -scheme "RecordThing macOS" -configuration Debug -derivedDataPath ./DerivedData
```

### Swift Development Environment

```bash
brew install xcode-build-server xcbeautify swiftformat
```

### Python Environment Setup

Using pip:

```bash
uv run -m venv .venv
source .venv/bin/activate
pip install -e .
```

Using uv (faster):

```bash
uv venv
source .venv/bin/activate
uv pip install -e .
```

## Documentation

For more detailed information about specific components:

- [CLI Commands](docs/CLI.md) - Command-line interface documentation
- [Navigation](docs/navigation.md) - UI navigation and component structure
- [Database Schema](docs/DATABASE.md) - Database structure and relationships
- [Branding Guidelines](docs/BRANDING.md) - Visual identity specifications
- [QA Process](docs/QA.md) - Testing and quality assurance
- [Apple Enrollment](docs/apple_enrollment.md) - Apple Developer Program enrollment

## Architecture

The Record Thing ecosystem consists of these main components:

```
Record Thing Ecosystem
├── RecordThing App (Swift/SwiftUI) - iOS/macOS client
├── RecordLib Library (Python) - Core data management functionality
└── Backoffice Library (Python) - Server-side and admin tools
    └── Buckia - Synchronization with Storage Buckets
```

## Dataset

The project uses the ICDAR2019 SROIE dataset for receipt recognition:

- [ICDAR-2019-SROIE](https://github.com/zzzDavid/ICDAR-2019-SROIE)
- [Papers with Code: SROIE](https://paperswithcode.com/dataset/sroie)

## iOS Sharing Implementation

RecordThing includes an iOS Share Extension that allows users to share content from other apps directly into the app:

- **YouTube Video Sharing**: Share videos from the YouTube app into strategic focus areas
- **Web Content Sharing**: Share any web page from Safari or other browsers
- **Thepia Strategist**: Organize shared content around strategic interests and projects
- **Evidence Linking**: Connect shared content to physical items or strategic focus areas

For detailed implementation information, see [docs/SHARING_IMPLEMENTATION.md](docs/SHARING_IMPLEMENTATION.md).

## Services and Accounts

- Apple Developer (<apps@thepia.com>)
- together.ai for ImageGen

## License

See [LICENSE](LICENSE) for details.

### Auth prompt

I want to use keychain/keyring functionality on my website to authenticate users and protect access tokens and other secrets for accessing backend services. This should enable a single registration with touchid/faceid that can be used across apple devices for the same user. It should be possible to replicate the authentication approach in other contexts such as python cli or swiftui
