from pathlib import Path
import sys

p = str(Path(__file__).absolute().parent.parent / "libs")
print("Setting up the environment...", p)
if p not in sys.path:
    sys.path.insert(0, p)
    