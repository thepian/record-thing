from typing import Optional
import os

from dataset.commons import commons
from sqlmodel import Field, SQLModel
from .uid import ksuid, ksuid_encoded

# TODO switch to cyksuid
# Implement the same factory interface: https://github.com/timonwong/cyksuid/blob/master/cyksuid/ksuid.py vs https://github.com/python/cpython/blob/main/Lib/uuid.py#L88

from .account import Account

class Products(SQLModel, table=True):
    __tablename__ = "products"
    __abstract__ = True

    account: str = Field(primary_key=True, foreign_key="accounts.id")
    id: str = Field(primary_key=True, default_factory=ksuid_encoded)
    upc: str
    asin: str
    elid: str
    brand: str
    model: str
    color: str
    category: str
    title: str
    description: str

    # User provided name and tags
    name: str
    tags: str

    def from_json(json):
        pass

    def from_dict(product_dict: dict[str, any]):
        product = Products()
        product.account = product_dict["account"]
        product.id = product_dict["id"]
        product.upc = product_dict["upc"]
        product.asin = product_dict["asin"]
        product.elid = product_dict["elid"]
        product.brand = product_dict["brand"]
        product.model = product_dict["model"]
        product.color = product_dict["color"]
        product.tags = product_dict["tags"]
        product.category = product_dict["category"]
        product.title = product_dict["title"]
        product.description = product_dict["description"]
        product.name = product_dict["name"]

        return product

    def from_row(row):
        product = Products()
        product.account = row[0]
        product.id = row[1]
        product.upc = row[2]
        product.asin = row[3]
        product.elid = row[4]
        product.brand = row[5]
        product.model = row[6]
        product.color = row[7]
        product.tags = row[8]
        product.category = row[9]
        product.title = row[10]
        product.description = row[11]
        product.name = row[12]

        return product
        

def init_products(cursor):
    with open(os.path.join(os.path.dirname(__file__), './products.sql'), 'r') as sql_file:
        sql_script = sql_file.read()
        cursor.executescript(sql_script)
        

# product images

def select_product(cursor, id: Optional[str] = None, upc: Optional[str] = None) -> Optional[Products]:
    if id:
        query = cursor.execute("SELECT * FROM products WHERE id = ?", [id])
    elif upc:
        query = cursor.execute("SELECT * FROM products WHERE upc in (?,?)", [upc, upc.lstrip("0")])
    else:
        return None
    product = query.fetchone()
    if product:
        # print("Product found:", product)
        return Products.from_row(product) 
    # else:   
    #     print("Product not found", upc)


def create_product(cursor, 
                   upc: str, asin: str, elid: str, 
                   brand: str, model: str, color: str, 
                   tags: str, category: str, title: str, 
                   description: str, name: str) -> str:
    account_id = commons["account_id"]
    id = ksuid().encoded
    cursor.execute("""
        INSERT INTO products (account, id, upc, asin, elid, brand, model, color, tags, category, title, description, name) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""", 
        [account_id, id, upc, asin, elid, brand, model, color, tags, category, title, description, name])
        
    return id