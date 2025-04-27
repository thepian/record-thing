import os
import requests
from pathlib import Path
import logging
import time
import pandas as pd
from typing import Dict, Optional, List, Tuple
from datetime import datetime
import io
from PIL import Image as PILImage
import matplotlib.pyplot as plt
from tqdm import tqdm
from IPython.display import Image, display

# Import from gen_evidence module
from ..gen_evidence import EvidenceImageGenerator, DBP, logger, together

class PreviewImageGenerator(EvidenceImageGenerator):
    def __init__(self, 
                 db_path: Path = DBP, 
                 provider: str = "openai", 
                 api_key: Optional[str] = None, 
                 azure_endpoint: Optional[str] = None, # Azure specific
                 api_version: Optional[str] = None,   # Azure specific
                 image_model: Optional[str] = None, # Model/Deployment name
                 project_id: Optional[str] = None, # Google specific
                 location: Optional[str] = "us-central1", # Google specific
                 model_params: Optional[Dict] = None # Additional model-specific parameters
                 ):
        
        # Initialize the parent class in dry_run mode
        super().__init__(
            db_path=db_path, 
            provider=provider, 
            api_key=api_key,
            azure_endpoint=azure_endpoint,
            api_version=api_version,
            image_model=image_model,
            project_id=project_id, 
            location=location,
            model_params=model_params,
            dry_run=True # Ensures parent doesn't update DB
        ) 
                         
        self.preview_dir = Path("preview_images")
        self.preview_dir.mkdir(parents=True, exist_ok=True)
        logger.info(f"Preview images will be saved to: {self.preview_dir}")
    
    # Override generate_image to ONLY save the file, not update the DB
    def generate_image(self, evidence: Dict) -> Optional[str]:
        """Generate an image without updating the database, saving to preview dir."""
        prompt = self.generate_prompt(evidence)
        evidence_id = evidence['evidence_id']
        logger.info(f"Generating preview image for evidence {evidence_id}")
        logger.debug(f"Using prompt: {prompt}")

        # Extract the original file extension from local_path
        original_path = evidence.get('local_file', '')
        original_ext = Path(original_path).suffix.lower() if original_path else '.png'
        
        # Default to PNG if no extension or unsupported extension
        if original_ext not in ['.jpg', '.jpeg', '.png']:
            logger.debug(f"Unsupported extension '{original_ext}' for preview {evidence_id}, defaulting to PNG")
            original_ext = '.png'
            
        logger.debug(f"Will save preview image as {original_ext} format for {evidence_id}")

        image_data: Optional[bytes] = None
        error_message: str = "Unknown error"

        for attempt in range(self.max_retries):
            try:
                 logger.info(f"Attempt {attempt + 1}/{self.max_retries} for preview {evidence_id}")
                 
                 # Call the appropriate private generation method directly
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
                         image_data, _ = result  # Discard the URL since we don't store it for previews
                     else:
                         image_data = result
                 else:
                    logger.error(f"Invalid provider for preview: {self.provider}")
                    return None

                 if image_data:
                    is_valid, validation_msg = self.validate_image(image_data)
                    if is_valid:
                        # Create filename with the correct extension
                        filename = f"preview_{evidence_id}{original_ext}"
                        filepath = self.preview_dir / filename
                        
                        # Handle format conversion if needed
                        try:
                            img = PILImage.open(io.BytesIO(image_data))
                            
                            # Determine format for saving
                            save_format = 'PNG' if original_ext.lower() == '.png' else 'JPEG'
                            
                            # Set quality for JPEG
                            save_options = {}
                            if save_format == 'JPEG':
                                save_options['quality'] = 95
                                # Convert RGBA to RGB if needed (JPEG doesn't support alpha channel)
                                if img.mode == 'RGBA':
                                    logger.debug(f"Converting RGBA to RGB for JPEG preview for {evidence_id}")
                                    # Create white background and paste the image on top
                                    background = PILImage.new('RGB', img.size, (255, 255, 255))
                                    background.paste(img, mask=img.split()[3])  # Use alpha channel as mask
                                    img = background
                            
                            # Save with appropriate format
                            img_buffer = io.BytesIO()
                            img.save(img_buffer, format=save_format, **save_options)
                            processed_image_data = img_buffer.getvalue()
                            
                            # Write to file
                            with open(filepath, 'wb') as f:
                                f.write(processed_image_data)
                                
                            logger.info(f"Preview image successfully saved to {filepath} as {save_format}")
                            
                        except Exception as e:
                            logger.error(f"Error processing preview image format: {e}")
                            # Fall back to saving raw image data
                            with open(filepath, 'wb') as f:
                                f.write(image_data)
                            logger.info(f"Preview image saved in original format to {filepath} (format conversion failed)")
                            
                        return str(filepath) 
                    else:
                        error_message = f"Image validation failed: {validation_msg}"
                        logger.warning(f"{error_message} for preview {evidence_id}")
                        # Optionally retry on validation failure
                        # time.sleep(self.rate_limit_delay)
                        # continue
                        return None 
                 else:
                     error_message = f"{self.provider.capitalize()} API call failed or returned no data."
                     if attempt < self.max_retries - 1:
                         wait_time = self.rate_limit_delay * (2 ** attempt)
                         logger.warning(f"Preview generation attempt {attempt + 1} failed. Retrying in {wait_time}s...")
                         time.sleep(wait_time)
                         continue
                     else:
                         logger.error(f"Max retries reached for preview {evidence_id}.")
                         return None
            
            except KeyboardInterrupt:
                logger.warning(f"Preview generation for {evidence_id} interrupted by user.")
                return None
            except Exception as e:
                logger.exception(f"Error generating preview for {evidence_id}: {e}")
                error_message = str(e)
                if attempt < self.max_retries - 1:
                    wait_time = self.rate_limit_delay * (2 ** attempt)
                    logger.warning(f"Preview generation attempt {attempt + 1} failed with error: {error_message}. Retrying in {wait_time}s...")
                    time.sleep(wait_time)
                else:
                    logger.error(f"All preview generation attempts failed for {evidence_id}: {error_message}")
                    return None

        return None  # All attempts failed


