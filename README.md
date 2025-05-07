# Record Thing

A comprehensive solution for recording, recognizing, and organizing physical items using computer vision and machine learning.

## Overview

Record Thing helps users:

- Scan and catalogue physical items
- Organize items by categories
- Collect evidence about items (receipts, photos, etc.)
- Manage requests related to items

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
python -m libs.record_thing.db_setup
```

Alternatively, open the Jupyter notebook: `docs/record-thing.ipynb`

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

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e .
```

## Documentation

For more detailed information about specific components:

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

## Services and Accounts

- Apple Developer (apps@thepia.com)
- together.ai for ImageGen

## License

See [LICENSE](LICENSE) for details.
