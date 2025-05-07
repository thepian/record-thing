# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Record Thing is an app that helps users record, recognize, and organize "things" (physical items) using computer vision and machine learning. The app allows users to:

1. Scan and catalogue physical items
2. Organize items by categories
3. Collect evidence about items (e.g., receipts, photos)
4. Manage requests related to items

The project has both:

- iOS and macOS Swift applications (using SwiftUI)
- Python backend tools for data management, ML processing, and sync

## Technology Stack

- **Swift/SwiftUI**: Main iOS and macOS app implementation
- **Python**: Backend tools, database setup, and ML processing
- **SQLite/Blackbird**: Database with Blackbird as Swift ORM
- **MLX**: Apple's machine learning framework for Apple Silicon
- **DINO v2**: Self-supervised learning model for computer vision
- **B2/Bunny CDN**: Used for asset synchronization and storage

## Code Architecture

### Swift App Structure

- **apps/RecordThing**: Main iOS/macOS application
  - **Shared/**: Cross-platform code (iOS, macOS)
  - **iOS/**: iOS-specific code
  - **macOS/**: macOS-specific code
  - **Widgets/**: App widgets code
- **apps/libs/RecordLib**: Swift Package containing reusable components

### Python Backend Structure

- **libs/record_thing/**: Python package with core functionality
  - **db/**: Database schema and setup
  - **taxonomy/**: Product categorization
  - **b2sync/**: Backblaze B2 sync tools
  - **bunny/**: BunnyCDN integration
  - **gen/**: AI-assisted content generation

## Common Development Tasks

### Setting Up the Database

To set up the demo database for the App:

```bash
# From the root directory
uv run -m record_thing.cli init-db

# To force reset an existing database
uv run -m record_thing.cli init-db --force

# To test database connection with verbose output
uv run -m record_thing.cli test-db -v
```

### Building the iOS/macOS App

From the project directory:

```bash
cd apps/RecordThing
xcodebuild -scheme "RecordThing iOS" -configuration Debug -derivedDataPath ./DerivedData -destination "platform=iOS Simulator,name=iPhone 14 Pro"
```

For macOS:

```bash
cd apps/RecordThing
xcodebuild -scheme "RecordThing macOS" -configuration Debug -derivedDataPath ./DerivedData
```

### Swift Development Environment

Required tools:

```bash
brew install xcode-build-server xcbeautify swiftformat
```

### Python Environment Setup

```bash
# Create and activate virtual environment
uv run -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -e .
```

### Running Tests

Python tests:

```bash
uv run -m unittest discover libs/record_thing/tests
```

Swift tests:

```bash
cd apps/RecordThing
xcodebuild test -scheme "RecordThing iOS" -destination "platform=iOS Simulator,name=iPhone 14 Pro"
```

## System Architecture Overview

The Record Thing ecosystem consists of these main components:

```
Record Thing Ecosystem
├── RecordThing App (Swift/SwiftUI) - iOS/macOS client
├── RecordLib Library (Python) - Core data management functionality
└── Backoffice Library (Python) - Server-side and admin tools
    └── Buckia - Synchronization with Storage Buckets
```

### Key Components

#### Database Structure

The SQLite database includes tables for:

- Universe: Sets of functionality for the App
- Things: Physical items recorded by the user
- Evidence: Records that are evidence of things
- Requests: Evidence gathering actions for the user to complete
- Accounts: User accounts in the system
- Owners: The account ID used to create new data on this node
- Products, Brands, Companies: Reference data for item identification
- ProductType/DocumentType: Standard categories with identifiers

SQL table definitions are in `libs/record_thing/db/*.sql`.
Table descriptions are in `docs/DATABASE.md`.

#### SwiftUI Views

The app uses a combination of navigation types:

- AppSplitView: Main navigation container
- ThingsView/EvidenceTypeView: Main content views

#### Model Layer

- Uses Blackbird as ORM over SQLite
- Models are defined as Swift structs conforming to BlackbirdModel
- Automatic schema migration is handled by Blackbird

#### Storage Bucket Structure

1. **Common Storage Bucket**

   - `<demo-team-id>/`: Demo content folder
   - `<user-id>/`: Common user folders

2. **Premium Storage Bucket**

   - `<demo-team-id>/`: Demo content folder
   - `<user-id>/`: Premium user folders

3. **Enterprise Storage Bucket**
   - `<demo-team-id>/`: Demo content folder
   - `<user-id>/`: Enterprise user folders

## Important Notes

1. The project is exploring the use of DINO v2 for computer vision
2. Database creation and migration is handled by Python scripts
3. The app uses a standard SQLite database with a copy in the app bundle for initialization
4. Image assets are synced between local storage and CDN
5. MLX is used for model training and serving on Apple Silicon
6. Tables use SQLite constraints that are compatible with Blackbird in Swift (no TIMESTAMP, DATETIME, or TIME fields)

## Code Generation Guidelines

### General Principles

1. **Context-Aware Generation**: Always specify which component (App, RecordLib, or Backoffice) the code is for.

2. **Consistent Coding Styles**:

   - Swift: Follow Apple's Swift style guide with SwiftUI best practices
   - Python: Use type hints, follow PEP 8, and use black code formatting

3. **Type Safety**:

   - Swift: Use strong typing and SwiftUI property wrappers appropriately
   - Python: Use type hints with mypy compatibility

4. **Error Handling**:
   - Swift: Use Swift's Result type or throws for error propagation
   - Python: Use explicit exception handling with custom exceptions

### RecordThing App Code (Swift/SwiftUI)

When requesting Swift code, use this format:

```
# Request: [Brief description of what you need]
Component: RecordThing App (Swift)
Context: [Relevant context about what the code should accomplish]
Integration Points: [Any existing components this should work with]
Special Requirements: [Any specific requirements]
```

Example Swift View Component:

```swift
import SwiftUI
import Blackbird

struct ThingListView: View {
    @Environment(\.blackbirdDatabase) var db
    @BlackbirdLiveModels var things: [Thing]

    init() {
        self._things = BlackbirdLiveModels(
            database: db,
            tableName: "things",
            where: "account_id = ?",
            whereArgs: [AppState.shared.accountId],
            returnType: Thing.self
        )
    }

    var body: some View {
        List(things) { thing in
            ThingRowView(thing: thing)
        }
        .navigationTitle("My Things")
    }
}
```

### RecordLib Library Code (Python)

When requesting RecordLib Python code, use this format:

```
# Request: [Brief description of what you need]
Component: RecordLib Library (Python)
Context: [Relevant context about what the code should accomplish]
Integration Points: [Any existing components this should work with]
Special Requirements: [Any specific requirements]
```

Example Python RecordLib Code:

```python
from typing import Dict, List, Optional
import sqlite3
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

def import_product_data(
    conn: sqlite3.Connection,
    product_data: Dict[str, any],
    source: str = "api"
) -> str:
    """
    Import product data into the database.

    Args:
        conn: SQLite database connection
        product_data: Dictionary containing product information
        source: Source of the product data

    Returns:
        Newly created product ID
    """
    cursor = conn.cursor()

    try:
        # Generate a new KSUID for the product
        from ..commons import create_uid
        product_id = create_uid()

        # Insert product record
        cursor.execute("""
            INSERT INTO product (
                id, name, brand_id, category,
                description, official_url, source
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            product_id,
            product_data.get("name", ""),
            product_data.get("brand_id", ""),
            product_data.get("category", ""),
            product_data.get("description", ""),
            product_data.get("url", ""),
            source
        ))

        conn.commit()
        logger.info(f"Imported product {product_id}: {product_data.get('name', '')}")
        return product_id

    except Exception as e:
        conn.rollback()
        logger.error(f"Error importing product: {e}")
        raise
```

### Backoffice Library Code (Python)

The PRD for the Backoffice library and CLI is in `docs/BACKOFFICE_PRD.md`.

The CLI is a command-line tool for managing the backoffice system, including team management, user data synchronization, and bucket configuration.
When interacting with the Cloud Storage, it will use keyring biometric authentication to access access tokens. This means that the user will be prompted to authenticate using their biometric data (e.g., fingerprint, face ID) when accessing the storage.
See [SECURITY.md](docs/SECURITY.md) for more details.

When requesting Backoffice Python code, use this format:

```
# Request: [Brief description of what you need]
Component: Backoffice Library (Python)
Context: [Relevant context about what the code should accomplish]
Integration Points: [Any existing components this should work with]
Special Requirements: [Any specific requirements]
```

Example Python Backoffice Code:

```python
import os
from typing import Dict, List, Optional
from pathlib import Path
import logging
from buckia import BuckiaClient, BucketConfig

logger = logging.getLogger(__name__)

class TeamManager:
    """Manages team operations in the backoffice system."""

    def __init__(self, base_path: Path):
        self.base_path = base_path
        self.config_path = base_path / "configs"

    def create_team(self, team_id: str, team_name: str, bucket_type: str = "common") -> Dict[str, any]:
        """
        Create a new team with associated bucket configuration.

        Args:
            team_id: KSUID for the new team
            team_name: Descriptive name for the team
            bucket_type: Type of bucket (common, premium, enterprise)

        Returns:
            Dictionary containing team information
        """
        # Create team directory structure
        team_dir = self.base_path / "teams" / team_id
        team_dir.mkdir(parents=True, exist_ok=True)

        # Create bucket configuration
        bucket_config = self._create_bucket_config(team_id, bucket_type)

        # Save configuration
        config_file = self.config_path / f"{team_id}.yaml"
        with open(config_file, "w") as f:
            f.write(bucket_config)

        # Return team info
        return {
            "team_id": team_id,
            "team_name": team_name,
            "bucket_type": bucket_type,
            "config_file": str(config_file)
        }

    def _create_bucket_config(self, team_id: str, bucket_type: str) -> str:
        """Create a bucket configuration YAML for the team."""
        if bucket_type == "common":
            bucket_name = "record-thing-common"
        elif bucket_type == "premium":
            bucket_name = "record-thing-premium"
        else:
            bucket_name = f"record-thing-enterprise-{team_id}"

        # Create YAML configuration
        config = f"""
{bucket_name}:
  provider: bunny
  bucket_name: {bucket_name}
  domain: storage.bunnycdn.com
  region: eu-central

  # Folders to sync (top-level directories in the bucket)
  folders:
    - {team_id}

  # Sync settings
  paths:
    - teams/{team_id}/ # Will receive incoming changes from the bucket
  delete_orphaned: true
  max_workers: 8

  # Advanced settings
  checksum_algorithm: sha256
  conflict_resolution: local_wins
"""
        return config
```

### Buckia Integration Code (Python)

When requesting Buckia integration code, use this format:

```
# Request: [Brief description of what you need]
Component: Buckia Integration (Python)
Context: [Relevant context about what the code should accomplish]
Integration Points: [Any existing components this should work with]
Special Requirements: [Any specific requirements]
```

Example Buckia Integration Code:

```python
from buckia import BuckiaClient, BucketConfig
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

def sync_user_data(user_id: str, team_id: str, local_base_path: Path) -> dict:
    """
    Synchronize user data with the appropriate storage bucket.

    Args:
        user_id: User's KSUID
        team_id: Team's KSUID
        local_base_path: Base path for local files

    Returns:
        Dictionary with sync statistics
    """
    # Determine bucket configuration based on team
    from record_thing.sync.bucket import get_bucket_config
    config = get_bucket_config(team_id)

    # Set up client
    client = BuckiaClient(config)

    # Determine local path for user
    user_path = local_base_path / "users" / user_id
    user_path.mkdir(parents=True, exist_ok=True)

    # Sync user data
    logger.info(f"Syncing data for user {user_id} in team {team_id}")
    result = client.sync(
        local_path=str(user_path),
        sync_paths=[
            "database/",  # SQLite database
            "assets/"     # User assets (images, etc.)
        ],
        delete_orphaned=True,
        max_workers=4
    )

    logger.info(f"Sync complete: {result.uploaded} uploaded, {result.downloaded} downloaded")

    return {
        "user_id": user_id,
        "team_id": team_id,
        "uploaded": result.uploaded,
        "downloaded": result.downloaded,
        "deleted": result.deleted,
        "errors": result.errors
    }
```

## Cross-Component Integration

When generating code that spans multiple components, specify the relationships explicitly:

```
# Request: [Brief description of what you need]
Components:
  - RecordThing App (Swift): [What this component will do]
  - RecordLib Library (Python): [What this component will do]
Integration Flow: [How these components interact]
```

## Testing Guidelines

Include appropriate testing code when generating implementation:

### Swift Testing (XCTest)

```swift
import XCTest
@testable import RecordThing

final class ThingManagerTests: XCTestCase {
    var sut: ThingManager!

    override func setUp() {
        super.setUp()
        sut = ThingManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testCreateThing() {
        // Given
        let thingData = ThingData(name: "Test Item", category: "Electronics")

        // When
        let result = sut.createThing(thingData)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Test Item")
    }
}
```

### Python Testing (pytest)

```python
import pytest
import sqlite3
from pathlib import Path

from record_thing.db.schema import init_db_tables

def test_import_product_data():
    # Setup
    conn = sqlite3.connect(":memory:")
    init_db_tables(conn)

    # Test data
    product_data = {
        "name": "Test Product",
        "brand_id": "test_brand_id",
        "category": "Electronics"
    }

    # Execute
    from record_thing.db.product import import_product_data
    product_id = import_product_data(conn, product_data, source="test")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM product WHERE id = ?", (product_id,))
    result = cursor.fetchone()

    # Assert
    assert result is not None
    assert result[1] == "Test Product"  # name
    assert result[4] == "Electronics"   # category
```

## Documentation Guidelines

Add appropriate documentation with generated code:

1. **Function/Method Documentation**:

   - Python: Use Google-style docstrings
   - Swift: Use standard Swift documentation comments

2. **Class Documentation**:

   - Include purpose, usage examples, and key properties/methods

3. **Module Documentation**:
   - Add module-level documentation explaining the component's role

## Best Practices for Requesting Code Generation

1. **Be Specific About Context**: Provide relevant database schema details, existing functionality, and integration points

2. **Chunk Appropriately**: Request smaller, focused components rather than large monolithic systems

3. **Specify Requirements Clearly**: Include error handling, validation, and edge cases to consider

4. **Reference Existing Patterns**: Mention similar existing code to maintain consistency

5. **Iterate with Feedback**: Use initial code generation as a starting point and refine through follow-up requests
