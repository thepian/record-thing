# image_scraper/spiders/image_spider.py
import scrapy
import os
from urllib.parse import urlparse

class ImageSpider(scrapy.Spider):
    name = 'image_spider'
    
    def __init__(self, start_urls=None, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.start_urls = start_urls or []
    
    def start_requests(self):
        for url in self.start_urls:
            yield scrapy.Request(url, self.parse)
    
    def parse(self, response):
        # Extract image URLs from the page
        image_urls = response.css('img::attr(src)').getall()
        
        for img_url in image_urls:
            # Resolve relative URLs
            img_url = response.urljoin(img_url)
            
            yield scrapy.Request(
                img_url, 
                callback=self.save_image, 
                meta={'original_url': img_url}
            )
    
    def save_image(self, response):
        # Extract filename from URL
        url = response.meta['original_url']
        parsed = urlparse(url)
        filename = os.path.basename(parsed.path)
        
        # Ensure unique filename
        filename = f"{hash(url)}_{filename}"
        
        # Save image
        file_path = os.path.join(
            self.settings.get('IMAGES_STORE', './downloads'), 
            filename
        )
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        with open(file_path, 'wb') as f:
            f.write(response.body)
        
        # Yield item with image metadata
        yield {
            'url': url,
            'file_path': file_path
        }

