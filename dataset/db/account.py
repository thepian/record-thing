from typing import Optional
import os
from datetime import datetime

from ..commons import commons

from sqlmodel import Field, SQLModel
from .uid import ksuid_encoded


class Account(SQLModel, table=True):
    __tablename__ = "accounts"
    __abstract__ = True

    id: str = Field(primary_key=True, default_factory=ksuid_encoded)
    name: Optional[str] = None
    username: Optional[str] = None
    email: Optional[str] = None
    sms: Optional[str] = None
    region: Optional[str] = None
    password_hash: Optional[str] = None
    registration_date: Optional[datetime] = None
    is_active: Optional[bool] = None
    last_login: Optional[datetime] = None


def init_account(cursor):
    with open(os.path.join(os.path.dirname(__file__), './accounts.sql'), 'r') as sql_file:
        sql_script = sql_file.read()
        cursor.executescript(sql_script)

    cursor.execute("SELECT * FROM owners LIMIT 1")
    one_owner = cursor.fetchone()
    if one_owner is None:
        # print("new id:", account_id)
        cursor.execute("""
        INSERT INTO accounts(id, name) VALUES (?, ?);
        """, [commons['account_id'], "Joe Schmoe"], )
        cursor.execute("""
        INSERT INTO owners(account_id) VALUES (?);
        """, [commons['account_id']], )
    else:
        # print("existing id:", commons['account_id'])
        commons['account_id'] = one_owner[0]

    # cursor.executemany('INSERT INTO accounts(id, name) VALUES(?)', seq_of_parameters=(('a',), ('b',)))
    # cursor.execute("""
    #     INSERT INTO accounts(id, name) VALUES (?, ?);                      
    #     """, [commons['account_id'], "Joe Schmoe"], )


