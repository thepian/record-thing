import pyrqlite.dbapi2 as dbapi2


# import sqlite3
# import sqlite_vec
# from cyksuid.v2 import ksuid, parse
from collections import namedtuple

from typing import List, Tuple, Dict, Any
import struct

from .account import init_account
from .assets import init_assets

# Connect to the database
connection = dbapi2.connect(
    host='localhost',
    port=4001,
)

def init_db(disconnect=True):

    try:
        with connection.cursor() as cursor:
            init_account(cursor)

        with connection.cursor() as cursor:
            # Read a single record with qmark parameter style
            sql = "SELECT `id`, `name` FROM `foo` WHERE `name`=?"
            cursor.execute(sql, ('a',))
            result = cursor.fetchone()
            print(result)
            # Read a single record with named parameter style
            sql = "SELECT `id`, `name` FROM `foo` WHERE `name`=:name"
            cursor.execute(sql, {'name': 'b'})
            result = cursor.fetchone()
            print(result)
    finally:
        if disconnect:
            connection.close()

    "SELECT * FROM SAMPLE_TABLE ORDER BY ROWID ASC LIMIT 1"