# Function to display generated images in the notebook
def display_generated_images(results: Dict):
    """Display generated images in a grid."""
    successful_images = [d for d in results.get('details', []) if d.get('status') == 'success' and 'path' in d]
    
    if not successful_images:
        print("No images were generated successfully to display.")
        return
    
    n_images = len(successful_images)
    n_cols = min(3, n_images)
    n_rows = (n_images + n_cols - 1) // n_cols
    
    plt.figure(figsize=(15, 5 * n_rows))
    
    for idx, image_data in enumerate(successful_images, 1):
        try:
            img_path = image_data['path']
            # Extract file extension
            ext = Path(img_path).suffix.lower()
            
            # Log the image format we're displaying
            if ext in ['.jpg', '.jpeg']:
                logger.debug(f"Displaying JPEG image: {img_path}")
            elif ext == '.png':
                logger.debug(f"Displaying PNG image: {img_path}")
            else:
                logger.debug(f"Displaying image with extension {ext}: {img_path}")
                
            # Open the image file
            img = PILImage.open(img_path)
            
            plt.subplot(n_rows, n_cols, idx)
            plt.imshow(img)
            title = f"Evidence ID: {image_data['evidence_id']}"
            
            # Add format info to title
            if ext:
                title += f" ({ext[1:].upper()})"
                
            plt.title(title)
            plt.axis('off')
        except FileNotFoundError:
             logger.error(f"Image file not found for display: {image_data['path']}")
        except Exception as e:
             logger.error(f"Error displaying image {image_data['path']}: {e}")

    plt.tight_layout()
    plt.show()


