import os
import openai
from openai import AzureOpenAI  # Import AzureOpenAI client
from pathlib import Path
import requests
from datetime import datetime
import json
import logging
import sqlite3
from typing import List, Dict, Optional, Tuple, Union
import pandas as pd
from IPython.display import Image, display
import matplotlib.pyplot as plt
from tqdm import tqdm
import time
from PIL import Image as PILImage
import io
import base64  # Needed for Together AI response
import random

# Use Vertex AI SDK for Google Cloud Image Generation
from google.cloud import aiplatform

# from vertexai.preview.generative_models import GenerativeModel, Image # Remove this preview import
from vertexai.vision_models import (
    ImageGenerationModel,
    Image,
)  # Use stable Vision Models

# Together AI specific import
import together

from .commons import DBP, assets_ref_path


# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class EvidenceImageGenerator:
    def __init__(
        self,
        db_path: Path = DBP,
        provider: str = "openai",
        api_key: Optional[str] = None,
        azure_endpoint: Optional[str] = None,  # Azure specific
        api_version: Optional[str] = None,  # Azure specific
        image_model: Optional[str] = None,  # Model name or Azure deployment name
        image_size: str = "1024x1024",
        image_quality: str = "standard",  # DALL-E specific
        dry_run: bool = False,
        project_id: Optional[str] = None,  # Google Cloud specific
        location: Optional[str] = "us-central1",  # Google Cloud specific
        model_params: Optional[Dict] = None,  # Additional model-specific parameters
        iconic_size: Tuple[int, int] = (256, 256),  # Size for iconic image thumbnails
        output_dir: Optional[Path] = None,  # Custom output directory
    ):
        """Initialize the evidence image generator.

        Args:
            db_path: Path to the database.
            provider: Image generation provider ("openai", "google", "azure", or "together"). Defaults to "openai".
            api_key: API key for the selected provider. Reads from env vars if None
                     (OPENAI_API_KEY, GOOGLE_API_KEY, AZURE_OPENAI_API_KEY, TOGETHER_API_KEY).
            azure_endpoint: Azure OpenAI endpoint URL (required for "azure" provider).
                            Reads from AZURE_OPENAI_ENDPOINT env var if None.
            api_version: Azure OpenAI API version (required for "azure" provider).
                         Reads from AZURE_OPENAI_API_VERSION env var if None.
            image_model: Model name for OpenAI/Google/Together, or deployment name for Azure.
                         Defaults: "dall-e-3" (openai), "imagegeneration@006" (google),
                                   "stabilityai/stable-diffusion-v1-5" (together), None (azure - required).
            image_size: Size of the generated image (OpenAI/Azure DALL-E specific,
                        influences height/width for Together AI). Defaults to "1024x1024".
            image_quality: Quality of the generated image (OpenAI/Azure DALL-E 3 specific). Defaults to "standard".
                         Valid values: "standard", "hd". (Not directly used by Google/Together).
            dry_run: If True, logs actions without making API calls or saving files.
            project_id: Google Cloud project ID (required for "google" provider).
                        Reads from GOOGLE_CLOUD_PROJECT env var if None.
            location: Google Cloud location (required for "google" provider). Defaults to "us-central1".
                     Reads from GOOGLE_CLOUD_LOCATION env var if None.
            model_params: Dictionary of additional model-specific parameters to pass to the API call.
                         These parameters override defaults and will be passed directly to the provider's API.
            iconic_size: Size to use for iconic thumbnail images stored in the database.
            output_dir: Custom output directory for saving generated images. If None, uses assets_ref_path/sample_images.
        """
        self.provider = provider.lower()
        self.dry_run = dry_run
        self.rate_limit_delay = (
            3  # seconds between API calls (adjust per provider if needed)
        )
        self.max_retries = 3
        self.image_size = image_size
        self.image_quality = (
            image_quality if image_quality in ["standard", "hd"] else "standard"
        )  # OpenAI/Azure DALL-E 3
        self.image_model_name = image_model  # Store the requested model/deployment name
        self.model_params = (
            model_params or {}
        )  # Initialize model_params as empty dict if None
        self.iconic_size = (
            iconic_size  # Size for thumbnail images stored in the database
        )

        # --- Provider specific initialization ---
        if self.provider == "openai":
            self.api_key = api_key or os.getenv("OPENAI_API_KEY")
            if not self.api_key:
                raise ValueError(
                    "OpenAI API key is required (or set OPENAI_API_KEY environment variable)"
                )
            self.openai_client = openai.OpenAI(api_key=self.api_key)
            self.image_model_name = self.image_model_name or "dall-e-3"
            logger.info(f"Using OpenAI provider with model: {self.image_model_name}")

        elif self.provider == "google":
            self.project_id = project_id or os.getenv("GOOGLE_CLOUD_PROJECT")
            self.location = location or os.getenv(
                "GOOGLE_CLOUD_LOCATION", "us-central1"
            )
            if not self.project_id:
                raise ValueError(
                    "Google Cloud project_id is required (or set GOOGLE_CLOUD_PROJECT environment variable)"
                )

            logger.info(
                f"Initializing Google Cloud Vertex AI: Project={self.project_id}, Location={self.location}"
            )
            try:
                aiplatform.init(project=self.project_id, location=self.location)
                self.image_model_name = self.image_model_name or "imagegeneration@006"
                self.google_model = ImageGenerationModel.from_pretrained(
                    self.image_model_name
                )
                logger.info(
                    f"Using Google Vertex AI provider with model: {self.image_model_name}"
                )
            except Exception as e:
                logger.error(f"Failed to initialize Google Cloud Vertex AI: {e}")
                raise

        elif self.provider == "azure":
            self.api_key = api_key or os.getenv("AZURE_OPENAI_API_KEY")
            self.azure_endpoint = azure_endpoint or os.getenv("AZURE_OPENAI_ENDPOINT")
            self.api_version = api_version or os.getenv("AZURE_OPENAI_API_VERSION")
            self.image_model_name = self.image_model_name or os.getenv(
                "AZURE_OPENAI_DEPLOYMENT_NAME"
            )
            if not all(
                [
                    self.api_key,
                    self.azure_endpoint,
                    self.api_version,
                    self.image_model_name,
                ]
            ):
                raise ValueError(
                    "Azure provider requires api_key, azure_endpoint, api_version, and image_model (deployment name). Set them or use environment variables."
                )
            self.azure_client = AzureOpenAI(
                api_key=self.api_key,
                azure_endpoint=self.azure_endpoint,
                api_version=self.api_version,
            )
            logger.info(
                f"Using Azure OpenAI provider with deployment: {self.image_model_name} at {self.azure_endpoint}"
            )

        elif self.provider == "together":
            self.api_key = api_key or os.getenv("TOGETHER_API_KEY")
            if not self.api_key:
                raise ValueError(
                    "Together AI API key is required (or set TOGETHER_API_KEY environment variable)"
                )
            # The together client uses the env var by default if api_key=None
            self.together_client = together.Together(api_key=self.api_key)
            # Default to a model known to be available in Together AI
            self.image_model_name = (
                self.image_model_name or "stabilityai/stable-diffusion-v1-5"
            )
            logger.info(
                f"Using Together AI provider with model: {self.image_model_name}"
            )
            # Parse image size for height/width
            try:
                self.width, self.height = map(int, self.image_size.split("x"))
            except ValueError:
                logger.warning(
                    f"Invalid image_size format '{self.image_size}' for Together AI. Defaulting to 1024x1024."
                )
                self.width, self.height = 1024, 1024

        else:
            raise ValueError(
                f"Unsupported provider: {provider}. Choose 'openai', 'google', 'azure', or 'together'."
            )

        # --- Common initialization ---
        self.db_path = db_path
        if not self.db_path.exists():
            raise FileNotFoundError(f"Database file not found at: {self.db_path}")
        self.conn = sqlite3.connect(db_path)
        self.cursor = self.conn.cursor()

        self.output_dir = output_dir or assets_ref_path / "cache"
        self.output_dir.mkdir(parents=True, exist_ok=True)
        logger.debug(f"Image output directory: {self.output_dir}")

    def get_missing_evidence(self, limit: Optional[int] = None) -> List[Dict]:
        """Get evidence records where the local_file path points to a non-existent file,
        and attempt to recover missing files from URLs when available.
        """
        # First, query for all evidence that has a local_file path
        query = """
            SELECT e.id, e.thing_id, e.thing_account_id, e.evidence_type,
                   t.title, t.description, t.category, t.brand, t.model, t.color,
                   e.data as evidence_data,
                   e.local_file
            FROM evidence e
            LEFT JOIN things t ON e.thing_id = t.id AND e.thing_account_id = t.account_id
            WHERE e.local_file IS NOT NULL AND e.local_file != ''
        """

        self.cursor.execute(query)
        all_evidence = self.cursor.fetchall()

        missing_evidence_list = []
        count = 0
        recovered_count = 0

        for row in all_evidence:
            evidence_id = row[0]
            local_file = row[11]  # e.local_file
            relative_path = local_file.lstrip("/")
            file_path = self.output_dir / relative_path

            # Check if the file exists at the expected path
            file_exists = file_path.exists()

            if file_exists:
                logger.debug(f"File exists: {file_path} for evidence ID {evidence_id}")
                continue

            # File doesn't exist locally, try to recover it from URLs

            # 1. Check for URL in evidence data
            evidence_data = {}
            image_url = None

            if row[10] and row[10] != "null":
                try:
                    evidence_data = json.loads(row[10])
                    # Check for URL in evidence data
                    image_url = evidence_data.get("image_url") or evidence_data.get(
                        "url"
                    )
                except json.JSONDecodeError:
                    logger.warning(
                        f"Failed to parse evidence data for ID {evidence_id}"
                    )

            # 2. If no URL in evidence data, check image_assets table
            if not image_url:
                try:
                    self.cursor.execute(
                        """
                        SELECT original_url, alt_url 
                        FROM image_assets 
                        WHERE path = ?
                    """,
                        (relative_path,),
                    )

                    url_row = self.cursor.fetchone()
                    if url_row and url_row[0]:
                        image_url = url_row[0]  # original_url
                    elif url_row and url_row[1]:
                        image_url = url_row[1]  # alt_url
                except Exception as e:
                    logger.warning(
                        f"Error querying image_assets table for {evidence_id}: {e}"
                    )

            # 3. If we found a URL, try to download the image
            if image_url:
                logger.info(
                    f"Found URL for missing evidence {evidence_id}: {image_url[:100]}..."
                )
                if self._recover_image_from_url(image_url, file_path):
                    recovered_count += 1
                    # Image successfully recovered, no need to consider it missing
                    continue

            # If we reach here, the file is truly missing (doesn't exist and couldn't be recovered)
            logger.debug(
                f"Missing file found: {file_path} for evidence ID {evidence_id}"
            )
            missing_evidence_list.append(
                {
                    "evidence_id": evidence_id,
                    "thing_id": row[1],
                    "account_id": row[2],
                    "evidence_type": row[3],
                    "thing_title": row[4],
                    "thing_description": row[5],
                    "category": row[6],
                    "brand": row[7],
                    "model": row[8],
                    "color": row[9],
                    "evidence_data": evidence_data,
                    "local_file": local_file,
                    "expected_path": str(file_path),
                }
            )
            count += 1
            if limit is not None and count >= limit:
                break

        if recovered_count > 0:
            logger.info(f"Recovered {recovered_count} missing images from URLs")
        logger.info(
            f"Found {len(missing_evidence_list)} evidence records with missing image files (after recovery attempts)."
        )
        return missing_evidence_list

    def sanitize_prompt(self, text: str) -> str:
        """
        Removes potentially problematic characters or patterns from the prompt
        and ensures it's within appropriate length limits.
        """
        if not text:
            return "A photograph of a personal item on a neutral background"

        # Remove excess whitespace
        sanitized = " ".join(text.split())

        # Remove problematic characters
        sanitized = sanitized.replace("\n", " ").replace("\r", " ")

        # Remove any leading/trailing punctuation
        sanitized = sanitized.strip(".,;:!?-_")

        # Ensure the prompt isn't too long (adjust max length based on provider)
        max_length = 1500  # Default
        if self.provider == "openai" or self.provider == "azure":
            max_length = 4000  # DALL-E 3 supports longer prompts
        elif self.provider == "together":
            max_length = (
                2000  # Stable Diffusion models generally have a bit more capacity
            )
        elif self.provider == "google":
            max_length = 1500  # Imagen is more restrictive

        if len(sanitized) > max_length:
            logger.debug(
                f"Truncating prompt from {len(sanitized)} to {max_length} characters"
            )
            sanitized = sanitized[:max_length]
            # Ensure we don't cut in the middle of a sentence
            last_period = sanitized.rfind(".")
            if (
                last_period > max_length * 0.8
            ):  # If there's a period in the last 20% of text
                sanitized = sanitized[: last_period + 1]

        return sanitized

    def generate_prompt(self, evidence: Dict) -> str:
        """Generate a prompt for the image generation based on evidence details."""
        try:
            logger.debug(
                f"Generating prompt for evidence: {json.dumps(evidence, indent=2)}"
            )

            # Get evidence type and document type from evidence data
            evidence_data = evidence.get("evidence_data", {})
            evidence_type = evidence_data.get("type", "")
            document_type = evidence_data.get("document_type", "")

            # Determine if this is a document based on evidence type or document_type being present
            is_document = (
                document_type != ""
                or evidence_type.lower()
                in [
                    "document",
                    "receipt",
                    "invoice",
                    "certificate",
                    "letter",
                    "id",
                    "identification",
                ]
                or (
                    evidence.get("category", "").lower()
                    in [
                        "document",
                        "documents",
                        "paperwork",
                        "certificate",
                        "identification",
                    ]
                )
            )

            # Select a random base prompt variant
            base_prompts = [
                "A clear, well-lit photograph of",
                "A detailed product image showing",
                "A realistic documentary photo capturing",
                "A high-resolution image displaying",
                "A photographic record showing",
            ]
            base_prompt = random.choice(base_prompts)

            # Build the item description
            item_desc_parts = [
                evidence.get("brand"),
                evidence.get("thing_title", "a personal item"),
            ]
            if evidence.get("thing_description"):
                item_desc_parts.append(
                    f"described as '{evidence.get('thing_description')}'"
                )
            item_desc = " ".join(filter(None, item_desc_parts))

            prompt = f"{base_prompt} {item_desc}"

            # Add category, type, document type if available
            descriptors = []
            if evidence.get("category"):
                descriptors.append(f"category: {evidence['category']}")
            if evidence_type:
                descriptors.append(f"type: {evidence_type}")
            if document_type:
                descriptors.append(f"document type: {document_type}")
            if evidence.get("color"):
                descriptors.append(f"color: {evidence['color']}")

            if descriptors:
                prompt += f", {', '.join(descriptors)}"

            # Select a context variant, excluding backside for documents
            context_variants = [
                "on an isolated white background, clearly showing the entire item with no distractions",
                "as a hero shot with complementary neutral setting, prominently displayed",
                "held in a hand for scale reference, showing normal usage",
                "placed on a neutral surface with soft lighting, emphasizing the complete object",
            ]

            # Only add the backside option for non-document items
            if not is_document:
                context_variants.append(
                    "showing the back side or alternate angle, revealing additional details"
                )

            context = random.choice(context_variants)

            # Add notes if available
            notes = evidence_data.get("notes")
            if notes:
                prompt += f". Additional context: {notes}"

            # Add the selected context
            prompt += f". Context: {context}"

            # Add common requirements for ML training
            prompt += ". The image should be high quality and suitable for machine learning training, with the subject occupying most of the frame. Natural lighting, photorealistic style, no filters or text."

            sanitized_prompt = self.sanitize_prompt(prompt)
            logger.debug(f"Generated prompt: {sanitized_prompt}")

            if not sanitized_prompt:
                logger.warning("Empty prompt generated, using fallback")
                return "A photograph of a personal item on a neutral background"

            return sanitized_prompt

        except Exception as e:
            logger.error(f"Error generating prompt: {str(e)}")
            return "A photograph of a personal item on a neutral background"

    def validate_image(self, image_data: bytes) -> Tuple[bool, str]:
        """Validate the generated image meets basic requirements."""
        try:
            img = PILImage.open(io.BytesIO(image_data))
            if img.size[0] < 512 or img.size[1] < 512:  # Keep a reasonable minimum size
                return False, f"Image size {img.size} is too small (min 512x512)"
            if img.format not in ["PNG", "JPEG"]:
                return False, f"Invalid image format: {img.format}"
            return True, "Image valid"
        except Exception as e:
            return False, f"Image validation failed: {str(e)}"

    def _create_iconic_image(self, image_data: bytes) -> bytes:
        """Create a scaled-down iconic version of the image suitable for storage in the database.

        Args:
            image_data: Original image bytes

        Returns:
            bytes: PNG-encoded bytes of the iconic image at the configured size
        """
        try:
            img = PILImage.open(io.BytesIO(image_data))

            # Resize maintaining aspect ratio
            img.thumbnail(self.iconic_size, PILImage.Resampling.LANCZOS)

            # Convert to PNG format
            buffer = io.BytesIO()
            img.save(buffer, format="PNG", optimize=True)
            iconic_png = buffer.getvalue()

            logger.debug(
                f"Created iconic image: {len(iconic_png)} bytes, size {img.size}"
            )
            return iconic_png
        except Exception as e:
            logger.error(f"Error creating iconic image: {e}")
            # Return None on error, which will be handled in the calling method
            return None

    def _save_to_image_assets(
        self, path: str, image_data: bytes, image_url: Optional[str] = None
    ) -> bool:
        """Save image data to the image_assets table.

        Args:
            path: The local_file path to use as the PRIMARY KEY
            image_data: The original image data bytes
            image_url: Optional URL where the image was downloaded from

        Returns:
            bool: True if successful, False if failed
        """
        try:
            # Calculate hash values for the image
            import hashlib

            sha1 = hashlib.sha1(image_data).hexdigest()
            md5 = hashlib.md5(image_data).hexdigest()

            # Create the iconic version of the image
            iconic_png = self._create_iconic_image(image_data)
            if not iconic_png:
                logger.warning(f"Failed to create iconic image for {path}")
                # Continue anyway, just without the iconic image

            # Store in database
            self.cursor.execute(
                """
                INSERT OR REPLACE INTO image_assets (
                    path, alt_url, original_url, sha1, md5, iconic_png
                ) VALUES (?, ?, ?, ?, ?, ?)
            """,
                (path, None, image_url, sha1, md5, iconic_png),
            )

            self.conn.commit()
            logger.info(f"Saved image assets record for {path}")
            return True

        except Exception as e:
            logger.error(f"Error saving to image_assets table: {e}")
            return False

    def generate_image(self, evidence: Dict) -> Optional[str]:
        """Generate an image for the evidence record using the configured provider."""
        prompt = self.generate_prompt(evidence)
        evidence_id = evidence["evidence_id"]

        # Determine if this is a document
        evidence_data = evidence.get("evidence_data", {})
        evidence_type = evidence_data.get("type", "")
        document_type = evidence_data.get("document_type", "")
        is_document = (
            document_type != ""
            or evidence_type.lower()
            in [
                "document",
                "receipt",
                "invoice",
                "certificate",
                "letter",
                "id",
                "identification",
            ]
            or (
                evidence.get("category", "").lower()
                in [
                    "document",
                    "documents",
                    "paperwork",
                    "certificate",
                    "identification",
                ]
            )
        )

        logger.info(
            f"Attempting to generate image for evidence {evidence_id} using {self.provider}"
        )
        logger.debug(f"Using prompt: {prompt}")

        # Extract the original file extension from local_file
        original_path = evidence.get("local_file", "")
        original_ext = Path(original_path).suffix.lower() if original_path else ".png"

        # Default to PNG if no extension or unsupported extension
        if original_ext not in [".jpg", ".jpeg", ".png"]:
            logger.debug(
                f"Unsupported extension '{original_ext}' for {evidence_id}, defaulting to PNG"
            )
            original_ext = ".png"

        logger.debug(f"Will save image as {original_ext} format for {evidence_id}")

        if self.dry_run:
            logger.info(
                f"[DRY RUN] Would generate image for {evidence_id} with prompt: '{prompt}'"
            )
            self._log_prompt_analytics(prompt, evidence_id, is_document)
            return str(self.output_dir / original_path.lstrip("/"))

        image_data: Optional[bytes] = None
        image_url: Optional[str] = None
        error_message: str = "Unknown error during generation"

        for attempt in range(self.max_retries):
            try:
                logger.info(
                    f"Attempt {attempt + 1}/{self.max_retries} for evidence {evidence_id}"
                )

                if self.provider == "openai":
                    image_data = self._generate_image_openai(prompt)
                elif self.provider == "google":
                    image_data = self._generate_image_google(prompt)
                elif self.provider == "azure":
                    image_data = self._generate_image_azure(prompt)
                elif self.provider == "together":
                    # For Together API, we might get image_data back or a tuple with (image_data, image_url)
                    result = self._generate_image_together(prompt)
                    if isinstance(result, tuple) and len(result) == 2:
                        image_data, image_url = result
                    else:
                        image_data = result
                else:
                    logger.error(f"Invalid provider configured: {self.provider}")
                    return None

                if image_data:
                    is_valid, validation_msg = self.validate_image(image_data)
                    if is_valid:
                        # Create the filename with the correct extension
                        filepath = self.output_dir / original_path.lstrip("/")

                        # Handle format conversion if needed
                        try:
                            img = PILImage.open(io.BytesIO(image_data))

                            # Determine format for saving
                            save_format = (
                                "PNG" if original_ext.lower() == ".png" else "JPEG"
                            )

                            # Set quality for JPEG
                            save_options = {}
                            if save_format == "JPEG":
                                save_options["quality"] = 95
                                # Convert RGBA to RGB if needed (JPEG doesn't support alpha channel)
                                if img.mode == "RGBA":
                                    logger.debug(
                                        f"Converting RGBA to RGB for JPEG output for {evidence_id}"
                                    )
                                    # Create white background and paste the image on top
                                    background = PILImage.new(
                                        "RGB", img.size, (255, 255, 255)
                                    )
                                    background.paste(
                                        img, mask=img.split()[3]
                                    )  # Use alpha channel as mask
                                    img = background

                            # Save with appropriate format
                            img_buffer = io.BytesIO()
                            img.save(img_buffer, format=save_format, **save_options)
                            processed_image_data = img_buffer.getvalue()

                            # Write to file
                            with open(filepath, "wb") as f:
                                f.write(processed_image_data)

                            logger.info(
                                f"Image successfully generated and saved to {filepath} as {save_format}"
                            )

                            # Save to image_assets table using local_file as the path key
                            db_path = original_path.lstrip("/")
                            self._save_to_image_assets(
                                db_path, processed_image_data, image_url
                            )

                        except Exception as e:
                            logger.error(f"Error processing image format: {e}")
                            # Fall back to saving raw image data
                            with open(filepath, "wb") as f:
                                f.write(image_data)
                            logger.info(
                                f"Image saved in original format to {filepath} (format conversion failed)"
                            )

                            # Still try to save to image_assets with the raw data
                            db_path = original_path.lstrip("/")
                            self._save_to_image_assets(db_path, image_data, image_url)

                        # If we got this image from a URL, store the URL in the evidence_data
                        if image_url:
                            # Get current evidence_data
                            self.cursor.execute(
                                """
                                SELECT data FROM evidence WHERE id = ?
                            """,
                                (evidence_id,),
                            )
                            current_data_row = self.cursor.fetchone()
                            current_data = {}
                            if current_data_row and current_data_row[0]:
                                try:
                                    if current_data_row[0] != "null":
                                        current_data = json.loads(current_data_row[0])
                                except json.JSONDecodeError:
                                    logger.warning(
                                        f"Failed to parse existing evidence data for {evidence_id}"
                                    )

                            # Add URL to evidence_data
                            current_data["image_url"] = image_url

                            # Update the database with both the local file path and the evidence_data
                            self.cursor.execute(
                                """
                                UPDATE evidence SET local_file = ?, data = ? WHERE id = ?
                            """,
                                (original_path, json.dumps(current_data), evidence_id),
                            )
                        else:
                            # Just update the local_file if no URL
                            self.cursor.execute(
                                """
                                UPDATE evidence SET local_file = ? WHERE id = ?
                            """,
                                (original_path, evidence_id),
                            )

                        self.conn.commit()
                        logger.info(f"Database updated for evidence {evidence_id}")

                        self._log_prompt_analytics(prompt, evidence_id, is_document)

                        return str(filepath)  # Success!
                    else:
                        error_message = f"Image validation failed: {validation_msg}"
                        logger.warning(f"{error_message} for {evidence_id}")
                        # Fail fast on validation error
                        return None

                else:
                    # Generation failed within the provider method
                    error_message = f"{self.provider.capitalize()} API call failed or returned no data."
                    if attempt < self.max_retries - 1:
                        wait_time = self.rate_limit_delay * (2**attempt)
                        logger.warning(
                            f"Generation attempt {attempt + 1} failed. Retrying in {wait_time}s..."
                        )
                        time.sleep(wait_time)
                        continue
                    else:
                        logger.error(f"Max retries reached for evidence {evidence_id}.")
                        return None

            # Catch specific provider errors if available/needed
            except openai.RateLimitError as e:
                wait_time = self.rate_limit_delay * (2**attempt)
                logger.warning(
                    f"OpenAI/Azure Rate limit hit, waiting {wait_time}s. Error: {e}"
                )
                time.sleep(wait_time)
                error_message = str(e)
            except openai.BadRequestError as e:
                logger.error(f"OpenAI/Azure API rejected prompt: {str(e)}")
                logger.error(f"Failed prompt was: {prompt}")
                error_message = f"API rejected prompt: {e}"
                return None
            # Together AI errors
            except together.error.RateLimitError as e:
                wait_time = self.rate_limit_delay * (2**attempt)
                logger.warning(
                    f"Together AI Rate limit hit, waiting {wait_time}s. Error: {e}"
                )
                time.sleep(wait_time)
                error_message = str(e)
            except together.error.InvalidRequestError as e:
                logger.error(f"Together AI request error: {str(e)}")
                error_message = f"API rejected request: {e}"
                if "model_not_available" in str(e):
                    logger.error(
                        f"Model {self.image_model_name} is not available in Together AI"
                    )
                    return None
                elif attempt < self.max_retries - 1:
                    wait_time = self.rate_limit_delay * (2**attempt)
                    time.sleep(wait_time)
                else:
                    return None
            # Add specific Google/Together errors here if known
            except requests.exceptions.RequestException as e:
                logger.error(f"Network error (e.g., downloading image): {str(e)}")
                error_message = f"Network error: {e}"
                if attempt < self.max_retries - 1:
                    wait_time = self.rate_limit_delay * (2**attempt)
                    time.sleep(wait_time)
                else:
                    return None  # Fail after retries
            except Exception as e:
                logger.exception(
                    f"Unexpected error generating image for {evidence_id} (attempt {attempt + 1}): {e}"
                )
                error_message = str(e)
                if attempt < self.max_retries - 1:
                    wait_time = self.rate_limit_delay * (2**attempt)
                    logger.info(
                        f"Waiting {wait_time}s before retry {attempt + 2}/{self.max_retries}."
                    )
                    time.sleep(wait_time)
                else:
                    return None  # Failed after retries

        logger.error(
            f"Failed to generate image for {evidence_id} after {self.max_retries} attempts. Last error context: {error_message}"
        )
        return None

    def _generate_image_openai(self, prompt: str) -> Optional[bytes]:
        """Generate image using OpenAI's DALL-E and return image bytes."""
        try:
            logger.debug(
                f"Calling OpenAI API model={self.image_model_name}, size={self.image_size}, quality={self.image_quality}"
            )

            # Base parameters
            params = {
                "model": self.image_model_name,
                "prompt": prompt,
                "size": self.image_size,
                "quality": self.image_quality,
                "n": 1,
                "response_format": "url",
            }

            # Update with any additional model-specific parameters
            params.update(self.model_params)

            response = self.openai_client.images.generate(**params)

            image_url = response.data[0].url
            logger.debug(f"OpenAI generated image URL: {image_url}")

            image_response = requests.get(image_url, timeout=60)
            image_response.raise_for_status()
            logger.debug(
                f"Image downloaded from OpenAI, size: {len(image_response.content)} bytes"
            )
            return image_response.content

        except (openai.BadRequestError, openai.RateLimitError) as e:
            raise e
        except requests.exceptions.RequestException as e:
            logger.error(f"Network error downloading OpenAI image: {e}")
            raise e
        except Exception as e:
            logger.exception(f"OpenAI API call or download failed: {e}")
            return None

    def _generate_image_google(self, prompt: str) -> Optional[bytes]:
        """Generate image using Google Vertex AI Imagen and return image bytes."""
        try:
            logger.debug(f"Calling Google Vertex AI API model={self.image_model_name}")

            # Base parameters
            params = {
                "prompt": prompt,
                "number_of_images": 1,
            }

            # Update with any additional model-specific parameters
            params.update(self.model_params)

            images = self.google_model.generate_images(**params)

            if not images:
                logger.warning("Google API returned no images.")
                return None

            image_data = images[0]._blob
            logger.debug(f"Image generated by Google, size: {len(image_data)} bytes")
            return image_data

        except Exception as e:
            logger.exception(f"Google Vertex AI API error: {e}")
            # Consider raising specific Google exceptions if needed for retry logic
            return None

    def _generate_image_azure(self, prompt: str) -> Optional[bytes]:
        """Generate image using Azure OpenAI DALL-E and return image bytes."""
        try:
            logger.debug(
                f"Calling Azure OpenAI API deployment={self.image_model_name}, size={self.image_size}, quality={self.image_quality}"
            )

            # Base parameters
            params = {
                "model": self.image_model_name,
                "prompt": prompt,
                "size": self.image_size,
                "quality": self.image_quality,
                "n": 1,
                "response_format": "url",
            }

            # Update with any additional model-specific parameters
            params.update(self.model_params)

            response = self.azure_client.images.generate(**params)
            image_url = response.data[0].url
            logger.debug(f"Azure OpenAI generated image URL: {image_url}")

            image_response = requests.get(image_url, timeout=60)
            image_response.raise_for_status()
            logger.debug(
                f"Image downloaded from Azure, size: {len(image_response.content)} bytes"
            )
            return image_response.content

        except (openai.BadRequestError, openai.RateLimitError) as e:
            raise e
        except requests.exceptions.RequestException as e:
            logger.error(f"Network error downloading Azure image: {e}")
            raise e
        except Exception as e:
            logger.exception(f"Azure OpenAI API call or download failed: {e}")
            return None

    def _log_together_response(
        self, response, level=logging.DEBUG, prefix="Together API response"
    ):
        """Log detailed information from a Together API response."""
        try:
            # Try to use model_dump() for Pydantic models
            if hasattr(response, "model_dump"):
                logger.log(level, f"{prefix} data: {response.model_dump()}")
            # Fallback for non-Pydantic responses
            else:
                # For dictionary-like objects
                if hasattr(response, "items"):
                    logger.log(level, f"{prefix} data: {dict(response)}")
                # For objects with __dict__
                elif hasattr(response, "__dict__"):
                    logger.log(level, f"{prefix} attributes: {vars(response)}")
                # Last resort
                else:
                    logger.log(level, f"{prefix} repr: {repr(response)}")

            # Log specific fields of interest
            for field in ["id", "created", "usage", "system_fingerprint", "object"]:
                if hasattr(response, field):
                    logger.log(level, f"{prefix} {field}: {getattr(response, field)}")

            # If there's data array, log details of each item
            if hasattr(response, "data") and response.data:
                for i, item in enumerate(response.data):
                    logger.log(
                        level, f"{prefix} data[{i}] properties available: {dir(item)}"
                    )
                    # Log interesting fields in the data items
                    for item_field in [
                        "revised_prompt",
                        "url",
                        "b64_json",
                        "finish_reason",
                    ]:
                        if hasattr(item, item_field):
                            value = getattr(item, item_field)
                            # Truncate long values
                            if isinstance(value, str) and len(value) > 100:
                                value = value[:100] + "..."
                            logger.log(
                                level, f"{prefix} data[{i}].{item_field}: {value}"
                            )
        except Exception as e:
            logger.warning(f"Error logging Together API response: {e}")

    def _generate_image_together(
        self, prompt: str
    ) -> Union[Optional[bytes], Tuple[bytes, str]]:
        """
        Generate image using Together AI and return image bytes.

        Returns:
            Either just the image data (bytes) or a tuple of (image_data, image_url)
            if the image was downloaded from a URL.
        """
        try:
            logger.debug(
                f"Calling Together AI API model={self.image_model_name}, height={self.height}, width={self.width}"
            )

            # Base parameters
            params = {
                "model": self.image_model_name,
                "prompt": prompt,
                "n": 1,
                "height": self.height,
                "width": self.width,
            }

            # Update with any additional model-specific parameters
            params.update(self.model_params)

            response = self.together_client.images.generate(**params)

            # Log successful response at debug level
            self._log_together_response(
                response, logging.DEBUG, "Together API success response"
            )

            # Check if image data is present in response
            if not response.data:
                logger.warning("Together AI API returned no data items.")
                self._log_together_response(
                    response, logging.WARNING, "Together API empty response"
                )
                return None

            data_item = response.data[0]

            # Try to get image data - either from base64 or by downloading from URL
            image_data = None
            image_url = None

            # Case 1: Base64 encoded image data
            if hasattr(data_item, "b64_json") and data_item.b64_json:
                logger.debug("Using base64 encoded image data from response")
                image_b64 = data_item.b64_json
                image_data = base64.b64decode(image_b64)
                return image_data  # Only return the image data in this case

            # Case 2: Image URL that needs to be downloaded
            elif hasattr(data_item, "url") and data_item.url:
                image_url = data_item.url
                logger.debug(f"Downloading image from URL: {image_url[:100]}...")

                try:
                    # Download the image from the URL
                    image_response = requests.get(image_url, timeout=60)
                    image_response.raise_for_status()
                    image_data = image_response.content
                    logger.debug(
                        f"Successfully downloaded image from URL, size: {len(image_data)} bytes"
                    )
                    # Return both the image data and the URL
                    return (image_data, image_url)
                except requests.exceptions.RequestException as e:
                    logger.error(f"Failed to download image from URL: {str(e)}")
                    return None

            # No usable image data found
            else:
                logger.warning(
                    "Together AI API response contained no usable image data (neither b64_json nor url)."
                )
                self._log_together_response(
                    response,
                    logging.WARNING,
                    "Together API response without image data",
                )
                return None

            # Validate and return the image data
            if image_data:
                logger.debug(
                    f"Image generated by Together AI, size: {len(image_data)} bytes"
                )
                return image_data
            else:
                return None

        except together.error.RateLimitError as e:
            logger.error(f"Together AI Rate Limit Error: {e}")
            # Log detailed error info if available
            if hasattr(e, "response") and e.response:
                logger.error(
                    f"Rate limit details: Status {e.response.status_code}, {e.response.text}"
                )
                try:
                    # Try to parse response JSON
                    if hasattr(e.response, "json"):
                        error_data = e.response.json()
                        logger.error(f"Rate limit error details: {error_data}")
                except Exception as json_err:
                    logger.debug(
                        f"Could not parse rate limit error response as JSON: {json_err}"
                    )
            raise e  # Re-raise for handling in the main loop
        except together.error.AuthenticationError as e:
            logger.error(f"Together AI Authentication Error: {e}")
            # Log detailed error info if available
            if hasattr(e, "response") and e.response:
                logger.error(
                    f"Auth error details: Status {e.response.status_code}, {e.response.text}"
                )
                try:
                    # Try to parse response JSON
                    if hasattr(e.response, "json"):
                        error_data = e.response.json()
                        logger.error(f"Auth error details: {error_data}")
                except Exception as json_err:
                    logger.debug(
                        f"Could not parse auth error response as JSON: {json_err}"
                    )
            # This is likely not recoverable by retry, raise it or return None
            raise e
        except together.error.ResponseError as e:  # Catch other API errors
            logger.error(f"Together AI API Response Error: {e}")
            # Log detailed error info if available
            if hasattr(e, "response") and e.response:
                logger.error(
                    f"Error response details: Status {e.response.status_code}, {e.response.text}"
                )
                try:
                    # Try to parse response JSON
                    if hasattr(e.response, "json"):
                        error_data = e.response.json()
                        logger.error(f"API error details: {error_data}")
                except Exception as json_err:
                    logger.debug(
                        f"Could not parse API error response as JSON: {json_err}"
                    )
            # Depending on the error, could retry or fail
            return None
        except together.error.InvalidRequestError as e:
            logger.error(f"Together AI Invalid Request Error: {e}")
            # Log detailed error info
            if hasattr(e, "response") and e.response:
                logger.error(
                    f"Request error details: Status {e.response.status_code}, {e.response.text}"
                )
                try:
                    # Try to parse response JSON
                    if hasattr(e.response, "json"):
                        error_data = e.response.json()
                        logger.error(f"Request error details: {error_data}")
                except Exception as json_err:
                    logger.debug(
                        f"Could not parse request error response as JSON: {json_err}"
                    )
            if hasattr(e, "request") and e.request:
                logger.error(f"Invalid request details: {e.request.body}")
            return None
        except Exception as e:
            logger.exception(f"Together AI API call failed: {e}")
            return None

    def generate_missing_images(self, limit: Optional[int] = None) -> Dict:
        """Generate images for all missing evidence records."""
        missing_evidence = self.get_missing_evidence(limit)
        results = {
            "total_missing": len(missing_evidence),
            "attempted": 0,
            "successful": 0,
            "failed": 0,
            "details": [],
        }
        if not missing_evidence:
            return results
        logger.info(
            f"Starting image generation for {len(missing_evidence)} records using {self.provider}..."
        )

        for evidence in tqdm(missing_evidence, desc="Generating images"):
            results["attempted"] += 1
            start_time = time.time()
            generated_path: Optional[str] = None
            error_info: str = "Unknown error"
            try:
                time.sleep(self.rate_limit_delay if results["attempted"] > 1 else 0)
                generated_path = self.generate_image(evidence)
            except KeyboardInterrupt:
                logger.warning("Image generation interrupted by user.")
                results["details"].append(
                    {
                        "evidence_id": evidence["evidence_id"],
                        "status": "interrupted",
                        "error": "User interrupted",
                        "prompt": self.generate_prompt(evidence),
                        "duration_s": round(time.time() - start_time, 2),
                    }
                )
                break
            except Exception as e:
                logger.exception(
                    f"Critical error during generation loop for {evidence['evidence_id']}: {e}"
                )
                error_info = f"Loop error: {e}"

            elapsed_time = time.time() - start_time
            if generated_path:
                results["successful"] += 1
                results["details"].append(
                    {
                        "evidence_id": evidence["evidence_id"],
                        "status": "success",
                        "path": generated_path,
                        "prompt": self.generate_prompt(evidence),
                        "duration_s": round(elapsed_time, 2),
                    }
                )
            else:
                results["failed"] += 1
                results["details"].append(
                    {
                        "evidence_id": evidence["evidence_id"],
                        "status": "failed",
                        "error": f"Image generation failed after retries (check logs). Last error context: {error_info}",
                        "prompt": self.generate_prompt(evidence),
                        "duration_s": round(elapsed_time, 2),
                    }
                )
                time.sleep(self.rate_limit_delay * 1.5)

        # Calculate remaining missing after this run
        remaining_missing = results["total_missing"] - results["successful"]

        logger.info(f"Image generation complete:")
        logger.info(f"  Initially Missing: {results['total_missing']}")
        logger.info(f"  Generation Attempted: {results['attempted']}")
        logger.info(f"  Successfully Generated: {results['successful']}")
        logger.info(f"  Failed to Generate: {results['failed']}")
        logger.info(f"  Remaining Missing: {remaining_missing}")

        return results

    def __del__(self):
        """Clean up database connection."""
        if hasattr(self, "conn") and self.conn:
            try:
                self.conn.close()
                logger.info("Database connection closed.")
            except Exception as e:
                logger.error(f"Error closing database connection: {e}")

    def test_prompt_generation(self, evidence_id: str) -> None:
        """Test prompt generation for a specific evidence record."""
        # Query the evidence record
        self.cursor.execute(
            """
            SELECT e.id, e.thing_id, e.thing_account_id, e.evidence_type,
                   t.title, t.description, t.category, t.brand, t.model, t.color,
                   e.data as evidence_data,
                   e.local_file
            FROM evidence e
            LEFT JOIN things t ON e.thing_id = t.id AND e.thing_account_id = t.account_id
            WHERE e.id = ?
        """,
            (evidence_id,),
        )
        row = self.cursor.fetchone()
        if not row:
            logger.error(f"Evidence record {evidence_id} not found")
            return

        # Create evidence dictionary
        evidence = {
            k: v
            for k, v in zip(
                [
                    "evidence_id",
                    "thing_id",
                    "account_id",
                    "evidence_type",
                    "thing_title",
                    "thing_description",
                    "category",
                    "brand",
                    "model",
                    "color",
                    "evidence_data",
                    "local_file",
                ],
                row,
            )
        }

        # Parse evidence data
        try:
            evidence["evidence_data"] = (
                json.loads(row[10]) if row[10] and row[10] != "null" else {}
            )
        except json.JSONDecodeError:
            logger.warning(f"Failed to parse evidence data for ID {evidence_id}")
            evidence["evidence_data"] = {}

        # Extract the original file extension
        original_path = evidence.get("local_file", "")
        relative_path = original_path.lstrip("/")
        file_path = self.output_dir / relative_path

        # Check if the file exists locally, and try to recover if not
        if not file_path.exists():
            logger.warning(f"Test image file doesn't exist at {file_path}")

            # Try to recover from URLs
            # 1. Check for URL in evidence data
            image_url = evidence["evidence_data"].get("image_url") or evidence[
                "evidence_data"
            ].get("url")

            # 2. If no URL in evidence data, check image_assets table
            if not image_url:
                try:
                    self.cursor.execute(
                        """
                        SELECT original_url, alt_url 
                        FROM image_assets 
                        WHERE path = ?
                    """,
                        (relative_path,),
                    )

                    url_row = self.cursor.fetchone()
                    if url_row and url_row[0]:
                        image_url = url_row[0]  # original_url
                    elif url_row and url_row[1]:
                        image_url = url_row[1]  # alt_url
                except Exception as e:
                    logger.warning(
                        f"Error querying image_assets table for {evidence_id}: {e}"
                    )

            # 3. If we found a URL, try to download the image
            if image_url:
                logger.info(
                    f"Found URL for missing test image {evidence_id}: {image_url[:100]}..."
                )
                if self._recover_image_from_url(image_url, file_path):
                    logger.info(f"Successfully recovered test image to {file_path}")
                else:
                    logger.warning(f"Could not recover test image from URL")

        # Determine if this is a document
        evidence_data = evidence.get("evidence_data", {})
        evidence_type = evidence_data.get("type", "")
        document_type = evidence_data.get("document_type", "")
        is_document = (
            document_type != ""
            or evidence_type.lower()
            in [
                "document",
                "receipt",
                "invoice",
                "certificate",
                "letter",
                "id",
                "identification",
            ]
            or (
                evidence.get("category", "").lower()
                in [
                    "document",
                    "documents",
                    "paperwork",
                    "certificate",
                    "identification",
                ]
            )
        )

        # Get the file extension
        original_ext = Path(original_path).suffix.lower() if original_path else ".png"

        # Default to PNG if no extension or unsupported extension
        if original_ext not in [".jpg", ".jpeg", ".png"]:
            logger.debug(
                f"Unsupported extension '{original_ext}' for test prompt, defaulting to PNG"
            )
            original_ext = ".png"

        # Determine save format
        save_format = "PNG" if original_ext.lower() == ".png" else "JPEG"

        # Generate the prompt
        prompt = self.generate_prompt(evidence)
        logger.info(f"Generated prompt for {evidence_id}: {prompt}")
        logger.info(
            f"Testing prompt with {self.provider} provider, will save as {save_format}..."
        )

        # Log analytics for the prompt
        self._log_prompt_analytics(prompt, evidence_id, is_document)

        # Test with the provider's API
        try:
            if self.provider == "google":
                response = self.google_model.generate_images(
                    prompt=prompt, number_of_images=1
                )
                logger.info(
                    f"Prompt accepted by Google Vertex AI. Response snippet: {str(response)[:200]}..."
                )
            elif self.provider == "openai":
                response = self.openai_client.images.generate(
                    model=self.image_model_name,
                    prompt=prompt,
                    size=self.image_size,
                    quality=self.image_quality,
                    n=1,
                )
                logger.info(
                    f"Prompt accepted by OpenAI DALL-E API. Response snippet: {str(response)[:200]}..."
                )
            elif self.provider == "azure":
                response = self.azure_client.images.generate(
                    model=self.image_model_name,
                    prompt=prompt,
                    size=self.image_size,
                    quality=self.image_quality,
                    n=1,
                )
                logger.info(
                    f"Prompt accepted by Azure OpenAI API. Response snippet: {str(response)[:200]}..."
                )
            elif self.provider == "together":
                # Use the specific parameters for together
                params = {
                    "model": self.image_model_name,
                    "prompt": prompt,
                    "n": 1,
                    "height": self.height,
                    "width": self.width,
                }
                # Update with any model-specific parameters
                params.update(self.model_params)
                response = self.together_client.images.generate(**params)
                logger.info(f"Prompt accepted by Together AI API.")
                # Log detailed response information
                self._log_together_response(
                    response, logging.INFO, "Together test prompt response"
                )

                # Check and report if it's using URL or base64
                if response.data and len(response.data) > 0:
                    data_item = response.data[0]
                    if hasattr(data_item, "b64_json") and data_item.b64_json:
                        logger.info("Together API returned a base64-encoded image")

                        # Save the test image if not in dry run mode
                        if not self.dry_run:
                            try:
                                # Decode base64 data
                                image_data = base64.b64decode(data_item.b64_json)

                                # Process and save with the correct format
                                img = PILImage.open(io.BytesIO(image_data))
                                test_filename = f"test_prompt_{evidence_id}_{datetime.now():%Y%m%d_%H%M%S}{original_ext}"
                                test_filepath = self.output_dir / test_filename

                                # Handle format conversion
                                save_options = {}
                                if save_format == "JPEG":
                                    save_options["quality"] = 95
                                    # Convert RGBA to RGB if needed
                                    if img.mode == "RGBA":
                                        background = PILImage.new(
                                            "RGB", img.size, (255, 255, 255)
                                        )
                                        background.paste(img, mask=img.split()[3])
                                        img = background

                                img.save(
                                    test_filepath, format=save_format, **save_options
                                )
                                logger.info(
                                    f"Test image saved to {test_filepath} as {save_format}"
                                )
                            except Exception as img_err:
                                logger.error(f"Failed to save test image: {img_err}")

                    elif hasattr(data_item, "url") and data_item.url:
                        logger.info(
                            f"Together API returned an image URL: {data_item.url[:100]}..."
                        )
                        # Optionally save the test image
                        if not self.dry_run:
                            test_filename = f"test_prompt_{evidence_id}_{datetime.now():%Y%m%d_%H%M%S}{original_ext}"
                            test_filepath = self.output_dir / test_filename
                            if self._recover_image_from_url(
                                data_item.url, test_filepath
                            ):
                                logger.info(f"Test image saved to {test_filepath}")
                            else:
                                logger.error(f"Failed to save test image from URL")

        except Exception as e:
            logger.error(f"Error testing prompt with {self.provider}: {str(e)}")
            logger.error(f"Tested prompt was: {prompt}")
            # For Together errors, try to log more details
            if self.provider == "together":
                if hasattr(e, "response") and e.response:
                    logger.error(
                        f"Together API error response: Status {e.response.status_code}, {e.response.text}"
                    )
                    try:
                        if hasattr(e.response, "json"):
                            error_data = e.response.json()
                            logger.error(f"Together API error details: {error_data}")
                    except Exception as json_err:
                        logger.debug(
                            f"Could not parse Together API error response as JSON: {json_err}"
                        )

    def _log_prompt_analytics(
        self, prompt: str, evidence_id: str, is_document: bool = None
    ) -> None:
        """
        Log analytics about the prompt to help track which variants are being used
        and potentially correlate with image quality later.

        Args:
            prompt: The generated prompt
            evidence_id: The ID of the evidence record
            is_document: Whether the evidence is a document (if known)
        """
        try:
            # Try to infer if this is a document from the prompt if not explicitly provided
            if is_document is None:
                is_document = "document type:" in prompt or any(
                    term in prompt.lower()
                    for term in [
                        "receipt",
                        "invoice",
                        "certificate",
                        "letter",
                        "id",
                        "identification",
                    ]
                )

            # Identify which base prompt was used
            base_prompts = [
                "A clear, well-lit photograph of",
                "A detailed product image showing",
                "A realistic documentary photo capturing",
                "A high-resolution image displaying",
                "A photographic record showing",
            ]

            base_used = None
            for bp in base_prompts:
                if prompt.startswith(bp):
                    base_used = bp
                    break

            # Identify which context variant was used
            context_variants = [
                "on an isolated white background",
                "as a hero shot",
                "held in a hand",
                "showing the back side",
                "placed on a neutral surface",
            ]

            context_used = None
            for cv in context_variants:
                if cv in prompt:
                    context_used = cv
                    break

            prompt_info = {
                "evidence_id": evidence_id,
                "base_prompt": base_used or "custom",
                "context_variant": context_used or "custom",
                "prompt_length": len(prompt),
                "has_type_info": "type:" in prompt,
                "has_document_type": "document type:" in prompt,
                "is_document": is_document,
                "timestamp": datetime.now().isoformat(),
            }

            log_entry = json.dumps(prompt_info)
            logger.info(f"Prompt analytics: {log_entry}")

            # Optionally: save to a database or file for later analysis
            # self.cursor.execute("""
            #    INSERT INTO prompt_analytics (evidence_id, base_prompt, context_variant, prompt_length, timestamp, prompt_full, is_document)
            #    VALUES (?, ?, ?, ?, ?, ?, ?)
            # """, (evidence_id, base_used or "custom", context_used or "custom", len(prompt), datetime.now().timestamp(), prompt, is_document))
            # self.conn.commit()

        except Exception as e:
            logger.debug(f"Error logging prompt analytics: {e}")
            # Non-critical, so just log and continue

    def _recover_image_from_url(self, url: str, file_path: Path) -> bool:
        """
        Attempt to download and save an image from a URL to a file path.

        Args:
            url: The URL to download from
            file_path: The path to save the file to

        Returns:
            bool: True if successful, False otherwise
        """
        if not url:
            return False

        try:
            # Create parent directories if they don't exist
            file_path.parent.mkdir(parents=True, exist_ok=True)

            # Download the image
            logger.debug(f"Downloading image from URL: {url[:100]}...")
            response = requests.get(url, timeout=60)
            response.raise_for_status()

            # Validate that this is an image
            image_data = response.content
            try:
                img = PILImage.open(io.BytesIO(image_data))

                # Get the format and extension
                img_format = img.format
                logger.debug(f"Downloaded image format: {img_format}")

                # Save with appropriate format
                # For JPEG files, ensure RGB mode (no alpha channel)
                if img_format == "JPEG" and img.mode == "RGBA":
                    background = PILImage.new("RGB", img.size, (255, 255, 255))
                    background.paste(
                        img, mask=img.split()[3]
                    )  # Use alpha channel as mask
                    img = background

                # Save the image
                img.save(file_path)
            except Exception as e:
                # If PIL processing fails, just save the raw data
                logger.warning(f"PIL processing failed for URL image: {e}")
                with open(file_path, "wb") as f:
                    f.write(image_data)

            logger.info(f"Successfully saved image to {file_path}")

            # Also save to image_assets if it's not already there
            path = (
                str(file_path.relative_to(self.output_dir))
                if self.output_dir in file_path.parents
                else str(file_path)
            )
            self._save_to_image_assets(path, image_data, url)

            return True

        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to download image from URL: {e}")
            return False
        except Exception as e:
            logger.error(f"Error recovering image from URL: {e}")
            return False


