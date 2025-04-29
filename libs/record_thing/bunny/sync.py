"""
Main synchronization logic for Bunny.net CDN
"""

import os
import json
import hashlib
import requests
import mimetypes
from typing import Set, Dict, List, Optional, Tuple, Any
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import logging
from .config import BunnyConfig

# Import bunnycdnpython if available
try:
    # Equivalent to: from BunnyCDN.Storage import Storage
    from .Storage import Storage
    # Equivalent to: from BunnyCDN.CDN import CDN
    from .CDN import CDN
    BUNNY_PACKAGE_AVAILABLE = True
except ImportError:
    BUNNY_PACKAGE_AVAILABLE = False

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('bunny_sync')

class BunnySync:
    """Synchronize files with Bunny.net Storage"""
    
    def __init__(self, config: BunnyConfig):
        """
        Initialize BunnySync with configuration
        
        Args:
            config: BunnyConfig instance with Bunny.net credentials
        """
        self.config = config
        self.session = requests.Session()
        self.session.headers.update({
            'AccessKey': config.api_key,
            'Accept': 'application/json'
        })
        
        # Initialize bunnycdnpython client if requested and available
        self.bunny_client = None
        if config.use_bunnycdn_package:
            if not BUNNY_PACKAGE_AVAILABLE:
                logger.warning("bunnycdnpython package not installed. Falling back to direct API calls.")
            elif not config.storage_api_key:
                logger.warning("storage_api_key not provided. Falling back to direct API calls.")
            else:
                try:
                    # Initialize Storage with the correct parameter order (api_key, storage_zone, storage_zone_region)
                    # Explicitly pass None for storage_zone_region if it's empty to avoid index errors
                    storage_region = config.storage_region if config.storage_region else ""
                    self.bunny_client = Storage(
                        config.storage_api_key,
                        config.storage_zone_name,
                        storage_region
                    )
                    logger.info("Using bunnycdnpython package for storage operations")
                except Exception as e:
                    logger.error(f"Failed to initialize bunnycdnpython client: {str(e)}")
                    self.bunny_client = None
        
        # Test API key connection
        # self._test_api_connection()
        
        # Test password connection if password is provided
        if config.password:
            self._test_password_connection()
        
    def _test_api_connection(self) -> None:
        """Test connection to Bunny.net API using API key"""
        try:
            if self.bunny_client:
                # Test using bunnycdnpython client
                try:
                    self.bunny_client.GetStoragedObjectsList()
                    logger.info("Successfully connected to Bunny.net API using bunnycdnpython")
                    return
                except Exception as e:
                    raise ValueError(f"bunnycdnpython connection error: {str(e)}")
            
            # Test using direct API call
            url = f"{self.config.storage_api_url}/{self.config.storage_zone_name}/"
            response = self.session.get(url)
            
            if response.status_code == 401:
                raise ValueError("Authentication failed: Invalid API key")
            elif response.status_code == 404:
                raise ValueError(f"Storage zone '{self.config.storage_zone_name}' not found")
            elif response.status_code != 200:
                raise ValueError(f"Failed to connect to Bunny.net: {response.status_code} {response.text}")
            
            logger.info("Successfully connected to Bunny.net API using API key")
                
        except requests.RequestException as e:
            raise ValueError(f"Connection error: {str(e)}")
    
    def _test_password_connection(self) -> None:
        """Test connection to Bunny.net using password authentication"""
        if not self.config.password:
            logger.warning("Cannot test password connection: No password provided")
            return
            
        try:
            # Test by requesting the root directory with password auth
            url = f"{self.config.authenticated_cdn_endpoint}/"
            
            # Don't use the session with API key, create a direct request
            response = requests.get(url, timeout=10)
            
            if response.status_code == 401:
                raise ValueError("Password authentication failed: Invalid password or storage zone name")
            elif response.status_code == 404:
                # 404 might be acceptable if the root directory is empty
                logger.info("Successfully authenticated with password (root directory empty)")
                return
            elif response.status_code != 200:
                raise ValueError(f"Failed to connect with password: {response.status_code} {response.text}")
                
            logger.info("Successfully connected to Bunny.net using password authentication")
                
        except requests.RequestException as e:
            logger.error(f"Password connection error: {str(e)}")
            raise ValueError(f"Password connection error: {str(e)}")
    
    def test_connection(self, test_password: bool = True) -> Dict[str, bool]:
        """
        Test connection to Bunny.net using available authentication methods
        
        Args:
            test_password: Whether to test password authentication
            
        Returns:
            Dict with results for each authentication method
        """
        results = {
            'api_key': False,
            'password': False if self.config.password and test_password else None,
            'bunnycdn_package': False if self.bunny_client else None
        }
        
        # Test API key connection
        try:
            self._test_api_connection()
            results['api_key'] = True
        except Exception as e:
            logger.error(f"API key connection test failed: {str(e)}")
            
        # Test password connection if configured
        if self.config.password and test_password:
            try:
                self._test_password_connection()
                results['password'] = True
            except Exception as e:
                logger.error(f"Password connection test failed: {str(e)}")
                
        # Test bunnycdnpython connection if configured
        if self.bunny_client:
            try:
                self.bunny_client.GetStoragedObjectsList()
                results['bunnycdn_package'] = True
            except Exception as e:
                logger.error(f"bunnycdnpython connection test failed: {str(e)}")
                
        return results
    
    def _calculate_checksum(self, filepath: str) -> str:
        """Calculate SHA-256 checksum of a file"""
        sha256_hash = hashlib.sha256()
        with open(filepath, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256_hash.update(chunk)
        return sha256_hash.hexdigest()
    
    def _get_content_type(self, filepath: str) -> str:
        """Get the content type of a file"""
        content_type, _ = mimetypes.guess_type(filepath)
        return content_type or 'application/octet-stream'
    
    def _get_local_files(self, local_path: Path|str) -> Dict[str, str]:
        """
        Get all files and their checksums from local directory
        
        Args:
            local_path: Root path to scan for files
            
        Returns:
            Dict mapping relative file paths to checksums
        """
        local_files = {}
        # Use Path for better cross-platform path handling
        local_path_obj = Path(local_path)
        
        for root, _, files in os.walk(local_path):
            for file in files:
                full_path = os.path.join(root, file)
                relative_path = os.path.relpath(full_path, local_path)
                # Use forward slashes for paths (Bunny.net convention)
                relative_path = relative_path.replace('\\', '/')
                local_files[relative_path] = self._calculate_checksum(full_path)
                
        return local_files
    
    def _get_remote_files(self, path: Path|str = None) -> Dict[str, Dict[str, Any]]:
        """
        Get all files and their metadata from Bunny.net storage
        
        Args:
            path: Remote directory path to list
            
        Returns:
            Dict mapping relative file paths to file metadata
        """
        remote_files = {}
        
        # Ensure path is a string and properly formatted
        if path is not None:
            path = str(path).strip()
        
        # Use bunnycdnpython if available
        if self.bunny_client:
            try:
                # Handle potential empty string issues by using a try-except block
                try:
                    files = self.bunny_client.GetStoragedObjectsList(path)
                    
                    # Fix: Proper handling for None values in files list
                    if files is None:
                        logger.warning(f"GetStoragedObjectsList returned None for path '{path}'")
                        files = []
                        
                    for item in files:
                        # Skip None items in the list
                        if item is None:
                            continue
                        
                        # Fix: Handle items that are strings (not dictionaries)
                        if isinstance(item, str):
                            # For string items, create a simple metadata dict
                            is_dir = item.endswith('/')
                            object_name = item.rstrip('/')
                            
                            if is_dir:
                                # Recursively get files from subdirectory
                                subdir_path = f"{path}/{object_name}" if path else object_name
                                subdirectory_files = self._get_remote_files(subdir_path)
                                remote_files.update(subdirectory_files)
                            else:
                                file_path = f"{path}/{object_name}" if path else object_name
                                # Create basic metadata from the string
                                remote_files[file_path] = {
                                    "ObjectName": object_name,
                                    "IsDirectory": False,
                                    "Path": file_path
                                }
                        else:
                            # Handle dictionary items - now checking for both ObjectName and Folder_Name
                            # Get the name of the object/folder
                            object_name = None
                            is_directory = False
                            
                            # Try different field names that might contain the name
                            if "ObjectName" in item:
                                object_name = item["ObjectName"]
                                is_directory = item.get("IsDirectory", False)
                            elif "Folder_Name" in item:
                                object_name = item["Folder_Name"]
                                is_directory = True  # If it has Folder_Name, it's a directory
                            elif "File_Name" in item:
                                object_name = item["File_Name"]
                                is_directory = False
                            
                            if object_name:
                                if is_directory:
                                    # Recursively get files from subdirectory
                                    subdir_path = f"{path}/{object_name}" if path else object_name
                                    subdirectory_files = self._get_remote_files(subdir_path)
                                    remote_files.update(subdirectory_files)
                                else:
                                    file_path = f"{path}/{object_name}" if path else object_name
                                    remote_files[file_path] = item
                            else:
                                logger.warning(f"Skipping item with unknown name format: {item}")
                except Exception as e:
                    import traceback
                    logger.error(f"bunnycdnpython GetStoragedObjectsList error with path '{path}': {str(e)}")
                    logger.error(f"Stack trace: {traceback.format_exc()}")
                    # We'll fall back to direct API below
                else:
                    return remote_files
            except Exception as e:
                logger.error(f"Error listing files with bunnycdnpython: {str(e)}")
                # Fall back to direct API
        
        # Use direct API calls
        # Ensure no double slashes in URL
        clean_path = path.strip("/") if path else ""
        url_path = f"{clean_path}/" if clean_path else ""
        url = f"{self.config.storage_api_url}/{self.config.storage_zone_name}/{url_path}"
        
        try:
            response = self.session.get(url)
            
            if response.status_code != 200:
                logger.error(f"Failed to list remote files: {response.status_code} {response.text}")
                return remote_files
                
            items = response.json()
            
            for item in items:
                if item is None:
                    continue
                
                # Handle dictionary items - checking for both ObjectName and Folder_Name
                # Get the name of the object/folder
                object_name = None
                is_directory = False
                
                # Try different field names that might contain the name
                if "ObjectName" in item:
                    object_name = item["ObjectName"]
                    is_directory = item.get("IsDirectory", False)
                elif "Folder_Name" in item:
                    object_name = item["Folder_Name"]
                    is_directory = True  # If it has Folder_Name, it's a directory
                elif "File_Name" in item:
                    object_name = item["File_Name"]
                    is_directory = False
                
                if object_name:
                    if is_directory:
                        # Recursively get files from subdirectory
                        subdir_path = f"{path}/{object_name}" if path else object_name
                        subdirectory_files = self._get_remote_files(subdir_path)
                        remote_files.update(subdirectory_files)
                    else:
                        file_path = f"{path}/{object_name}" if path else object_name
                        remote_files[file_path] = item
                else:
                    logger.warning(f"Skipping item with unknown name format: {item}")
                    
        except requests.RequestException as e:
            logger.error(f"Error listing remote files: {str(e)}")
            
        except json.JSONDecodeError:
            logger.error("Invalid JSON response when listing remote files")
            
        return remote_files
    
    def _upload_file(self, local_file_path: str, remote_path: str) -> bool:
        """
        Upload a single file to Bunny.net Storage
        
        Args:
            local_file_path: Path to local file (absolute path)
            remote_path: Remote path for the file (relative path without leading slash)
            
        Returns:
            True if upload was successful, False otherwise
        """
        # Check if file exists
        if not os.path.exists(local_file_path):
            logger.error(f"Local file not found: {local_file_path}")
            return False
            
        # Use bunnycdnpython if available
        if self.bunny_client:
            try:
                # Extract filename and directory path for PutFile
                file_name = os.path.basename(local_file_path)
                local_directory = os.path.dirname(local_file_path)
                
                # The remote_path parameter in PutFile should not have a leading slash
                storage_path = remote_path.lstrip('/')
                
                # Call PutFile with the correct parameter order based on bunnycdnpython API
                self.bunny_client.PutFile(file_name, storage_path, local_directory)
                logger.info(f"Successfully uploaded with bunnycdnpython: {remote_path}")
                return True
            except Exception as e:
                logger.error(f"Error uploading with bunnycdnpython: {str(e)}")
                # Fall back to direct API
        
        # Use direct API calls
        url = f"{self.config.storage_api_url}/{self.config.storage_zone_name}/{remote_path}"
        content_type = self._get_content_type(local_file_path)
        
        try:
            with open(local_file_path, 'rb') as file:
                headers = {'Content-Type': content_type}
                response = self.session.put(url, data=file, headers=headers)
                
            if response.status_code in (200, 201):
                logger.info(f"Successfully uploaded: {remote_path}")
                return True
            else:
                logger.error(f"Failed to upload {remote_path}: {response.status_code} {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Error uploading {remote_path}: {str(e)}")
            return False
    
    def _delete_file(self, remote_path: str) -> bool:
        """
        Delete a single file from Bunny.net Storage
        
        Args:
            remote_path: Remote path of file to delete
            
        Returns:
            True if deletion was successful, False otherwise
        """
        # Use bunnycdnpython if available
        if self.bunny_client:
            try:
                self.bunny_client.DeleteFile(remote_path)
                logger.info(f"Successfully deleted with bunnycdnpython: {remote_path}")
                return True
            except Exception as e:
                logger.error(f"Error deleting with bunnycdnpython: {str(e)}")
                # Fall back to direct API
        
        # Use direct API calls
        url = f"{self.config.storage_api_url}/{self.config.storage_zone_name}/{remote_path}"
        
        try:
            response = self.session.delete(url)
            
            if response.status_code in (200, 204):
                logger.info(f"Successfully deleted: {remote_path}")
                return True
            else:
                logger.error(f"Failed to delete {remote_path}: {response.status_code} {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Error deleting {remote_path}: {str(e)}")
            return False
    
    def _download_file(self, remote_path: str, local_file_path: str, use_password: bool = False) -> bool:
        """
        Download a single file from Bunny.net Storage
        
        Args:
            remote_path: Remote path of file
            local_path: Local path to save file
            use_password: Whether to use password authentication instead of API key
            
        Returns:
            True if download was successful, False otherwise
        """
        # Use bunnycdnpython if available and not using password auth
        if self.bunny_client and not use_password:
            try:
                # Create directory if it doesn't exist
                os.makedirs(os.path.dirname(local_file_path), exist_ok=True)
                
                self.bunny_client.DownloadFile(remote_path, local_file_path)
                logger.info(f"Successfully downloaded with bunnycdnpython: {remote_path}")
                return True
            except Exception as e:
                logger.error(f"Error downloading with bunnycdnpython: {str(e)}")
                # Fall back to direct API
        
        if use_password and not self.config.password:
            logger.error("Password authentication requested but no password configured")
            return False
            
        if use_password:
            # Use password authentication
            url = f"{self.config.authenticated_cdn_endpoint}/{remote_path}"
            headers = {}  # No API key needed, basic auth is in URL
        else:
            # Use API key authentication
            url = f"{self.config.storage_api_url}/{self.config.storage_zone_name}/{remote_path}"
            headers = {'AccessKey': self.config.api_key}
        
        try:
            # Create directory if it doesn't exist
            os.makedirs(os.path.dirname(local_file_path), exist_ok=True)
            
            if use_password:
                # With password auth we use a direct request, not the self.session
                response = requests.get(url, headers=headers, stream=True)
            else:
                response = self.session.get(url, stream=True)
            
            if response.status_code != 200:
                logger.error(f"Failed to download {remote_path}: {response.status_code} {response.text}")
                return False
                
            with open(local_file_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
                    
            logger.info(f"Successfully downloaded: {remote_path}")
            return True
            
        except Exception as e:
            logger.error(f"Error downloading {remote_path}: {str(e)}")
            return False
            
    def get_public_url(self, remote_path: str, use_password: bool = False) -> str:
        """
        Get a public URL for a file in storage
        
        Args:
            remote_path: Path to the file in storage
            use_password: Whether to include password authentication in the URL
            
        Returns:
            URL to access the file
        """
        if use_password and self.config.password:
            # Use password-authenticated URL
            return f"{self.config.authenticated_cdn_endpoint}/{remote_path}"
        elif self.config.cdn_url:
            # Use CDN URL if configured
            return f"{self.config.cdn_url}/{remote_path}"
        else:
            # Use standard storage URL
            return f"https://{self.config.storage_zone_name}.{self.config.hostname}/{remote_path}"
    
    def sync(
        self, 
        local_path: Path|str, 
        max_workers: int = 4, 
        delete_orphaned: bool = False,
        include_pattern: Optional[str] = None,
        exclude_pattern: Optional[str] = None,
        dry_run: bool = False,
        progress_callback: Optional[callable] = None,
        cache_dir: Optional[Path|str] = None,
        sync_paths: Optional[List[str]] = None,
        write_protected_paths: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Synchronize local directory with Bunny.net storage
        
        Args:
            local_path: Path to local directory of the synced tree(Path)
            max_workers: Maximum number of concurrent operations
            delete_orphaned: Whether to delete files on CDN that don't exist locally
            include_pattern: Regex pattern for files to include
            exclude_pattern: Regex pattern for files to exclude
            dry_run: If True, only report what would be done without making changes
            progress_callback: Callback function for reporting progress
            cache_dir: Directory for local file cache that maps into the local tree
            sync_paths: Specific files/directories to sync (relative to local_path)
            write_protected_paths: Local paths that should not be modified by server changes
            
        Returns:
            Dict with synchronization results
        """
        if not os.path.isdir(local_path):
            raise NotADirectoryError(f"Local path does not exist: {local_path}")
            
        # Normalize paths
        local_path = Path(local_path)
        if cache_dir:
            cache_dir = Path(cache_dir)
            if not cache_dir.is_dir():
                raise NotADirectoryError(f"Cache directory does not exist: {cache_dir}")
        
        # Normalize write protected paths
        protected_patterns = []
        if write_protected_paths:
            protected_patterns = [str(Path(p)) for p in write_protected_paths]
            
        results = {
            'success': True,
            'uploaded': 0,
            'downloaded': 0,
            'deleted': 0,
            'failed': 0,
            'unchanged': 0,
            'errors': [],
            'protected_skipped': 0,
            'cached': 0
        }
        
        # First handle cache directory if specified
        if cache_dir and not dry_run:
            logger.info(f"Processing cache directory: {cache_dir}")
            cached_files = 0
            
            for root, _, files in os.walk(cache_dir):
                for file in files:
                    cache_file_path = Path(root) / file
                    relative_path = cache_file_path.relative_to(cache_dir)
                    target_path = local_path / relative_path
                    
                    # Skip if target is in write protected paths
                    if protected_patterns and any(str(target_path).startswith(p) for p in protected_patterns):
                        logger.debug(f"Skipping write-protected cached file: {relative_path}")
                        results['protected_skipped'] += 1
                        continue
                    
                    if not target_path.exists() or self._calculate_checksum(str(cache_file_path)) != self._calculate_checksum(str(target_path)):
                        # Create target directory if it doesn't exist
                        target_path.parent.mkdir(parents=True, exist_ok=True)
                        
                        # Copy file from cache to local path
                        import shutil
                        shutil.copy2(cache_file_path, target_path)
                        cached_files += 1
                        logger.debug(f"Copied cached file: {relative_path}")
            
            results['cached'] = cached_files
            logger.info(f"Copied {cached_files} files from cache directory")
        
        logger.info(f"Scanning local directory: {local_path}")
        if sync_paths:
            logger.info(f"Limiting sync to {len(sync_paths)} specific paths")
            # Only get files within specified paths
            local_files = {}
            for sync_path in sync_paths:
                sync_path_full = Path(local_path) / sync_path
                if sync_path_full.is_file():
                    # Single file
                    relative_path = os.path.relpath(sync_path_full, local_path)
                    relative_path = relative_path.replace('\\', '/')
                    local_files[relative_path] = self._calculate_checksum(str(sync_path_full))
                elif sync_path_full.is_dir():
                    # Directory - get all files within
                    for root, _, files in os.walk(sync_path_full):
                        for file in files:
                            full_path = os.path.join(root, file)
                            relative_path = os.path.relpath(full_path, local_path)
                            relative_path = relative_path.replace('\\', '/')
                            local_files[relative_path] = self._calculate_checksum(full_path)
                else:
                    logger.warning(f"Sync path not found: {sync_path}")
        else:
            # Get all files in local directory
            local_files = self._get_local_files(local_path)
        
        logger.info("Scanning remote storage...")
        remote_files = self._get_remote_files()
        
        # Find files to upload (new or modified)
        to_upload = []
        for relative_path, local_checksum in local_files.items():
            if relative_path not in remote_files:
                # New file
                to_upload.append(relative_path)
                logger.debug(f"New file to upload: {relative_path}")
            elif remote_files[relative_path].get('Checksum') != local_checksum:
                # Modified file
                to_upload.append(relative_path)
                logger.debug(f"Modified file to upload: {relative_path}")
            else:
                results['unchanged'] += 1
                
        # Find orphaned files to delete - only within sync_paths if specified
        to_delete = []
        if delete_orphaned:
            for remote_path in remote_files:
                if remote_path not in local_files:
                    # If sync_paths is specified, only delete files within those paths
                    if sync_paths:
                        if any(remote_path.startswith(str(p).replace('\\', '/')) for p in sync_paths):
                            to_delete.append(remote_path)
                            logger.debug(f"Orphaned file to delete: {remote_path}")
                    else:
                        to_delete.append(remote_path)
                        logger.debug(f"Orphaned file to delete: {remote_path}")
        
        # Find files to download (files that are newer on the server) - not including write-protected paths
        to_download = []
        if sync_paths and not all(p.startswith("!") for p in sync_paths):  # Skip if all paths are exclude patterns
            for remote_path, remote_data in remote_files.items():
                # Skip if this file is in write-protected paths
                target_path = os.path.join(local_path, remote_path)
                if protected_patterns and any(target_path.startswith(p) for p in protected_patterns):
                    logger.debug(f"Skipping write-protected file: {remote_path}")
                    results['protected_skipped'] += 1
                    continue
                    
                # Check if within sync_paths
                if sync_paths and not any(remote_path.startswith(str(p).replace('\\', '/')) for p in sync_paths):
                    continue
                    
                # If file doesn't exist locally or is different, download it
                if remote_path not in local_files:
                    to_download.append(remote_path)
                    logger.debug(f"New file to download: {remote_path}")
        
        # Report what would be done in dry run mode
        if dry_run:
            logger.info(f"DRY RUN: Would upload {len(to_upload)} files")
            if delete_orphaned:
                logger.info(f"DRY RUN: Would delete {len(to_delete)} files")
            logger.info(f"DRY RUN: Would download {len(to_download)} files")
            logger.info(f"DRY RUN: Would leave {results['unchanged']} files unchanged")
            logger.info(f"DRY RUN: Would skip {results['protected_skipped']} write-protected files")
            return results
        
        # Process uploads in parallel
        if to_upload:
            logger.info(f"Uploading {len(to_upload)} files...")
            with ThreadPoolExecutor(max_workers=max_workers) as executor:
                upload_tasks = []
                
                for i, relative_path in enumerate(to_upload):
                    # Properly join paths to ensure file paths are relative to local_path
                    local_file_path = os.path.join(local_path, relative_path)
                    task = executor.submit(self._upload_file, local_file_path, relative_path)
                    upload_tasks.append((task, relative_path))
                    
                    if progress_callback:
                        progress_callback(i + 1, len(to_upload), "uploading", relative_path)
                
                # Process upload results
                for task, relative_path in upload_tasks:
                    try:
                        if task.result():
                            results['uploaded'] += 1
                        else:
                            results['failed'] += 1
                            results['errors'].append(f"Failed to upload: {relative_path}")
                    except Exception as e:
                        results['failed'] += 1
                        results['errors'].append(f"Error uploading {relative_path}: {str(e)}")
        
        # Process downloads in parallel
        if to_download:
            logger.info(f"Downloading {len(to_download)} files...")
            with ThreadPoolExecutor(max_workers=max_workers) as executor:
                download_tasks = []
                
                for i, remote_path in enumerate(to_download):
                    local_file_path = os.path.join(local_path, remote_path)
                    # Create the directory if it doesn't exist
                    os.makedirs(os.path.dirname(local_file_path), exist_ok=True)
                    
                    task = executor.submit(self._download_file, remote_path, local_file_path)
                    download_tasks.append((task, remote_path))
                    
                    if progress_callback:
                        progress_callback(i + 1, len(to_download), "downloading", remote_path)
                
                # Process download results
                for task, remote_path in download_tasks:
                    try:
                        if task.result():
                            results['downloaded'] += 1
                        else:
                            results['failed'] += 1
                            results['errors'].append(f"Failed to download: {remote_path}")
                    except Exception as e:
                        results['failed'] += 1
                        results['errors'].append(f"Error downloading {remote_path}: {str(e)}")
        
        # Process deletions in parallel
        if to_delete:
            logger.info(f"Deleting {len(to_delete)} orphaned files...")
            with ThreadPoolExecutor(max_workers=max_workers) as executor:
                delete_tasks = []
                
                for i, remote_path in enumerate(to_delete):
                    task = executor.submit(self._delete_file, remote_path)
                    delete_tasks.append((task, remote_path))
                    
                    if progress_callback:
                        progress_callback(i + 1, len(to_delete), "deleting", remote_path)
                
                # Process deletion results
                for task, remote_path in delete_tasks:
                    try:
                        if task.result():
                            results['deleted'] += 1
                        else:
                            results['failed'] += 1
                            results['errors'].append(f"Failed to delete: {remote_path}")
                    except Exception as e:
                        results['failed'] += 1
                        results['errors'].append(f"Error deleting {remote_path}: {str(e)}")
        
        # Update success status based on failures
        results['success'] = results['failed'] == 0
        
        logger.info(f"Sync completed: {results['uploaded']} uploaded, {results['downloaded']} downloaded, {results['deleted']} deleted, {results['unchanged']} unchanged, {results['cached']} cached from local cache, {results['protected_skipped']} write-protected skipped, {results['failed']} failed")
        return results
    
    def purge_cache(self, paths: List[str] = None) -> Dict[str, Any]:
        """
        Purge files from Bunny.net cache
        
        Args:
            paths: List of paths to purge (None to purge everything)
            
        Returns:
            Dict with purge results
        """
        if not self.config.pull_zone_name:
            raise ValueError("Pull zone name is required for cache purging")
            
        results = {
            'success': False,
            'purged': 0,
            'failed': 0,
            'errors': []
        }
        
        # URL for the purge API
        url = f"https://api.bunny.net/pullzone/{self.config.pull_zone_name}/purgeCache"
        
        try:
            if paths:
                # Purge specific paths
                for path in paths:
                    data = {'url': path}
                    response = self.session.post(url, json=data)
                    
                    if response.status_code == 204:
                        results['purged'] += 1
                    else:
                        results['failed'] += 1
                        results['errors'].append(f"Failed to purge {path}: {response.status_code} {response.text}")
            else:
                # Purge everything
                response = self.session.post(f"{url}/purgeEverything")
                
                if response.status_code == 204:
                    results['purged'] = 1
                    logger.info("Successfully purged all cache")
                else:
                    results['failed'] = 1
                    results['errors'].append(f"Failed to purge cache: {response.status_code} {response.text}")
                    
            results['success'] = results['failed'] == 0
                    
        except requests.RequestException as e:
            results['errors'].append(f"Error purging cache: {str(e)}")
            
        return results


if __name__ == "__main__":
    # Example usage
    from .config import BunnyConfig
    
    # Create configuration
    config = BunnyConfig(
        storage_zone_name="your-zone-name",
        api_key="your-api-key",
        hostname="storage.bunnycdn.com",
        pull_zone_name="your-pull-zone",  # Optional, needed for cache purging
        password="your-password",  # Added for password-based authentication
        authenticated_cdn_endpoint="https://authenticated-cdn-endpoint.com",  # Added for authenticated CDN endpoint
        use_bunnycdn_package=True,  # Added for bunnycdnpython package
        storage_api_key="your-storage-api-key"  # Added for bunnycdnpython package
    )
    
    # Initialize sync client
    bunny_sync = BunnySync(config)
    
    # Define a progress callback
    def progress_callback(current, total, action, path):
        percent = int(current * 100 / total) if total > 0 else 0
        print(f"{action.capitalize()}: {current}/{total} ({percent}%) - {path}")
    
    # Sync directory with new features
    results = bunny_sync.sync(
        local_path="./assets/public",
        max_workers=5,
        delete_orphaned=True,
        progress_callback=progress_callback,
        # Using the new features:
        cache_dir="./assets/cache",  # Local cache directory
        sync_paths=["images/", "videos/intro.mp4"],  # Only sync specific paths
        write_protected_paths=["images/logos/"]  # Don't modify local logo files
    )
    
    print(f"Sync completed: {results}")
    
    # Example of a dry run with the new features
    dry_run_results = bunny_sync.sync(
        local_path="./assets/public",
        dry_run=True,
        cache_dir="./assets/cache",
        sync_paths=["js/", "css/"],
        write_protected_paths=["js/vendor/"]
    )
    
    print(f"Dry run completed: {dry_run_results}")
    
    # Purge cache for specific files
    bunny_sync.purge_cache(["path/to/file1.jpg", "path/to/file2.jpg"])
    
    # Download a file using password authentication
    bunny_sync._download_file("path/to/file.jpg", "./assets/cache/downloaded_file.jpg", use_password=True)
    
    # Get public URL for a file
    public_url = bunny_sync.get_public_url("path/to/file.jpg", use_password=True)
    print(f"Public URL: {public_url}") 