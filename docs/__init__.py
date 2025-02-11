from pathlib import Path
import sys

print("Setting up the environment...")
p = str(Path(__file__).absolute().parent.parent / "libs")
if p not in sys.path:
    sys.path.insert(0, p)
    