import os
import sys
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

# Common paths
SCRIPT_DIR = Path(__file__).parent
REPO_ROOT = SCRIPT_DIR.parent.parent
DBP = SCRIPT_DIR / "record-thing.sqlite"
ASSETS_DIR = REPO_ROOT / "assets"
APPS_DIR = REPO_ROOT / "apps"
LIBS_DIR = REPO_ROOT / "libs"
RECORDLIB_DIR = APPS_DIR / "libs" / "RecordLib"
RECORDTHING_DIR = APPS_DIR / "RecordThing"
RECORDTHING_SHARED_DIR = RECORDTHING_DIR / "Shared"

# Sync configuration path
sync_demo_path = SCRIPT_DIR / "sync-demo-config.json"


def get_repo_root() -> Path:
    """
    Find the repository root directory based on this script's location.
    The script is assumed to be in libs/record_thing/ within the repository.
    
    Returns:
        Path to the repository root
    """
    # Use the cached path if it looks valid
    if (REPO_ROOT / "libs" / "record_thing").exists() and (REPO_ROOT / "apps").exists():
        return REPO_ROOT
    
    # Otherwise, try to find repo root by traversing upward
    script_dir = Path(os.path.dirname(os.path.abspath(__file__)))
    current = script_dir
    while current != current.parent:  # Stop at filesystem root
        if (current / "libs" / "record_thing").exists() and (current / "apps").exists():
            return current
        current = current.parent
    
    # If we still can't find it, use the initial estimate and warn
    print(f"Warning: Unable to confidently determine repository root. Using {REPO_ROOT}", 
          file=sys.stderr)
    return REPO_ROOT


def resolve_path(path: str, base_path: Path = None) -> Path:
    """
    Resolve a path relative to the repository root.
    
    If the path is absolute, returns it unchanged.
    If the path is relative and starts with 'apps/' or 'libs/', treats it as relative to repo root.
    Otherwise, treats it as relative to base_path (or current directory if None).
    
    Args:
        path: Path to resolve
        base_path: Base path for relative paths not starting with 'apps/' or 'libs/'
                  (defaults to current directory)
    
    Returns:
        Resolved Path object
    """
    if not path:
        return None
    
    path_obj = Path(path)
    
    # If it's an absolute path, return it unchanged
    if path_obj.is_absolute():
        return path_obj
    
    # If path starts with apps/ or libs/, resolve relative to repo root
    if path.startswith(("apps/", "libs/")):
        return get_repo_root() / path
    
    # Otherwise, resolve relative to base_path or current directory
    base = base_path if base_path else Path.cwd()
    return base / path


def resolve_directory(directory: str, base_path: Path = None) -> Path:
    """
    Resolve a directory path, ensuring it exists.
    
    Args:
        directory: Directory path to resolve
        base_path: Base path for relative resolution
    
    Returns:
        Resolved Path object
    """
    path = resolve_path(directory, base_path)
    if not path.exists():
        raise FileNotFoundError(f"Directory not found: {path}")
    if not path.is_dir():
        raise NotADirectoryError(f"Not a directory: {path}")
    return path


def resolve_database_path(db_path: str = None) -> Path:
    """
    Resolve the database path, defaulting to the repository's record-thing.sqlite.
    
    Args:
        db_path: Optional database path
    
    Returns:
        Resolved database Path
    """
    if not db_path:
        # Default to record-thing.sqlite in libs/record_thing/
        return DBP
    
    return resolve_path(db_path)
