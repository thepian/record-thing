
import sqlite3
import sqlite_vec

from .account import init_account
from .assets import init_assets
from .products import init_products

db = None

def init_db_sqlite(disconnect=False):
    global db

    db = sqlite3.connect(":memory:")
    # db = sqlite3.connect("db.sqlite3")
    db.enable_load_extension(True)
    sqlite_vec.load(db)
    db.enable_load_extension(False)

    try:
        # with db.cursor() as cursor:
        cursor = db.cursor()
        init_account(cursor)
        init_assets(cursor)
        init_products(cursor)
    finally:
        if disconnect:
            db.close()

    return db

