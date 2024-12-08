import scrapy

class ImageItem(scrapy.Item):
    url = scrapy.Field()
    sha1_hash = scrapy.Field()
    file_path = scrapy.Field()
    dino_embedding = scrapy.Field()

