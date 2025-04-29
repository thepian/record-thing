# Bunny.net Integration for RecordThing

This module provides integration with Bunny.net CDN for file storage and synchronization in the RecordThing application.

## Features

- Upload, download, and synchronize files with Bunny.net Storage
- Configure storage zones and pull zones
- Purge cache for updated assets
- Parallel file operations with progress tracking
- Support for both API key and password-based authentication
- Connection testing for both authentication methods
- Optional integration with `bunnycdnpython` package for enhanced reliability

## Authentication Methods

The module supports three types of authentication:

1. **API Key Authentication** - Used for API operations like listing, uploading, and deleting files
2. **Password Authentication** - Used for direct file access, which can be more convenient for client-side access
3. **Storage API Key with bunnycdnpython** - Uses the official Bunny.net Python client library

## Installation

### Basic Installation

```bash
# Basic installation
pip install requests pillow
```

### With bunnycdnpython Support

```bash
# Install with bunnycdnpython for enhanced integration
pip install requests pillow bunnycdnpython
```

## Configuration

### Basic Setup

```python
from libs.record_thing.bunny.config import BunnyConfig
from libs.record_thing.bunny.sync import BunnySync

# Create configuration
config = BunnyConfig(
    storage_zone_name="your-storage-zone",
    api_key="your-api-key",  # API access key from Bunny.net
    hostname="storage.bunnycdn.com",
    # Optional settings
    pull_zone_name="your-pull-zone",  # For cache purging
    storage_region="de",  # For specific region, leave empty for default
    cdn_url="https://your-pull-zone.b-cdn.net",  # If using a custom domain
    password="your-storage-password"  # For password-based access
)

# Create sync client
bunny_sync = BunnySync(config)
```

### Using bunnycdnpython Package

```python
# Configuration with bunnycdnpython package support
config = BunnyConfig(
    storage_zone_name="your-storage-zone",
    api_key="your-api-key",  # Still needed for operations not supported by bunnycdnpython
    hostname="storage.bunnycdn.com",
    storage_api_key="your-storage-api-key",  # Storage zone API key for bunnycdnpython
    # The use_bunnycdn_package flag will be automatically set to True when storage_api_key is provided
)

# Create sync client - will automatically use bunnycdnpython where possible
bunny_sync = BunnySync(config)
```

### Loading Configuration from File

```python
# Load from JSON config file
config = BunnyConfig.from_file("/path/to/bunny_config.json")

# Save configuration
config.save("/path/to/bunny_config.json")
```

## Usage Examples

### Testing Connections

All configured authentication methods are tested automatically when initializing the `BunnySync` client. You can also test them manually:

```python
# Test all authentication methods
results = bunny_sync.test_connection()
print(f"API Key authentication: {'Successful' if results['api_key'] else 'Failed'}")
print(f"Password authentication: {'Successful' if results['password'] else 'Failed or not configured'}")
print(f"bunnycdnpython: {'Successful' if results['bunnycdn_package'] else 'Failed or not configured'}")

# Test only API key authentication
results = bunny_sync.test_connection(test_password=False)
```

### Synchronizing Directory

```python
# Define a progress callback
def progress_callback(current, total, action, path):
    percent = int(current * 100 / total) if total > 0 else 0
    print(f"{action.capitalize()}: {current}/{total} ({percent}%) - {path}")

# Sync directory
results = bunny_sync.sync(
    local_path="./assets/cache",
    max_workers=5,  # Number of concurrent operations
    delete_orphaned=True,  # Delete files that don't exist locally
    progress_callback=progress_callback
)

print(f"Sync completed: {results}")
```

### Uploading a Single File

```python
success = bunny_sync._upload_file(
    local_path="./assets/cache/image.jpg",
    remote_path="images/image.jpg"
)

if success:
    print("Upload successful")
else:
    print("Upload failed")
```

### Downloading with API Key vs Password

