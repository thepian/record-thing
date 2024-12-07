from typing import Optional

from dataset.commons import commons
from sqlmodel import Field, SQLModel
from .uid import ksuid, parse
import uuid 

# TODO switch to cyksuid
# Implement the same factory interface: https://github.com/timonwong/cyksuid/blob/master/cyksuid/ksuid.py vs https://github.com/python/cpython/blob/main/Lib/uuid.py#L88

from .account import Account

class Products(SQLModel, table=True):
    __tablename__ = "products"

    account: str = Field(primary_key=True, foreign_key="accounts.id")
    id: uuid.UUID = Field(primary_key=True, default_factory=uuid.uuid4)
    name: str
    upc: str
    asin: str
    elid: str
    brand: str
    model: str
    color: str
    tags: str
    category: str
    title: str
    description: str

    def from_json(json):
        pass



def init_products(cursor):
    cursor.execute("""CREATE TABLE IF NOT EXISTS products (
            account TEXT,
            id TEXT,
            upc TEXT,
            asin TEXT,
            elid TEXT,
            brand TEXT,
            model TEXT,
            color TEXT,
            tags TEXT,
            category TEXT,
            title TEXT,
            description TEXT
                   
            name TEXT,

            PRIMARY KEY (account, id)
            );""")

# product images

def select_product(cursor, id: Optional[str] = None, upc: Optional[str] = None) -> Optional[Products]:
    query = cursor.execute("SELECT * FROM products WHERE id = ? OR upc = ?" [id, upc])
    product = query.fetchone()
    if product:
        return Products.from_row(product) 


def create_product(cursor, upc: str, asin: str, elid: str, brand: str, model: str, color: str, tags: str, category: str, title: str, description: str, name: str) -> str:
    account_id = commons["account_id"]
    id = ksuid().encoded
    cursor.execute("""
        INSERT INTO products (account, id, upc, asin, elid, brand, model, color, tags, category, title, description, name) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""", 
        [account_id, id, upc, asin, elid, brand, model, color, tags, category, title, description, name])
        
    return id