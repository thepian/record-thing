from .db_setup import (
    DBP, 
    test_connection, insert_sample_data, create_database, generate_testdata_records,
    ensure_empty_db
)
from .db.schema import (
    init_db_tables, init_evidence, init_categories
)

__version__ = "0.1.0"

# Expose CLI entrypoint
from .cli import main as cli_main