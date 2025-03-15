import sqlite3
from SPARQLWrapper import SPARQLWrapper, JSON
import time
import logging
from pathlib import Path
from ..commons import create_uid
from tqdm import tqdm
from typing import Dict, Generator, Any, TypedDict, List, Tuple
from sqlite3 import Connection
import pandas as pd
import duckdb
import glob
import requests
from datetime import datetime, timedelta
import xml.etree.ElementTree as ET

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

companies_output_path = Path(__file__).parent / "wikidata_companies.parquet"
euipo_output_path = Path(__file__).parent / "euipo_trademarks.parquet"

evidentnet = Path("/Volumes/Datasets/evidentnet")

# Define columns for entity description when fetched from Wikidata
ENTITY_COLUMNS = [
    'wikidata_id',      # Wikidata ID (Q number)
    'name',             # Entity name/label
    'description',      # Entity description
    'instance_of',      # What type of entity (P31)
    'instance_of_id',   # Wikidata ID of the instance type
    'industry',         # Industry classification (P452)
    'industry_id',      # Wikidata ID of the industry
    'image',            # Image URL (P18)
    'logo',             # Logo URL (P154)
    'country',          # Country of origin/headquarters (P17)
    'country_id',       # Wikidata ID of the country
    'website',          # Official website (P856)
    'inception_date',   # Founding/inception date (P571)
    'category',         # Category from our classification
    'parent_company',   # Parent company (P749)
    'parent_company_id' # Wikidata ID of parent company
]

