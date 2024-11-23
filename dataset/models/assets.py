from typing import Optional

from sqlmodel import Field, SQLModel
from .uid import ksuid, parse
import uuid 

# TODO switch to cyksuid
# Implement the same factory interface: https://github.com/timonwong/cyksuid/blob/master/cyksuid/ksuid.py vs https://github.com/python/cpython/blob/main/Lib/uuid.py#L88

from .account import Account

class ClipAssets(SQLModel, table=True):
    __tablename__ = "clip_assets"

    account: str = Field(primary_key=True, foreign_key="accounts.id")
    id: uuid.UUID = Field(primary_key=True, default_factory=uuid.uuid4)
    name: str
    dino_vec_rowid: Optional[int] = None


# db.execute("""
# INSERT INTO clip_assets(account, id, dino_vec_rowid, name) VALUES (?, ?, ?, ?);
#            """, [account_id, ksuid().encoded, 1, "clip1"], )