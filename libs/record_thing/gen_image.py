import os
import openai
from pathlib import Path
import requests
from datetime import datetime
import json
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ThingImageGenerator:
    def __init__(self, api_key=None):
        """Initialize the image generator with OpenAI API key."""
        self.api_key = api_key or os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OpenAI API key is required")
        openai.api_key = self.api_key
        
        # Create output directory if it doesn't exist
        self.output_dir = Path("record-thing/apps/libs/record_thing/db/sample_images")
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Load category mappings
        self.category_prompts = {
            "watches": "A professional product photograph of a luxury watch on a white background, showing clear details of the watch face and band",
            "bags": "A professional product photograph of a designer handbag on a white background, showing clear details of the leather and hardware",
            "shoes": "A professional product photograph of luxury shoes on a white background, showing clear details of the design and materials",
            "accessories": "A professional product photograph of luxury accessories on a white background, showing clear details of the craftsmanship",
            "jewelry": "A professional product photograph of fine jewelry on a white background, showing clear details of the stones and metalwork",
            "clothing": "A professional product photograph of luxury clothing on a white background, showing clear details of the fabric and design",
            "other": "A professional product photograph of a luxury item on a white background, showing clear details of the product"
        }

    def generate_image(self, category: str, thing_name: str) -> str:
        """
        Generate an image for a thing based on its category and name.
        
        Args:
            category: The category of the thing (e.g., "watches", "bags")
            thing_name: The name of the thing
            
        Returns:
            str: Path to the generated image file
        """
        try:
            # Get the base prompt for the category
            base_prompt = self.category_prompts.get(category.lower(), self.category_prompts["other"])
            
            # Create a specific prompt for this thing
            prompt = f"{base_prompt}. The item is a {thing_name}. The image should be high resolution and suitable for e-commerce."
            
            logger.info(f"Generating image for {thing_name} in category {category}")
            
            # Call DALL-E API
            response = openai.images.generate(
                model="dall-e-3",
                prompt=prompt,
                size="1024x1024",
                quality="standard",
                n=1
            )
            
            # Get the image URL
            image_url = response.data[0].url
            
            # Download the image
            image_response = requests.get(image_url)
            image_response.raise_for_status()
            
            # Create a filename based on the thing name and timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{thing_name.lower().replace(' ', '_')}_{timestamp}.png"
            filepath = self.output_dir / filename
            
            # Save the image
            with open(filepath, 'wb') as f:
                f.write(image_response.content)
            
            logger.info(f"Image saved to {filepath}")
            return str(filepath)
            
        except Exception as e:
            logger.error(f"Error generating image: {str(e)}")
            raise

    def generate_sample_images(self, things_data: list):
        """
        Generate images for a list of things.
        
        Args:
            things_data: List of dictionaries containing thing information
                       [{"name": "Thing Name", "category": "category_name"}, ...]
        """
        results = []
        for thing in things_data:
            try:
                image_path = self.generate_image(thing["category"], thing["name"])
                results.append({
                    "name": thing["name"],
                    "category": thing["category"],
                    "image_path": image_path
                })
            except Exception as e:
                logger.error(f"Failed to generate image for {thing['name']}: {str(e)}")
                results.append({
                    "name": thing["name"],
                    "category": thing["category"],
                    "error": str(e)
                })
        return results

def main():
    # Example usage
    sample_things = [
        {"name": "Rolex Submariner", "category": "watches"},
        {"name": "Louis Vuitton Neverfull", "category": "bags"},
        {"name": "Gucci Loafers", "category": "shoes"},
        {"name": "Cartier Love Bracelet", "category": "jewelry"}
    ]
    
    try:
        generator = ThingImageGenerator()
        results = generator.generate_sample_images(sample_things)
        
        # Save results to a JSON file
        results_file = Path("record-thing/apps/libs/record_thing/db/sample_images/generation_results.json")
        with open(results_file, 'w') as f:
            json.dump(results, f, indent=2)
            
        logger.info(f"Results saved to {results_file}")
        
    except Exception as e:
        logger.error(f"Error in main: {str(e)}")

if __name__ == "__main__":
    main()
    