def init_products(cursor):
    cursor.execute("""CREATE TABLE IF NOT EXISTS product (
            account TEXT,
            id TEXT KEY,
            upc TEXT,
            asin TEXT,
            elid TEXT,
            brand TEXT,
            model TEXT,
            color TEXT,
            tags TEXT,
            category TEXT,
            title TEXT,
            description TEXT
                   
            name TEXT,

            PRIMARY KEY (account, id)
            );""")

