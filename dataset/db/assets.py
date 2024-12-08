from collections import namedtuple
from datetime import datetime
from typing import Optional
import os

from sqlmodel import Field, SQLModel, TIMESTAMP
from .uid import ksuid, ksuid_encoded

from ..vector import serialize_f32
from ..commons import commons, ksuid, DINO_EMBEDDING_SIZE

from .account import Account

# TODO switch to cyksuid
# Implement the same factory interface: https://github.com/timonwong/cyksuid/blob/master/cyksuid/ksuid.py vs https://github.com/python/cpython/blob/main/Lib/uuid.py#L88

class ClipAssets(SQLModel, table=True):
    __tablename__ = "clip_assets"
    __abstract__ = True

    account: str = Field(primary_key=True, foreign_key="accounts.id")
    id: str = Field(primary_key=True, default_factory=ksuid_encoded)
    name: str
    dino_vec_rowid: Optional[int] = None
    sha1: str
    tags: str  # comma separated, prefixed and suffixed
    category: str
    scanned_at: Optional[datetime] = Field(default=datetime.now, sa_column=TIMESTAMP)



def init_assets(cursor):
    with open(os.path.join(os.path.dirname(__file__), './assets.sql'), 'r') as sql_file:
        sql_script = sql_file.read()
        cursor.executescript(sql_script)

    # TODO add account_id as primary key?
