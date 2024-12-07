from sqlmodel import create_engine

# engine = create_engine('rqlite+pyrqlite://localhost:4001/', echo=True)

engine = create_engine("sqlite://", echo=True) # :memory: or /db.sqlite3
# engine.
# db = sqlite3.connect(":memory:")
# db = sqlite3.connect("db.sqlite3")
# db.enable_load_extension(True)
# sqlite_vec.load(db)
# db.enable_load_extension(False)
