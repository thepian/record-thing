from datetime import timedelta
from pathlib import Path
import requests
import csv
from typing import Any, List, Dict
import hashlib
import requests_cache
from ..commons import create_uid

# evidence_type_tuple = namedtuple('product_type', ['lang', 'rootName', 'name', 'url', 'gpcRoot', 'gpcName', 'gpcCode', 'unspscID'])

# def gen_from_node(node, base = []):
# 	base_names = ">".join(base)
# 	yield product_type_tuple('en', base_names, node['name'], None, base_names, node['name'], int(node['code']), None)
# 	for child in node['children']:
# 		yield from gen_from_node(child, base + [node['name']])

class GoogleProductTaxonomyManager:
    def __init__(self, account_id: str, locale: str = "en-US"):
        self.account_id = account_id
        self.taxonomy_url = f"https://www.google.com/basepages/producttype/taxonomy.{locale}.txt"
        self.categories_list: list[dict[str, Any]] = []
        self.categories_by_path: dict[str, dict[str, Any]] = {}
        self.categories_by_idx: dict[str, dict[int, Any]] = {}
        self.evidence_types: list[dict[str, Any]] = []

    def update_taxonomy(self):
        """
        Full workflow to download and insert taxonomy
        """
        taxonomy_lines = self.download_taxonomy()
        self.categories_list = self.parse_taxonomy(taxonomy_lines)
        self.insert_taxonomy(self.categories_list)
    
    def download_taxonomy(self) -> List[str]:
        """
        Download the latest Google Product Taxonomy
        """
        # Setup cache
        cache_dir = Path(__file__).parent.parent / ".cache"
        cache_dir.mkdir(exist_ok=True)
        cache_file = cache_dir / "taxonomy_cache"
        
        # Install cache with 7-day expiry
        requests_cache.install_cache(
            str(cache_file),
            expire_after=timedelta(days=7),
            allowable_methods=('GET',)
        )
        response = requests.get(self.taxonomy_url)
        response.raise_for_status()
			
        if response.from_cache:
            print("Using cached taxonomy...")
        else:
            print("Downloaded fresh taxonomy...")
			
        
        if response.status_code == 200:
            # Skip the first line (usually a header or comment)
            return response.text.split('\n')[1:]
        else:
            raise Exception("Failed to download taxonomy")
    
    def parse_taxonomy(self, taxonomy_lines: list[str]) -> list[Dict]:
        """
        Parse taxonomy lines into a structured format
        """
        categories = []
        for idx, line in enumerate(taxonomy_lines):
            if not line.strip():
                continue
            
            # Split the full path
            parts = line.split(' > ')
            
            category = {
                'account_id': self.account_id,
                'uid': create_uid(),
                'hash': hashlib.md5(line.encode()).hexdigest(),
                'full_path': line,
                'levels': parts,
                'level': len(parts) - 1,
                'parent_path': ' > '.join(parts[:-1]),
                'name': parts[-1],
                'is_leaf': True,
                'idx': idx
            }
            categories.append(category)
        
        return categories
    
    def insert_taxonomy(self, categories_list: list[dict[str, Any]]):
        """
        Insert taxonomy into the database
        Uses a recursive approach to handle hierarchical structure
        """
        
        for category in sorted(categories_list, key=lambda x: x['level']):
            self.categories_by_path[category['full_path']] = category
            self.categories_by_idx[category['idx']] = category
            
            # Determine parent
            parent_id = None
            if category['level'] > 0:
                category['parent'] = self.categories_by_path[category['parent_path']]
                        
    
