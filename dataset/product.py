from typing import Mapping
import requests

from dataset.ingestion import Ingestor

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

def lookup_product(upc: str, ingestor: Ingestor) -> Mapping:
    result = lookup_upc(upc)
    if result:
        images = result["images"]
        embeddings = [ingestor.embeddings(url=url) for url in images]
        result["embeddings"] = embeddings

        return result
    return None


