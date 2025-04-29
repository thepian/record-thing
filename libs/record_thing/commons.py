from cyksuid.v2 import ksuid
from pathlib import Path

DINO_EMBEDDING_SIZE = 768

def create_uid() -> str:
    return str(ksuid())

owner_id = create_uid()

commons = {
    # Account of the device user = owner (replaced when loading the DB)
    'account_id': owner_id, # deprecated
    'owner_id': owner_id,
}

DBP = Path(__file__).parent / "record-thing.sqlite"

# This is wonky on iPython Notebooks
assets_ref_path = Path(__file__).parent.parent.parent / "assets"

sync_demo_path = Path(__file__).parent / "sync-demo-config.json"
