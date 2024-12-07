import sqlite3
import sqlite_vec
from cyksuid.v2 import ksuid, parse
from collections import namedtuple

from typing import List, Tuple, Dict, Any
import struct

def serialize_f32(vector: List[float]) -> bytes:
    """serializes a list of floats into a compact "raw bytes" format"""
    return struct.pack("%sf" % len(vector), *vector)




db = sqlite3.connect(":memory:")
# db = sqlite3.connect("db.sqlite3")
db.enable_load_extension(True)
sqlite_vec.load(db)
db.enable_load_extension(False)

# if no accounts table

# Account of the device user
account_id = ksuid().encoded

db.execute("""
    CREATE TABLE accounts (
        id TEXT PRIMARY KEY, 
        name TEXT, 
        email TEXT, 
        sms TEXT, 
        region TEXT);
    """);

db.execute("""
    INSERT INTO accounts(id, name) VALUES (?, ?);
                      
    """, [account_id, "Joe Schmoe"], )

db.execute("""CREATE TABLE clip_assets (
           account TEXT,
           id TEXT, 
           dino_vec_rowid INTEGER,
           name TEXT,
           PRIMARY KEY (account, id)
           );""")

db.execute("""
INSERT INTO clip_assets(account, id, dino_vec_rowid, name) VALUES (?, ?, ?, ?);
           """, [account_id, ksuid().encoded, 1, "clip1"], )

CombinedClip = namedtuple('CombinedClip', ['id', 'name', 'rowid', 'dino_vec_rowid'])

# create a table with a single column of type float[4]
items = [
    CombinedClip(ksuid().encoded, "clip1", 1, [0.1, 0.1, 0.1, 0.1]),
    CombinedClip(ksuid().encoded, "clip2", 2, [0.2, 0.2, 0.2, 0.2]),
    CombinedClip(ksuid().encoded, "clip3", 3, [0.3, 0.3, 0.3, 0.3]),
    CombinedClip(ksuid().encoded, "clip4", 4, [0.4, 0.4, 0.4, 0.4]),
    CombinedClip(ksuid().encoded, "clip5", 5, [0.5, 0.5, 0.5, 0.5]),
]

db.execute("CREATE VIRTUAL TABLE vec_items USING vec0(embedding float[4])")

with db:
    for item in items:
        db.execute(
            "INSERT INTO clip_assets(account, id, dino_vec_rowid, name) VALUES (?, ?, ?, ?)",
            [account_id, item.id, item.rowid, item.name],
        )
        db.execute(
            "INSERT INTO vec_items(rowid, embedding) VALUES (?, ?)",
            [item.rowid, serialize_f32(item.dino_vec_rowid)],
        )

 