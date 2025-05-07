"""
Configuration management for B2Sync
"""

import os
import json
import re
from dataclasses import dataclass
from typing import Optional


@dataclass
class B2Config:
    bucket_name: str
    endpoint_url: str
    access_key_id: str
    secret_access_key: str
    region: str = "us-west-002"

    def __post_init__(self):
        """Validate configuration after initialization"""
        # Validate access key format (Backblaze keys are typically 31 characters)
        # if not re.match(r'^[A-Za-z0-9]{10,}$', self.access_key_id):
        #     raise ValueError("Invalid access_key_id format. Backblaze B2 application keys should be at least 31 characters long.")
        if not self.secret_access_key or self.secret_access_key.isspace():
            raise ValueError("secret_access_key cannot be empty")

        # Validate secret key format
        # if len(self.secret_access_key) < 31:
        #     raise ValueError("Secret access key appears too short. Backblaze B2 application keys should be at least 31 characters long.")

        # Validate endpoint URL format
        if not self.endpoint_url.startswith(("http://", "https://")):
            raise ValueError("Endpoint URL must start with http:// or https://")

        # Validate bucket name format
        if not re.match(r"^[a-z0-9-]{3,63}$", self.bucket_name.lower()):
            raise ValueError(
                "Invalid bucket name. Bucket names must be 3-63 characters and contain only lowercase letters, numbers, and hyphens."
            )

    @classmethod
    def from_file(cls, config_path: str) -> "B2Config":
        """Load configuration from a JSON file"""
        if not os.path.exists(config_path):
            raise FileNotFoundError(f"Config file not found: {config_path}")

        with open(config_path, "r") as f:
            config_data = json.load(f)

        required_fields = [
            "bucket_name",
            "endpoint_url",
            "access_key_id",
            "secret_access_key",
        ]
        missing_fields = [
            field for field in required_fields if field not in config_data
        ]

        if missing_fields:
            raise ValueError(
                f"Missing required fields in config: {', '.join(missing_fields)}"
            )

        return cls(**config_data)

    def save(self, config_path: str) -> None:
        """Save configuration to a JSON file"""
        with open(config_path, "w") as f:
            json.dump(self.__dict__, f, indent=4)