def main():
    # Test each provider if configured

    # Google Cloud
    try:
        project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
        if not project_id:
            print("Skipping Google test: GOOGLE_CLOUD_PROJECT env var not set.")
        else:
            logger.info("\n--- Testing Google Provider ---")
            generator_google = EvidenceImageGenerator(
                provider="google", project_id=project_id
            )
            results_google = generator_google.generate_missing_images(limit=1)
            fname = f"generation_results_google_{datetime.now():%Y%m%d_%H%M%S}.json"
            results_file_google = generator_google.output_dir / fname
            with open(results_file_google, "w") as f:
                json.dump(results_google, f, indent=2)
            logger.info(f"Google results saved to {results_file_google}")
    except Exception as e:
        logger.error(f"Error in main (Google): {str(e)}")

    # OpenAI
    try:
        if not os.getenv("OPENAI_API_KEY"):
            print("Skipping OpenAI test: OPENAI_API_KEY env var not set.")
        else:
            logger.info("\n--- Testing OpenAI Provider ---")
            # Example with custom OpenAI parameters
            openai_params = {
                "style": "natural",  # DALL-E 3 specific (natural or vivid)
                "user": "test-user",  # For OpenAI usage tracking
            }
            generator_openai = EvidenceImageGenerator(
                provider="openai", image_model="dall-e-3", model_params=openai_params
            )
            results_openai = generator_openai.generate_missing_images(limit=1)
            fname = f"generation_results_openai_{datetime.now():%Y%m%d_%H%M%S}.json"
            results_file_openai = generator_openai.output_dir / fname
            with open(results_file_openai, "w") as f:
                json.dump(results_openai, f, indent=2)
            logger.info(f"OpenAI results saved to {results_file_openai}")
    except Exception as e:
        logger.error(f"Error in main (OpenAI): {str(e)}")

    # Azure OpenAI
    try:
        if not all(
            os.getenv(k)
            for k in [
                "AZURE_OPENAI_API_KEY",
                "AZURE_OPENAI_ENDPOINT",
                "AZURE_OPENAI_DEPLOYMENT_NAME",
                "AZURE_OPENAI_API_VERSION",
            ]
        ):
            print("Skipping Azure test: Required Azure environment variables not set.")
        else:
            logger.info("\n--- Testing Azure Provider ---")
            generator_azure = EvidenceImageGenerator(provider="azure")
            results_azure = generator_azure.generate_missing_images(limit=1)
            fname = f"generation_results_azure_{datetime.now():%Y%m%d_%H%M%S}.json"
            results_file_azure = generator_azure.output_dir / fname
            with open(results_file_azure, "w") as f:
                json.dump(results_azure, f, indent=2)
            logger.info(f"Azure results saved to {results_file_azure}")
    except Exception as e:
        logger.error(f"Error in main (Azure): {str(e)}")

    # Together AI
    try:
        if not os.getenv("TOGETHER_API_KEY"):
            print("Skipping Together AI test: TOGETHER_API_KEY env var not set.")
        else:
            logger.info("\n--- Testing Together AI Provider ---")
            # Example using default Stable Diffusion model with advanced parameters
            together_params = {
                "steps": 50,  # Number of diffusion steps
                "cfg_scale": 7.0,  # Classifier-free guidance scale
                "seed": 42,  # Random seed for reproducibility
            }
            generator_together = EvidenceImageGenerator(
                provider="together",
                image_model="stabilityai/stable-diffusion-v1-5",
                model_params=together_params,
            )
            results_together = generator_together.generate_missing_images(limit=1)
            fname = f"generation_results_together_{datetime.now():%Y%m%d_%H%M%S}.json"
            results_file_together = generator_together.output_dir / fname
            with open(results_file_together, "w") as f:
                json.dump(results_together, f, indent=2)
            logger.info(f"Together AI results saved to {results_file_together}")
    except Exception as e:
        logger.error(f"Error in main (Together AI): {str(e)}")


if __name__ == "__main__":
    main()

# The preview functionality has been moved to gen_preview.py
