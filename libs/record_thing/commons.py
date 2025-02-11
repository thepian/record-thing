from cyksuid.v2 import ksuid

DINO_EMBEDDING_SIZE = 768

def create_uid() -> str:
    return str(ksuid())

owner_id = create_uid()

commons = {
    # Account of the device user = owner (replaced when loading the DB)
    'account_id': owner_id, # deprecated
    'owner_id': owner_id,
}

