# Project Structure:
# image_scraper/
#   ├── image_scraper/
#   │   ├── __init__.py
#   │   ├── items.py
#   │   ├── middlewares.py
#   │   ├── pipelines.py
#   │   └── spiders/
#   │       ├── __init__.py
#   │       └── image_spider.py
#   ├── requirements.txt
#   └── scrapy.cfg

# requirements.txt
scrapy
Pillow
torch
torchvision
timm
aiofiles
aiosqlite

# scrapy.cfg
[settings]
default = image_scraper.settings

# settings.py (create in image_scraper directory)
BOT_NAME = 'image_scraper'

SPIDER_MODULES = ['image_scraper.spiders']
NEWSPIDER_MODULE = 'image_scraper.spiders'

# Middlewares
ITEM_PIPELINES = {
    'image_scraper.middlewares.DinoV2EmbeddingMiddleware': 300,
    'image_scraper.pipelines.SQLitePipeline': 800,
}

# Image storage settings
IMAGES_STORE = './downloads'
SQLITE_DB_PATH = './images.db'

# Recommended settings for async performance
CONCURRENT_REQUESTS = 32
DOWNLOAD_DELAY = 0.1
RANDOMIZE_DOWNLOAD_DELAY = True

# Example usage script
# run.py
import os
import subprocess
from scrapy.crawler import CrawlerProcess
from scrapy.settings import Settings
from image_scraper.spiders.image_spider import ImageSpider

def main():
    # Configure settings
    settings = Settings()
    settings.setmodule('image_scraper.settings')
    
    # Create download directory if it doesn't exist
    os.makedirs(settings.get('IMAGES_STORE'), exist_ok=True)
    
    # Initialize crawler process
    process = CrawlerProcess(settings)
    
    # Add your start URLs here
    start_urls = [
        'https://example.com',  # Replace with actual websites
    ]
    
    # Run spider
    process.crawl(ImageSpider, start_urls=start_urls)
    process.start()

if __name__ == '__main__':
    main()
    