from typing import Optional

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

