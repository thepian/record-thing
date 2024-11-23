from collections import namedtuple

from ..vector import serialize_f32
from ..commons import commons, ksuid, DINO_EMBEDDING_SIZE

CombinedClip = namedtuple('CombinedClip', ['id', 'name', 'rowid', 'dino_vec_rowid'])

# create a table with a single column of type float[4]
items = [
    CombinedClip(ksuid().encoded, "clip1", 1, [0.1, 0.1, 0.1, 0.1]),
    CombinedClip(ksuid().encoded, "clip2", 2, [0.2, 0.2, 0.2, 0.2]),
    CombinedClip(ksuid().encoded, "clip3", 3, [0.3, 0.3, 0.3, 0.3]),
    CombinedClip(ksuid().encoded, "clip4", 4, [0.4, 0.4, 0.4, 0.4]),
    CombinedClip(ksuid().encoded, "clip5", 5, [0.5, 0.5, 0.5, 0.5]),
]


def init_assets(cursor):

    cursor.execute("""CREATE TABLE IF NOT EXISTS clip_assets (
            account TEXT,
            id TEXT, 
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
