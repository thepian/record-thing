import pyrqlite.dbapi2 as dbapi2


# import sqlite3
# import sqlite_vec
# from cyksuid.v2 import ksuid, parse
from collections import namedtuple

from typing import List, Tuple, Dict, Any

from .account import init_account
from .assets import init_assets
from .products import init_products

connection = None

def get_rqlite_cursor():
    return connection.cursor()

def init_db_rqlite(disconnect=True):
    global connection
    if connection is None:
        connection = dbapi2.connect(
            host='localhost',
            port=4001,
        )
    try:
        with connection.cursor() as cursor:
            init_account(cursor)
            init_assets(cursor)
            init_products(cursor)
    finally:
        if disconnect:
            connection.close()

    return connection



# def download_company_info(name: str) -> Dict[str, Any]:
#     """Searches European Unions trademark database for a product or tradmark name and returns the results"""
#     request = f"https://euipo.europa.eu/eSearch/#details/trademarks/{name}/"
#     requests.get(request)
    