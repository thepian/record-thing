from typing import Optional

from ..commons import commons

from sqlmodel import Field, SQLModel
from .uid import ksuid_encoded


class Account(SQLModel, table=True):
    __tablename__ = "accounts"

    id: str = Field(primary_key=True, default_factory=ksuid_encoded)
    name: Optional[str] = None
    email: Optional[str] = None
    sms: Optional[str] = None
    region: Optional[str] = None


def init_account(cursor):
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS accounts (
        id TEXT PRIMARY KEY, 
        name TEXT, 
        email TEXT, 
        sms TEXT, 
        region TEXT);
    """)
    cursor.execute("SELECT * FROM accounts LIMIT 1")
    one_account = cursor.fetchone()
    if one_account is None:
        # print("new id:", account_id)
        cursor.execute("""
        INSERT INTO accounts(id, name) VALUES (?, ?);
        """, [commons['account_id'], "Joe Schmoe"], )
    else:
        # print("existing id:", commons['account_id'])
        commons['account_id'] = one_account[0]

    # cursor.executemany('INSERT INTO accounts(id, name) VALUES(?)', seq_of_parameters=(('a',), ('b',)))
    # cursor.execute("""
    #     INSERT INTO accounts(id, name) VALUES (?, ?);                      
    #     """, [commons['account_id'], "Joe Schmoe"], )


