from collections import namedtuple
from typing import Optional

from sqlmodel import Field, SQLModel
from .uid import ksuid, ksuid_encoded

from ..vector import serialize_f32
from ..commons import commons, ksuid, DINO_EMBEDDING_SIZE

from .account import Account


CombinedClip = namedtuple('CombinedClip', ['id', 'name', 'rowid', 'dino_vec_rowid'])

# create a table with a single column of type float[4]
items = [
    CombinedClip(ksuid().encoded, "clip1", 1, [0.1, 0.1, 0.1, 0.1]),
    CombinedClip(ksuid().encoded, "clip2", 2, [0.2, 0.2, 0.2, 0.2]),
    CombinedClip(ksuid().encoded, "clip3", 3, [0.3, 0.3, 0.3, 0.3]),
    CombinedClip(ksuid().encoded, "clip4", 4, [0.4, 0.4, 0.4, 0.4]),
    CombinedClip(ksuid().encoded, "clip5", 5, [0.5, 0.5, 0.5, 0.5]),
]


# TODO switch to cyksuid
# Implement the same factory interface: https://github.com/timonwong/cyksuid/blob/master/cyksuid/ksuid.py vs https://github.com/python/cpython/blob/main/Lib/uuid.py#L88

class ClipAssets(SQLModel, table=True):
    __tablename__ = "clip_assets"

    account: str = Field(primary_key=True, foreign_key="accounts.id")
    id: str = Field(primary_key=True, default_factory=ksuid_encoded)
    name: str
    dino_vec_rowid: Optional[int] = None
    md5: str
    tags: str  # comma separated, prefixed and suffixed
    category: str



def init_assets(cursor):

    cursor.execute("""CREATE TABLE IF NOT EXISTS clip_assets (
            account TEXT,
            id TEXT, 
            product_id TEXT,
            dino_vec_rowid INTEGER,
            md5 TEXT,
            name TEXT,
            tags TEXT,
            category TEXT,
            PRIMARY KEY (account, id)
            );""")

# TODO add account_id as primary key?

    cursor.execute(f"""CREATE VIRTUAL TABLE IF NOT EXISTS dino_embedding USING vec0(
            asset_id TEXT PRIMARY KEY,
            embedding float[{DINO_EMBEDDING_SIZE}]
            )""")

    # cursor.execute("SELECT * FROM clip_assets LIMIT 1")
    # clips = cursor.fetchone()
    # if clips is None:
    #     for item in items:
    #         cursor.execute(
    #             "INSERT INTO clip_assets(account, id, dino_vec_rowid, name) VALUES (?, ?, ?, ?)",
    #             [commons['account_id'], item.id, item.rowid, item.name],
    #         )
    #         cursor.execute(
    #             "INSERT INTO dino_embedding(asset_id, embedding) VALUES (?, ?)",
    #             [item.id, serialize_f32(item.dino_vec_rowid)],
    #         )