def populate_from_wikidata_entities(db_path: Path, evidentnet_path: Path = evidentnet) -> Dict[str, int]:
    """
    Read Wikidata entity data from parquet files and populate the brands and companies tables.
    
    This function:
    1. Connects to the SQLite database
    2. Finds all wikidata_entity_*.parquet files in the evidentnet/brands directory
    3. Uses DuckDB to efficiently read and process the parquet files
    4. Populates the brands table with entities where instance_of is "brand"
    5. Populates the companies table with entities where instance_of is not "brand"
    6. Ensures only one entry per Wikidata ID in the companies table
    7. Combines different instance_of values as tags
    
    Args:
        db_path: Path to the SQLite database
        evidentnet_path: Path to the evidentnet directory
    
    Returns:
        Dictionary with statistics about the import process
    """
    stats = {
        'new_brands': 0,
        'existing_brands': 0,
        'new_companies': 0,
        'existing_companies': 0,
        'updated_companies': 0,
        'errors': 0,
        'files_processed': 0
    }
    
    # Connect to SQLite database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Initialize DuckDB connection
    duck_conn = duckdb.connect(database=':memory:')
    
    # Create a tags table if it doesn't exist
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS tags (
            id TEXT PRIMARY KEY,
            entity_id TEXT NOT NULL,
            entity_type TEXT NOT NULL,
            tag TEXT NOT NULL,
            source TEXT,
            UNIQUE(entity_id, entity_type, tag)
        )
    """)
    
    # Dictionary to track companies that need to be processed
    # This helps us combine data from multiple files for the same entity
    company_data = {}
    
    try:
        # Find all wikidata entity files
        entity_files = glob.glob(str(evidentnet_path / "brands" / "wikidata_entity_*.parquet"))
        logger.info(f"Found {len(entity_files)} Wikidata entity files")
        
        # First pass: collect all company data across files
        logger.info("First pass: collecting company data across files")
        for file_path in tqdm(entity_files, desc="Collecting company data"):
            try:
                # Read parquet file into DuckDB
                duck_conn.execute(f"CREATE OR REPLACE TABLE entities AS SELECT * FROM read_parquet('{file_path}')")
                
                # Get companies (entities where instance_of is not brand)
                companies_df = duck_conn.execute("""
                    SELECT * FROM entities 
                    WHERE lower(instance_of) NOT LIKE '%brand%' 
                      AND lower(instance_of) NOT LIKE '%trademark%'
                """).fetchdf()
                
                # Collect company data
                for _, company in companies_df.iterrows():
                    wikidata_id = company['wikidata_id']
                    
                    if wikidata_id not in company_data:
                        company_data[wikidata_id] = {
                            'name': company['name'],
                            'description': company['description'],
                            'inception_date': company['inception_date'],
                            'website': company['website'],
                            'industry': company['industry'],
                            'country': company['country'],
                            'logo': company['logo'],
                            'image': company['image'],
                            'instance_of': set(),
                            'category': company['category']
                        }
                    
                    # Add instance_of to the set (for tags)
                    if company['instance_of']:
                        company_data[wikidata_id]['instance_of'].add(company['instance_of'])
                    
                    # Use the most complete data available
                    for field in ['name', 'description', 'inception_date', 'website', 'industry', 'country', 'logo', 'image', 'category']:
                        if not company_data[wikidata_id][field] and company[field]:
                            company_data[wikidata_id][field] = company[field]
                
            except Exception as e:
                logger.error(f"Error processing file {file_path} during collection: {e}")
                stats['errors'] += 1
        
        # Second pass: process brands and insert/update companies
        logger.info("Second pass: processing brands and inserting/updating companies")
        for file_path in tqdm(entity_files, desc="Processing entity files"):
            try:
                # Read parquet file into DuckDB
                duck_conn.execute(f"CREATE OR REPLACE TABLE entities AS SELECT * FROM read_parquet('{file_path}')")
                
                # Get brands (entities where instance_of contains "brand")
                brands_df = duck_conn.execute("""
                    SELECT * FROM entities 
                    WHERE lower(instance_of) LIKE '%brand%' 
                       OR lower(instance_of) LIKE '%trademark%'
                """).fetchdf()
                
                # Process brands
                for _, brand in brands_df.iterrows():
                    try:
        # Check if brand already exists
                        cursor.execute("SELECT id FROM brand WHERE wikidata_id = ?", (brand['wikidata_id'],))
        existing_brand = cursor.fetchone()
        
        if not existing_brand:
                            # Generate UID for new brand
            brand_id = create_uid()
            
                            # Insert new brand
            cursor.execute("""
                INSERT INTO brand (
                                    id, name, wikidata_id, description, category,
                                    founded_date, official_url, wikipedia_url, source
                                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                                brand_id,
                                brand['name'],
                                brand['wikidata_id'],
                                brand['description'],
                                brand['category'],
                                brand['inception_date'],
                                brand['website'],
                                "",  # wikipedia_url not in entity data
                                'wikidata'
            ))
            stats['new_brands'] += 1
            
                            # Add instance_of as tags
                            if brand['instance_of']:
                                tag_id = create_uid()
                                cursor.execute("""
                                    INSERT OR IGNORE INTO tags (id, entity_id, entity_type, tag, source)
                                    VALUES (?, ?, ?, ?, ?)
                                """, (
                                    tag_id,
                                    brand_id,
                                    'brand',
                                    brand['instance_of'],
                                    'wikidata'
                                ))
                            
                            # Link to parent company if available
                            if brand['parent_company_id']:
                                # Check if parent company exists
                                cursor.execute("SELECT id FROM company WHERE wikidata_id = ?", 
                                              (brand['parent_company_id'],))
                                parent_company = cursor.fetchone()
                                
                                if parent_company:
                                    # Update brand with company reference
                                    cursor.execute("""
                                        UPDATE brand SET company_id = ? WHERE id = ?
                                    """, (parent_company[0], brand_id))
                        else:
                            stats['existing_brands'] += 1
                    except Exception as e:
                        logger.error(f"Error processing brand {brand['wikidata_id']}: {e}")
                        stats['errors'] += 1
                
                # Commit after processing brands in each file
                conn.commit()
                stats['files_processed'] += 1
                
            except Exception as e:
                logger.error(f"Error processing file {file_path}: {e}")
                stats['errors'] += 1
        
        # Process collected company data
        logger.info(f"Processing {len(company_data)} unique companies")
        for wikidata_id, data in tqdm(company_data.items(), desc="Processing companies"):
            try:
                # Check if company already exists
                cursor.execute("SELECT id FROM company WHERE wikidata_id = ?", (wikidata_id,))
                existing_company = cursor.fetchone()
                
                if not existing_company:
                    # Generate UID for new company
                    company_id = create_uid()
                    
                    # Insert new company
                    cursor.execute("""
                        INSERT INTO company (
                            id, name, wikidata_id, description, 
                            founded_date, website, industry, source
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        company_id,
                        data['name'],
                        wikidata_id,
                        data['description'],
                        data['inception_date'],
                        data['website'],
                        data['industry'],
                        'wikidata'
                    ))
                    stats['new_companies'] += 1
                    
                    # Add instance_of values as tags
                    for instance_type in data['instance_of']:
                        if instance_type:
                            tag_id = create_uid()
                            cursor.execute("""
                                INSERT OR IGNORE INTO tags (id, entity_id, entity_type, tag, source)
                                VALUES (?, ?, ?, ?, ?)
                            """, (
                                tag_id,
                                company_id,
                                'company',
                                instance_type,
                                'wikidata'
                            ))
                else:
                    company_id = existing_company[0]
                    
                    # Update existing company with any new information
                    cursor.execute("""
                        UPDATE company 
                        SET 
                            name = COALESCE(NULLIF(?, ''), name),
                            description = COALESCE(NULLIF(?, ''), description),
                            founded_date = COALESCE(NULLIF(?, ''), founded_date),
                            website = COALESCE(NULLIF(?, ''), website),
                            industry = COALESCE(NULLIF(?, ''), industry)
                        WHERE id = ?
                    """, (
                        data['name'],
                        data['description'],
                        data['inception_date'],
                        data['website'],
                        data['industry'],
                        company_id
                    ))
                    
                    # Add instance_of values as tags
                    for instance_type in data['instance_of']:
                        if instance_type:
                            tag_id = create_uid()
                            cursor.execute("""
                                INSERT OR IGNORE INTO tags (id, entity_id, entity_type, tag, source)
                                VALUES (?, ?, ?, ?, ?)
                            """, (
                                tag_id,
                                company_id,
                                'company',
                                instance_type,
                                'wikidata'
                            ))
                    
                    stats['existing_companies'] += 1
                    stats['updated_companies'] += 1
        except Exception as e:
            logger.error(f"Error processing company {wikidata_id}: {e}")
                stats['errors'] += 1
        
        # Final commit
        conn.commit()
        
        logger.info(f"Import completed. Stats: {stats}")
        
    finally:
        # Close connections
        conn.close()
        duck_conn.close()
    
    return stats

if __name__ == "__main__":
    """
# Normal one-time fetch
python collect_brands.py

# Trickle fetch with 5 minute delay
python collect_brands.py --trickle

# Trickle fetch with custom delay
python collect_brands.py --trickle --delay 10    

# Import Wikidata entities from parquet files
python collect_brands.py --import-entities

# Import Wikidata entities with custom database path
python collect_brands.py --import-entities --db-path /path/to/database.sqlite
    """
    import argparse
    
    parser = argparse.ArgumentParser(description='Fetch brands from Wikidata and EUIPO')
    parser.add_argument('--trickle', action='store_true', help='Run in trickle mode')
    parser.add_argument('--delay', type=int, default=5, help='Delay between cycles in minutes')
    parser.add_argument('--import-entities', action='store_true', help='Import Wikidata entities from parquet files')
    parser.add_argument('--db-path', type=str, default=None, help='Path to SQLite database')
    
    args = parser.parse_args()
    
    if args.import_entities:
        # Determine database path
        if args.db_path:
            db_path = Path(args.db_path)
    else:
            db_path = Path(__file__).parent / "record-thing.sqlite"
        
        # Import entities
        populate_from_wikidata_entities(db_path)

    