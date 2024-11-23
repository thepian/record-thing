
db = sqlite3.connect(":memory:")
# db = sqlite3.connect("db.sqlite3")
db.enable_load_extension(True)
sqlite_vec.load(db)
db.enable_load_extension(False)