```python
# Download using API key (default)
bunny_sync._download_file(
    remote_path="images/image.jpg",
    local_path="./assets/cache/image.jpg"
)

# Download using password authentication
bunny_sync._download_file(
    remote_path="images/image.jpg",
    local_path="./assets/cache/image.jpg",
    use_password=True
)
```

### Getting Public URLs

```python
# Get a standard public URL
public_url = bunny_sync.get_public_url("images/image.jpg")
print(f"Public URL: {public_url}")

# Get a password-authenticated URL
auth_url = bunny_sync.get_public_url("images/image.jpg", use_password=True)
print(f"Authenticated URL: {auth_url}")
```

### Purging Cache

```python
# Purge specific files
results = bunny_sync.purge_cache([
    "images/image1.jpg",
    "images/image2.jpg"
])

# Purge everything (requires pull_zone_name in config)
results = bunny_sync.purge_cache()
```

## API Key Types Explained

Bunny.net has different types of API keys that serve different purposes:

1. **Account API Key** - Used for account-level operations. This is set in the `api_key` parameter.
2. **Storage Zone Password** - Used for direct file access via HTTP Basic Auth. This is set in the `password` parameter.
3. **Storage Zone API Key** - Specific to a storage zone, used with the bunnycdnpython package. This is set in the `storage_api_key` parameter.

## Troubleshooting Connection Issues

If you encounter connection issues with Bunny.net:

1. **API Key Authentication Failures**:
   - Verify your API key is correct and active in the Bunny.net dashboard
   - Ensure your storage zone name is correct
   - Check if your API key has permissions for the storage zone

2. **Password Authentication Failures**:
   - Confirm the password is set correctly for the storage zone
   - Verify the storage zone name is correct
   - Check that password authentication is enabled for the storage zone

3. **bunnycdnpython Issues**:
   - Ensure the package is installed (`pip install bunnycdnpython`)
   - Verify your storage API key is correct for the specific storage zone
   - Check if the package is compatible with your Python version

The `test_connection()` method can help diagnose which authentication method is failing.

## Integration with BucketManager

To use Bunny.net with the existing BucketManager:

```python
from libs.record_thing.bucket_manager import BucketManager, BucketConfig

# Create a bucket manager with Bunny.net configuration
manager = BucketManager(
    db_path="record-thing.sqlite",
    primary_bucket=BucketConfig(
        url="https://storage.bunnycdn.com",
        api_key="your-api-key",
        bucket_type="bunny",  # Identify as a Bunny.net bucket
        bucket_name="your-storage-zone"
    )
)

# Sync the cache directory
manager.sync_cache_directory(max_workers=5)
```

## Configuration File Format

Here's an example of a Bunny.net configuration JSON file:

```json
{
    "storage_zone_name": "your-storage-zone",
    "api_key": "your-api-key",
    "hostname": "storage.bunnycdn.com",
    "pull_zone_name": "your-pull-zone",
    "storage_region": "de",
    "cdn_url": "https://your-pull-zone.b-cdn.net",
    "password": "your-storage-password",
    "storage_api_key": "your-storage-api-key",
    "use_bunnycdn_package": true
}
```

## Available Regions

Bunny.net storage zones are available in the following regions:

- Empty string: Default region (NY, USA)
- "de": Frankfurt, Germany
- "uk": London, United Kingdom 
- "sg": Singapore
- "sy": Sydney, Australia
- "la": Los Angeles, USA
- "ny": New York, USA
- "se": Stockholm, Sweden

## Storage URL Format

When using regional storage, Bunny.net uses this URL format:
- Default region: `https://storage.bunnycdn.com`
- Region-specific: `https://storage-{region}.bunnycdn.com` (e.g., `https://storage-de.bunnycdn.com`)

### Authentication Formats

- **API Key Authentication**: Uses the `AccessKey` HTTP header
- **Password Authentication**: Uses HTTP Basic Auth in the URL: `https://{storage-zone}:{password}@storage.bunnycdn.com`
- **Storage API Key**: Used internally by the bunnycdnpython package

## Error Handling

The BunnySync class includes comprehensive error handling and logging. All operations return detailed result objects with success status, counts, and error messages. 