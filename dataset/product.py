from typing import Mapping, Optional
import requests
import torch

from dataset.db.uid import ksuid_encoded
from dataset.vector import serialize_f32

from .commons import commons, create_uid
from .ingestion import Ingestor
from .db.products import Products, create_product, select_product

def lookup_upc(upc: str, ingestor: Ingestor) -> Mapping:
    product = requests.get(url="https://api.upcitemdb.com/prod/trial/lookup", params={"upc": upc}).json()
    if product["code"] == "OK":
        number_matches = product["total"]

        # https://www.upcitemdb.com/wp/docs/main/development/responses/

        item = product["items"][0]

        # IDs
        upc = item["upc"]
        asin = item["asin"]
        elid = item["elid"]

        # Item
        brand = item["brand"]
        model = item["model"]
        color = item["color"]

        urls = item["images"]
        images = [ingestor.product_image(url=url) for url in urls]

        # Google product taxonomy, https://www.google.com/basepages/producttype/taxonomy.en-US.txt.
        category = item["category"]
        title = item["title"]
        description = item["description"] # max 515

        # item["offers"]["price"] vs item["offers"]["list_price"]
        # price = item["offers"]["price"]
        # list_price = item["offers"]["list_price"]
        upc_link = item["offers"][0]["link"]
        domain = item["offers"][0]["domain"]

        return {
            "upc": upc,
            "asin": asin,
            "elid": elid,
            "brand": brand,
            "model": model,
            "color": color,
            "category": category,
            "title": title,
            "description": description,
            "upc_link": upc_link,
            "domain": domain,
            "urls": urls,
            "images": images
        }
    else:
        return None 

def lookup_product(upc: str, ingestor: Ingestor, save=True, update=False) -> Optional[Products]:
    product = select_product(ingestor.cursor, upc=upc)   
    if product:
        # print("Product found:", product)
        missing_images = ingestor.cursor.execute("SELECT * FROM product_images WHERE id = ?", [product.id]).fetchone() is None
        if update or missing_images:
            update_product(product, lookup_upc(upc, ingestor), ingestor=ingestor)
        return product
    
    result = lookup_upc(upc, ingestor)
    if result:
        if save:
            # TODO update products table if save is True
            product_id = save_product(result, ingestor)
            result["account"] = commons["account_id"]
            result["id"] = product_id
            result["name"] = result["title"]
            result["tags"] = ",,"

        return Products.from_dict(result)
    return None

def save_product(product_dict: Mapping, ingestor: Ingestor) -> str:
    """
    'upc_link': 'https://www.upcitemdb.com/norob/alink/?id=v2p2z213v2x28474u2&tid=1&seq=1733392205&plt=cf7aa6eb9640d9edc6d6eda877e8e47a', 
    'domain': 'newegg.com', 
    'images': [
    'http://img.bbystatic.com/BestBuy_US/images/products/7218/7218034_sc.jpg', 
    'https://i5.walmartimages.com/asr/816d5a79-828f-4bc9-9033-1f8f08213857_1.a409ced9502bcea4cf84e7ab7b60c58f.jpeg?odnHeight=450&odnWidth=450&odnBg=ffffff', 'https://c1.neweggimages.com/ProductImageCompressAll640/A9K8_131002154351685402J2X9S9guNK.jpg', 
    'http://img1.r10.io/PIC/112231913/0/1/250/112231913.jpg'
    ], 
    'embeddings': [tensor([ 3.6900e-01,  1.2225e+00,  6.7577e-01, -5.7228e-01, -3.6754e-01,
            
    """

    name = product_dict["title"] # User consensus?
    tags = ",,"
    print("Creating product:", name, product_dict.keys())
    product_id = create_product(ingestor.cursor, 
                   product_dict["upc"], product_dict["asin"], product_dict["elid"], 
                   product_dict["brand"], product_dict["model"], product_dict["color"], 
                   tags, product_dict["category"], product_dict["title"], 
                   product_dict["description"], 
                   name)
    
    # TODO use scrapy to download images, save them to organised image repository and save the embeddings to the dino_embedding table

    print("Creating product images:", product_dict["images"])
    for product_image in product_dict["images"]:
        create_product_image(ingestor.cursor, product_id, product_image.url, product_image.embedding, product_image.sha1)

    ingestor.cursor.commit()

    return product_id

def update_product(product: Products, product_dict: Mapping, ingestor: Ingestor):
    product_id = product.id

    print("Creating product images:", product_dict["images"])
    for product_image in product_dict["images"]:
        create_product_image(ingestor.cursor, product_id, product_image.url, product_image.embedding, product_image.sha1)

    # TODO ingestor.cursor.commit()

    return product_id

def create_product_image(cursor, product_id: str, url: str, embedding: torch.tensor, sha1: str):
    embedding_id = create_uid() # TODO asset_id is the same as embedding_id

    # TODO use existing embedding_id if it exists
    if embedding is not None:
        cursor.execute("INSERT INTO dino_embedding(asset_id, sha1, url, embedding) VALUES (?, ?, ?, ?)", 
            [embedding_id, sha1, url, serialize_f32(embedding)])    

        pi_id = create_uid()
        cursor.execute("INSERT INTO product_images(id, product_id, url, embedding_id, sha1, is_public, image_type) VALUES (?, ?, ?, ?, ?, ?, ?)", 
            [pi_id, product_id, url, embedding_id, sha1, 1, 'web_scraped'])
    
    # account TEXT NOT NULL,
    # id TEXT PRIMARY KEY, -- KSUID
    # product_id TEXT NOT NULL,
    # url TEXT,
    # sha1 TEXT, 
    # cache_path TEXT,
    # is_public BOOLEAN DEFAULT 0,
    # image_type TEXT, -- 'original', 'user_added', 'web_scraped'
    # parse_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    