"""
Configuration for pytest.
This file helps with importing modules and setting up fixtures.
"""

import os
import sys
from pathlib import Path

# Add the project root to the Python path
# This allows imports like 'from libs.record_thing.db import ...' to work
root_dir = Path(__file__).parent.parent.parent.parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

# Also add the library directory to allow relative imports in tests
lib_dir = Path(__file__).parent.parent
if str(lib_dir) not in sys.path:
    sys.path.insert(0, str(lib_dir))
