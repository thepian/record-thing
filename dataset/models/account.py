from typing import Optional

from sqlmodel import Field, SQLModel
from .uid import ksuid, parse
import uuid 

class Account(SQLModel, table=True):
    __tablename__ = "accounts"

    id: uuid.UUID = Field(primary_key=True, default_factory=uuid.uuid4)
    name: Optional[str] = None
    email: Optional[str] = None
    sms: Optional[str] = None
    region: Optional[str] = None