# Example usage in notebook
def generate_preview_images(provider: str = "openai", limit: int = 3, 
                           api_key: Optional[str] = None, 
                           azure_endpoint: Optional[str] = None,
                           api_version: Optional[str] = None,
                           image_model: Optional[str] = None, # Deployment name for Azure/Together
                           project_id: Optional[str] = None, 
                           location: Optional[str] = "us-central1",
                           model_params: Optional[Dict] = None):
    """Generate and display preview images for a limited number of evidence records."""
    # This function signature now includes model_params for advanced configuration
    try:
        generator = PreviewImageGenerator(
            provider=provider, api_key=api_key, azure_endpoint=azure_endpoint, 
            api_version=api_version, image_model=image_model, 
            project_id=project_id, location=location, model_params=model_params
        )
        
        missing_evidence = generator.get_missing_evidence(limit=limit) 
        
        if not missing_evidence:
             logger.info("No missing evidence found to generate previews for.")
             return None
        
        results = { # Initialize results dictionary
            "total_missing": len(missing_evidence), "attempted": 0,
            "successful": 0, "failed": 0, "details": []
        }
        
        for evidence in tqdm(missing_evidence, desc=f"Generating {provider} previews"):
            results["attempted"] += 1
            start_time = time.time()
            generated_path: Optional[str] = None
            error_info: str = "Unknown error"
            try:
                time.sleep(generator.rate_limit_delay if results["attempted"] > 1 else 0)
                generated_path = generator.generate_image(evidence) 
            except KeyboardInterrupt:
                 logger.warning("Preview generation interrupted.")
                 results["details"].append({"evidence_id": evidence["evidence_id"], "status": "interrupted", "error": "User interrupted", "prompt": generator.generate_prompt(evidence), "duration_s": round(time.time() - start_time, 2)})
                 break
            except Exception as e:
                logger.exception(f"Critical error during preview loop for {evidence['evidence_id']}: {e}")
                error_info = f"Loop error: {e}"

            elapsed_time = time.time() - start_time
            if generated_path:
                results["successful"] += 1
                results["details"].append({"evidence_id": evidence["evidence_id"], "status": "success", "path": generated_path, "prompt": generator.generate_prompt(evidence), "duration_s": round(elapsed_time, 2)})
            else:
                results["failed"] += 1
                results["details"].append({"evidence_id": evidence["evidence_id"], "status": "failed", "error": f"Preview generation failed (check logs). Last error context: {error_info}", "prompt": generator.generate_prompt(evidence), "duration_s": round(elapsed_time, 2)})
                # time.sleep(generator.rate_limit_delay * 1.5) # Optional increased delay

        print(f"\nPreview Generation Summary ({provider}):")
        print(f"  Attempted: {results['attempted']}")
        print(f"  Successful: {results['successful']}")
        print(f"  Failed: {results['failed']}")
        
        if results['details']:
            df = pd.DataFrame(results['details'])
            display(df[['evidence_id', 'status', 'prompt', 'error', 'duration_s', 'path']].fillna('N/A')) # Display relevant columns
            if results['successful'] > 0: display_generated_images(results)
        
        return results
        
    except Exception as e:
        print(f"Error initializing or running preview generation: {str(e)}")
        return None


# Example usage
"""
# Together AI Preview with advanced parameters
together_params = {"steps": 50, "cfg_scale": 8.0, "seed": 123}
results_together = generate_preview_images(
    provider="together", 
    limit=2, 
    image_model="runwayml/stable-diffusion-v1-5",
    model_params=together_params
) 

# Azure Preview with custom parameters
azure_params = {"user": "test-user"}
results_azure = generate_preview_images(
    provider="azure", 
    limit=2,
    model_params=azure_params
)

# Google Preview with custom parameters
google_params = {"aspect_ratio": "1:1"}
results_google = generate_preview_images(
    provider="google", 
    limit=2,
    model_params=google_params
)

# OpenAI Preview with custom parameters
openai_params = {"style": "vivid"}
results_openai = generate_preview_images(
    provider="openai", 
    limit=2,
    model_params=openai_params
)
"""

if __name__ == "__main__":
    # Simple demo of the preview generator
    print("Running preview generator demo...")
    results = generate_preview_images(limit=1)
    print(f"Preview generation completed with {results['successful']} successful generations.") 