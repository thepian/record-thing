from cyksuid.v2 import ksuid, parse
from ..commons import commons

# default_account = {
#     "id": account_id,
#     "name": "Joe Schmoe",
#     "email": "
# }

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


