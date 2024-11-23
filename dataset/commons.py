from cyksuid.v2 import ksuid, parse

DINO_EMBEDDING_SIZE = 768

commons = {

    # Account of the device user (replaced when loading the DB)
    'account_id': ksuid().encoded,
}

def create_uid() -> str:
    return str(ksuid())