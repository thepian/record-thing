"""
Main synchronization logic for B2Sync
"""

import os
import boto3
import hashlib
from typing import Set, Dict, List
from concurrent.futures import ThreadPoolExecutor
from botocore.exceptions import ClientError
from botocore.config import Config
from .config import B2Config


class B2Sync:
    def __init__(self, config: B2Config):
        self.config = config

        # Configure boto3 to use SigV4
        boto_config = Config(signature_version="s3v4", retries={"max_attempts": 3})

        try:
            self.client = boto3.client(
                "s3",
                endpoint_url=config.endpoint_url,
                aws_access_key_id=config.access_key_id,
                aws_secret_access_key=config.secret_access_key,
                region_name=config.region,
                config=boto_config,
            )
            # Test the credentials with a simple operation
            # self.client.head_bucket(Bucket=config.bucket_name)
        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "")
            if error_code == "InvalidAccessKeyId":
                raise ValueError(
                    "Invalid access key ID. Please check your B2 application key ID. "
                    "You can find this in your Backblaze B2 account under 'App Keys'."
                ) from e
            elif error_code == "SignatureDoesNotMatch":
                raise ValueError(
                    "Invalid secret key. Please check your B2 application key secret. "
                    "Note: If you can't see the full key, you'll need to create a new one."
                ) from e
            elif error_code == "NoSuchBucket":
                raise ValueError(
                    f"Bucket '{config.bucket_name}' does not exist or you don't have access to it. "
                    "Please check the bucket name and your permissions."
                ) from e
            else:
                raise ValueError(f"Failed to initialize B2 client: {str(e)}") from e

    def _calculate_md5(self, filepath: str) -> str:
        """Calculate MD5 hash of a file"""
        hash_md5 = hashlib.md5()
        with open(filepath, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()

    def _get_local_files(self, local_path: str) -> Dict[str, str]:
        """Get all files and their MD5 hashes from local directory"""
        local_files = {}
        for root, _, files in os.walk(local_path):
            for file in files:
                full_path = os.path.join(root, file)
                relative_path = os.path.relpath(full_path, local_path)
                local_files[relative_path] = self._calculate_md5(full_path)
        return local_files

    def _get_remote_files(self) -> Dict[str, str]:
        """Get all files and their ETags from B2 bucket"""
        remote_files = {}
        paginator = self.client.get_paginator("list_objects_v2")

        try:
            for page in paginator.paginate(Bucket=self.config.bucket_name):
                if "Contents" in page:
                    for obj in page["Contents"]:
                        # Remove quotes from ETag
                        etag = obj["ETag"].strip('"')
                        remote_files[obj["Key"]] = etag
        except ClientError as e:
            raise Exception(f"Failed to list bucket contents: {str(e)}")

        return remote_files

    def _upload_file(self, local_path: str, relative_path: str) -> None:
        """Upload a single file to B2"""
        try:
            self.client.upload_file(local_path, self.config.bucket_name, relative_path)
        except FileNotFoundError:
            print(f"The file {local_path} was not found")
        # except NoCredentialsError:
        #     print('Credentials not available')
        except ClientError as e:
            raise Exception(f"Failed to upload {relative_path}: {str(e)}")

    def _sync(self):
        for root, dirs, files in os.walk(self.local_folder):
            for file in files:
                local_path = os.path.join(root, file)
                relative_path = os.path.relpath(local_path, self.local_folder)
                s3_path = relative_path.replace(
                    "\\", "/"
                )  # Ensure compatibility with S3 path format
                self.upload_file(local_path, self.bucket_name, s3_path)

    def sync(self, local_path: str, max_workers: int = 4) -> None:
        """
        Synchronize local directory with B2 bucket

        Args:
            local_path: Path to local directory
            max_workers: Maximum number of concurrent uploads
        """
        if not os.path.isdir(local_path):
            raise NotADirectoryError(f"Local path does not exist: {local_path}")

        print(f"Scanning local directory: {local_path}")
        local_files = self._get_local_files(local_path)

        print("Scanning remote bucket...")
        remote_files = self._get_remote_files()

        # Find files to upload (new or modified)
        to_upload = set()
        for relative_path, local_hash in local_files.items():
            if (
                relative_path not in remote_files
                or remote_files[relative_path] != local_hash
            ):
                to_upload.add(relative_path)

        if not to_upload:
            print("Everything is up to date!")
            return

        print(f"Uploading {len(to_upload)} files...")

        # Upload files using thread pool
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = []
            for relative_path in to_upload:
                local_file_path = os.path.join(local_path, relative_path)
                futures.append(
                    executor.submit(self._upload_file, local_file_path, relative_path)
                )

            # Wait for all uploads to complete
            for future in futures:
                future.result()

        print("Sync completed successfully!")


if __name__ == "__main__":
    local_folder = "/path/to/local/folder"
    bucket_name = "your-bucket-name"
    aws_access_key_id = "your-access-key-id"
    aws_secret_access_key = "your-secret-access-key"

    b2sync = B2Sync(local_folder, bucket_name, aws_access_key_id, aws_secret_access_key)
    b2sync.sync()

    class B2Config:
        def __init__(
            self,
            local_folder,
            bucket_name,
            aws_access_key_id,
            aws_secret_access_key,
            region_name="us-west-002",
        ):
            self.local_folder = local_folder
            self.bucket_name = bucket_name
            self.aws_access_key_id = aws_access_key_id
            self.aws_secret_access_key = aws_secret_access_key
            self.region_name = region_name

    if __name__ == "__main__":
        config = B2Config(
            local_folder="/path/to/local/folder",
            bucket_name="your-bucket-name",
            aws_access_key_id="your-access-key-id",
            aws_secret_access_key="your-secret-access-key",
        )

        b2sync = B2Sync(
            local_folder=config.local_folder,
            bucket_name=config.bucket_name,
            aws_access_key_id=config.aws_access_key_id,
            aws_secret_access_key=config.aws_secret_access_key,
            region_name=config.region_name,
        )
        b2sync.sync()
