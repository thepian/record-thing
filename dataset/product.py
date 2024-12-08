from typing import Mapping, Optional
import requests

from .commons import commons
from .ingestion import Ingestor
from .db.products import Products, create_product, select_product

def lookup_upc(upc: str) -> Mapping:
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

        images = item["images"]

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
            "images": images
        }
    else:
        return None 

def lookup_product(upc: str, ingestor: Ingestor, save=True, update=False) -> Optional[Products]:
    product = select_product(ingestor.cursor, upc=upc)   
    if product:
        # print("Product found:", product)
        if update:
            update_product(product)
        return product
    
    result = lookup_upc(upc)
    if result:
        images = result["images"]
        embeddings = [ingestor.embeddings(url=url) for url in images]
        result["embeddings"] = embeddings

        if save:
            # TODO update products table if save is True
            product_id = save_product(result, ingestor)
            result["account"] = commons["account_id"]
            result["id"] = product_id
            result["name"] = result["title"]
            result["tags"] = ",,"

        return Products.from_dict(result)
    return None

def save_product(product: Mapping, ingestor: Ingestor) -> str:
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

    name = product["title"] # User consensus?
    tags = ",,"
    print("Creating product:", name, product.keys())
    product_id = create_product(ingestor.cursor, 
                   product["upc"], product["asin"], product["elid"], 
                   product["brand"], product["model"], product["color"], 
                   tags, product["category"], product["title"], 
                   product["description"], 
                   name)
    
    # TODO use scrapy to download images, save them to organised image repository and save the embeddings to the dino_embedding table

    return product_id

def update_product(product: Products):
    # TODO lookup upc and update the product
    pass
