"""
Configuration management for Bunny.net CDN
"""

import os
import json
import re
from dataclasses import dataclass
from typing import Optional, List


@dataclass
class BunnyConfig:
    """Configuration for Bunny.net CDN storage and pull zones"""

    storage_zone_name: str
    api_key: str
    hostname: str  # e.g., storage.bunnycdn.com
    pull_zone_name: Optional[str] = None
    storage_region: str = ""  # Empty string for default region, or specific region code
    cdn_url: Optional[str] = None  # Custom CDN URL if using one
    password: Optional[str] = None  # Password for direct file access to storage zone
    storage_api_key: Optional[str] = None  # Storage API key for bunnycdnpython package
    enabled_regions: List[str] = None  # Regions to enable for pull zone
    use_bunnycdn_package: bool = False  # Whether to use bunnycdnpython package

    def __post_init__(self):
        """Validate configuration after initialization"""
        # Validate API key format (Bunny.net keys are UUID-like strings)
        if not self.api_key or len(self.api_key) < 32:
            raise ValueError(
                "Invalid API key format. Bunny.net API keys should be at least 32 characters long."
            )

        # Validate storage zone name format
        if not re.match(r"^[a-z0-9][a-z0-9-]{2,62}$", self.storage_zone_name.lower()):
            raise ValueError(
                "Invalid storage zone name. Names must be 3-63 characters and contain only lowercase letters, numbers, and hyphens."
            )

        # Validate hostname format
        if not re.match(
            r"^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?$",
            self.hostname.lower(),
        ):
            raise ValueError(
                "Invalid hostname format. Should be a valid domain name (e.g., storage.bunnycdn.com)."
            )

        # Initialize empty lists if needed
        if self.enabled_regions is None:
            self.enabled_regions = []

        # Set use_bunnycdn_package flag if storage_api_key is provided
        if self.storage_api_key:
            self.use_bunnycdn_package = True

    @classmethod
    def from_file(cls, config_path: str) -> "BunnyConfig":
        """Load configuration from a JSON file"""
        if not os.path.exists(config_path):
            raise FileNotFoundError(f"Config file not found: {config_path}")

        with open(config_path, "r") as f:
            config_data = json.load(f)

        required_fields = ["storage_zone_name", "api_key", "hostname"]
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
        os.makedirs(os.path.dirname(config_path), exist_ok=True)
        with open(config_path, "w") as f:
            json.dump(self.__dict__, f, indent=4)

    @property
    def storage_api_url(self) -> str:
        """Get the API URL for storage operations"""
        if self.storage_region:
            return f"https://storage-{self.storage_region}.bunnycdn.com"
        return f"https://{self.hostname}"

    @property
    def cdn_endpoint(self) -> str:
        """Get the CDN endpoint for direct file access"""
        if self.cdn_url:
            return self.cdn_url

        # Standard format for Bunny.net storage URL
        base_url = f"https://{self.storage_zone_name}.{self.hostname}"

        # If password is provided, include it in the URL for direct access
        if self.password:
            return f"https://{self.storage_zone_name}:{self.password}@{self.hostname}"

        return base_url

    @property
    def authenticated_cdn_endpoint(self) -> str:
        """Get the password-authenticated CDN endpoint for direct file access"""
        if not self.password:
            raise ValueError("Password is required for authenticated access")

        # For password-based authentication with Bunny.net
        hostname = self.hostname
        if self.storage_region:
            hostname = f"storage-{self.storage_region}.bunnycdn.com"

        return f"https://{self.storage_zone_name}:{self.password}@{hostname}"
