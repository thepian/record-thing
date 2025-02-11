import requests
import csv
from typing import List, Dict
from cyksuid.v2 import ksuid

def ksuid_encoded():
    return ksuid().encoded

class GoogleProductTaxonomyManager:
    def __init__(self, account_id: str):
        self.account_id = account_id
        self.taxonomy_url = "https://www.google.com/basepages/producttype/taxonomy.en-US.txt"
    
    def download_taxonomy(self) -> List[str]:
        """
        Download the latest Google Product Taxonomy
        """
        response = requests.get(self.taxonomy_url)
        if response.status_code == 200:
            # Skip the first line (usually a header or comment)
            return response.text.split('\n')[1:]
        else:
            raise Exception("Failed to download taxonomy")
    
    def parse_taxonomy(self, taxonomy_lines: List[str]) -> List[Dict]:
        """
        Parse taxonomy lines into a structured format
        """
        categories = []
        for line in taxonomy_lines:
            if not line.strip():
                continue
            
            # Split the full path
            parts = line.split(' > ')
            
            category_data = {
                'full_path': line,
                'taxonomy_id': hash(line),  # Unique identifier
                'levels': parts,
                'level': len(parts) - 1,
                'is_leaf': True
            }
            categories.append(category_data)
        
        return categories
    
    def insert_taxonomy(self, categories: List[Dict]):
        """
        Insert taxonomy into the database
        Uses a recursive approach to handle hierarchical structure
        """
        # Store parent references to optimize insertion
        parent_cache = {}
        
        for category in sorted(categories, key=lambda x: x['level']):
            # Generate a new KSUID for the category
            category_id = str(ksuid_encoded())
            
            # Determine parent
            parent_id = None
            if category['level'] > 0:
                parent_path = ' > '.join(category['levels'][:-1])
                parent_id = parent_cache.get(parent_path)
            
            # Prepare insertion data
            category_data = {
                'category_id': category_id,
                'account_id': self.account_id,
                'taxonomy_id': category['taxonomy_id'],
                'full_path': category['full_path'],
                'level': category['level'],
                'parent_category_id': parent_id,
                'is_leaf': category['is_leaf'],
                'description': category['full_path']
            }
            
            # Insert into database
            # Use your database connection to insert the category
            # self.db.insert('google_product_categories', category_data)
            
            # Cache this category for potential child lookups
            parent_cache[category['full_path']] = category_id
    
    def update_taxonomy(self):
        """
        Full workflow to download and insert taxonomy
        """
        taxonomy_lines = self.download_taxonomy()
        categories = self.parse_taxonomy(taxonomy_lines)
        self.insert_taxonomy(categories)
