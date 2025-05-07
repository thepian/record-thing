from pathlib import Path

from cyksuid.v2 import ksuid

DINO_EMBEDDING_SIZE = 768
DEMO_ACCOUNT_ID = "2siEySuKO1wK4XiJHWQ0YxhLxd2"
FREE_TEAM_ID = "2wokkB1WCfyZq3lcahGCMd53zZ7"
PREMIUM_TEAM_ID = "2wokwJClVrkYDmyT5jGZliWR924"


def create_uid() -> str:
    return str(ksuid())


owner_id = create_uid()

commons = {
    # Account of the device user = owner (replaced when loading the DB)
    "demo_account_id": DEMO_ACCOUNT_ID,
    "account_id": owner_id,  # deprecated
    "owner_id": owner_id,
    "free_team_id": FREE_TEAM_ID,
    "premium_team_id": PREMIUM_TEAM_ID,
}

DBP = Path(__file__).parent / "record-thing.sqlite"

# This is wonky on iPython Notebooks
assets_ref_path = Path(__file__).parent.parent.parent / "assets"

sync_demo_path = Path(__file__).parent / "sync-demo-config.json"
