# Record thing library

## Generating images for incomplete Evidence records (EvidenceImageGenerator)

Follow the steps in `record-thing.ipynb` to generate images for incomplete Evidence records in record-thing.sqlite.

It will run through the evidence table and generate image file if not found based on the `local_path` field. Use the information for the related things record to generate the image. The `local_path` field is a relative path pointing to a unique image asset. There is no need to generate the image if it already exists and no need to change the `local_path`.

Provide options for using OpenAI and Google APIs. Provide candidates for a well working prompt.

Evidence records refer to images or short video clips recorded by a user of a single subject. Typically this will be of a personal belonging or related documents. The image will be evaluated by ML models to tag and categorise the evidence. The image will be the raw recording and in no way stylised or processed. The subject will generally be fully in view, take up most of the space and be suitable as training data.
Images are typically recorded using a mobile phone camera in portrait mode. EXIF data is added to reflect the time and date of the recording. The image is not intended to be used as a final product, but rather as a demo for the evidence record.

Step 1: Generate a list of evidence records that are missing images and the related things fields.
Step 2: Generate the images using OpenAI or Google APIs.
Step 3: Save the images to the local path specified in the evidence record.
Step 4: Log the generated evidence incl prompt and local path to a log file.

The generator should have a flag for dry-run mode, which will not generate the images but will print the prompt and the local path to the console. This is useful for testing and debugging the generator.

```
# Basic usage
generator = EvidenceImageGenerator()
results = generator.generate_missing_images(limit=5)

# Dry run mode
generator = EvidenceImageGenerator(dry_run=True)
results = generator.generate_missing_images()

# With custom configuration
generator = EvidenceImageGenerator(
    api_key="your-api-key",
    db_path="custom/path/db.sqlite",
    dry_run=False
)
generator.rate_limit_delay = 2  # 2 seconds between API calls
generator.max_retries = 5
results = generator.generate_missing_images(limit=10)
```

## Production Service Plan for Together.ai Integration

When deploying the EvidenceImageGenerator in production with Together.ai as the provider, consider the following best practices to ensure reliable and efficient operation:

### API Key Management

- Store the Together.ai API key in environment variables or a secure secret management service
- Rotate API keys periodically according to your organization's security policies
- Use different API keys for development, staging, and production environments

```python
import os
from dotenv import load_dotenv

# Load API key from environment
load_dotenv()
api_key = os.getenv("TOGETHER_API_KEY")

generator = EvidenceImageGenerator(
    provider="together",
    api_key=api_key,
    image_model="stabilityai/stable-diffusion-v1-5"
)
```

### Error Handling and Resilience

- Implement exponential backoff for rate limiting errors (already built into the generator)
- Configure appropriate timeout values for API calls
- Set up monitoring and alerting for Together.ai API service disruptions
- Consider implementing a circuit breaker pattern for catastrophic failures

```python
# Configure with higher retry counts and longer delays for production
generator = EvidenceImageGenerator(
    provider="together",
    image_model="stabilityai/stable-diffusion-v1-5"
)
generator.max_retries = 8  # More retries in production
generator.rate_limit_delay = 5  # Longer delay between retries
```

### Monitoring and Logging

- Set up structured logging to capture all API interactions
- Monitor Together.ai API response times and success rates
- Track quota usage to avoid unexpected service disruptions
- Implement application-level metrics for image generation performance

```python
import logging

# Configure advanced logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("together_api.log"),
        logging.StreamHandler()
    ]
)
```

### Scaling and Performance

- For bulk processing, implement a job queue system (e.g., Celery, AWS SQS)
- Process images in batches to optimize throughput while respecting rate limits
- Consider using a distributed worker pattern for high-volume image generation

```python
# Example of batch processing with rate limiting
def process_evidence_batch(batch_size=50, delay_between_batches=60):
    generator = EvidenceImageGenerator(provider="together")
    
    # Get all missing evidence
    all_missing = generator.get_missing_evidence()
    
    # Process in batches
    for i in range(0, len(all_missing), batch_size):
        batch = all_missing[i:i+batch_size]
        print(f"Processing batch {i//batch_size + 1} of {(len(all_missing) + batch_size - 1)//batch_size}")
        
        # Process this batch
        for evidence in batch:
            generator.generate_image(evidence)
            
        # Wait between batches to avoid overwhelming the API
        if i + batch_size < len(all_missing):
            time.sleep(delay_between_batches)
```

### Fallback Mechanisms

- Implement provider fallback chains to handle service disruptions
- Configure alternative Together.ai models as backup options
- Consider multi-provider strategies for critical workloads

```python
def generate_with_fallback(evidence):
    # Try primary model
    generator = EvidenceImageGenerator(
        provider="together",
        image_model="stabilityai/stable-diffusion-v1-5"
    )
    
    result = generator.generate_image(evidence)
    if result:
        return result
        
    # Fallback to alternative model
    generator = EvidenceImageGenerator(
        provider="together",
        image_model="stabilityai/stable-diffusion-xl-base-1.0"
    )
    
    result = generator.generate_image(evidence)
    if result:
        return result
    
    # Final fallback to OpenAI
    generator = EvidenceImageGenerator(
        provider="openai", 
        image_model="dall-e-3"
    )
    
    return generator.generate_image(evidence)
```

### Cost Management

- Track API usage and associated costs
- Set up billing alerts in both Together.ai dashboard and your monitoring system
- Implement usage quotas for different application components
- Consider caching generated images for frequently requested evidence

### Regular Testing

- Periodically test the connection to Together.ai APIs
- Validate that saved images meet quality standards
- Ensure proper handling of different image formats (PNG, JPEG)
- Test format conversions and alpha channel handling

```python
# Regular health check function
def check_together_api_health():
    test_evidence_id = "sample_evidence_123"  # A known evidence ID
    generator = EvidenceImageGenerator(provider="together")
    generator.test_prompt_generation(test_evidence_id)
    # Check logs for successful response
```

By following these best practices, you can ensure a reliable, efficient, and cost-effective integration with Together.ai for your production environment.


### Prompt engineering

We want to construct prompt for generating demo recordings of evidence.

```
You are a prompt engineer creating a prompt template for generating demo assets for an iPhone App. You will create a variation of prompts to try out and a way to evaluate the efficacy.

Evidence records refer to images or short video clips recorded by a user of a single subject. Typically this will be of a personal belonging or related documents. The image will be evaluated by ML models to tag and categorise the evidence. The image will be the raw recording and in no way stylised or processed. The subject will generally be fully in view, take up most of the space and be suitable as training data. The user will photograph the subject from specific directions such as front, back, and side.
In terms of staging the user may record it on an isolated background such as resting on a white table, or mounted in complementary settings for a presentational hero shot.
Images are typically recorded using a mobile phone camera in portrait mode. EXIF data is added to reflect the time and date of the recording. The image is not intended to be used as a final product, but rather as a demo for the evidence record.
```


```
Make the .sync function support a local cache directory and specific files/directories all of which is mapped into the local tree being synced with the server. Also support configuration of write protected file paths locally that will not be modified by changes on the server.
```
