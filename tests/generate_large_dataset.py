#!/usr/bin/env python3
"""
Generate large dataset for testing.
Creates a database with substantial data for performance and stress testing.
"""

import sys
import time
import sqlite3
from pathlib import Path
from typing import Dict, Any

# Add the project root to the Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from libs.record_thing.db.connection import connect_to_db
from libs.record_thing.db_setup import create_database, create_tables
from libs.record_thing.db.operations import generate_testdata_records
from libs.record_thing.db.schema import ensure_owner_account, ensure_teams
from libs.record_thing.db.uid import create_uid
from libs.record_thing.commons import commons


def generate_large_dataset(db_path: Path, config: Dict[str, Any] = None) -> Dict[str, Any]:
    """
    Generate a large dataset for testing.
    
    Args:
        db_path: Path to the database file
        config: Configuration for data generation
    
    Returns:
        Dictionary with generation statistics
    """
    if config is None:
        config = {
            'things_count': 1000,
            'evidence_per_thing': 3,
            'requests_count': 200,
            'evidence_types_count': 100,
            'document_types_count': 50,
        }
    
    print(f"Generating large dataset at {db_path}")
    print(f"Configuration: {config}")
    
    start_time = time.time()
    
    # Create database with basic schema
    create_tables(db_path)
    
    conn = connect_to_db(db_path)
    cursor = conn.cursor()
    
    # Ensure basic accounts and teams
    ensure_owner_account(conn, dummy_account_data=True)
    ensure_teams(conn)
    conn.commit()
    
    # Generate evidence types
    print("Generating evidence types...")
    evidence_types = []
    for i in range(config['evidence_types_count']):
        evidence_types.append((
            i + 1,  # id
            'en',   # lang
            f'Category {i // 10}',  # rootName
            f'Evidence Type {i}',   # name
            f'https://example.com/evidence-type/{i}',  # url
            f'GPC Root {i}',  # gpcRoot
            f'GPC Name {i}',  # gpcName
            1000 + i,  # gpcCode
            2000 + i,  # unspscID
            f'/icons/evidence-type-{i}.png'  # icon_path
        ))
    
    cursor.executemany("""
        INSERT OR IGNORE INTO evidence_type 
        (id, lang, rootName, name, url, gpcRoot, gpcName, gpcCode, unspscID, icon_path)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, evidence_types)
    
    # Generate document types
    print("Generating document types...")
    document_types = []
    for i in range(config['document_types_count']):
        document_types.append((
            'en',  # lang
            f'Document Category {i // 5}',  # rootName
            f'Document Type {i}',  # name
            f'https://example.com/document-type/{i}',  # url
        ))
    
    cursor.executemany("""
        INSERT OR IGNORE INTO document_type (lang, rootName, name, url)
        VALUES (?, ?, ?, ?)
    """, document_types)
    
    # Generate things
    print(f"Generating {config['things_count']} things...")
    things = []
    brands = ['Apple', 'Samsung', 'Sony', 'LG', 'Dell', 'HP', 'Lenovo', 'ASUS', 'Acer', 'MSI']
    categories = ['Electronics', 'Furniture', 'Appliances', 'Tools', 'Sports', 'Books', 'Clothing', 'Toys']
    
    for i in range(config['things_count']):
        thing_id = create_uid()
        created_at = 1640995200.0 + (i * 3600)  # Spread over time
        updated_at = created_at + (i % 1000)  # Some variation
        
        things.append((
            thing_id,
            commons["owner_id"],
            f"UPC{1000000 + i}",  # upc
            f"ASIN{i:08d}",  # asin
            f"ELID{i:08d}",  # elid
            brands[i % len(brands)],  # brand
            f"Model {i}",  # model
            ['Black', 'White', 'Silver', 'Blue', 'Red'][i % 5],  # color
            f'["tag{i}", "tag{i+1}", "category{i%10}"]',  # tags (JSON)
            categories[i % len(categories)],  # category
            str((i % config['evidence_types_count']) + 1),  # evidence_type
            f"Evidence Type {(i % config['evidence_types_count'])}",  # evidence_type_name
            f"Large Dataset Thing {i}",  # title
            f"This is a test thing #{i} generated for large dataset testing. " * 3,  # description
            created_at,
            updated_at
        ))
        
        if (i + 1) % 100 == 0:
            print(f"  Generated {i + 1} things...")
    
    cursor.executemany("""
        INSERT INTO things (
            id, account_id, upc, asin, elid, brand, model, color, tags, category,
            evidence_type, evidence_type_name, title, description, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, things)
    
    # Generate evidence
    print(f"Generating evidence ({config['evidence_per_thing']} per thing)...")
    evidence = []
    evidence_types_list = ['Receipt', 'Photo', 'Manual', 'Warranty', 'Invoice', 'Certificate']
    
    evidence_count = 0
    for i, thing in enumerate(things):
        thing_id = thing[0]  # First element is the thing ID
        
        for j in range(config['evidence_per_thing']):
            evidence_id = create_uid()
            created_at = 1640995200.0 + (i * 3600) + (j * 60)
            updated_at = created_at + (j * 10)
            
            evidence.append((
                evidence_id,
                commons["owner_id"],  # thing_account_id
                thing_id,  # thing_id
                None,  # request_id
                f"{evidence_types_list[j % len(evidence_types_list)]} for Thing {i}",  # name
                f"Evidence description for thing {i}, evidence {j}. " * 2,  # description
                f"https://example.com/evidence/{evidence_id}",  # url
                created_at,
                updated_at
            ))
            evidence_count += 1
        
        if (i + 1) % 100 == 0:
            print(f"  Generated evidence for {i + 1} things ({evidence_count} total evidence)...")
    
    cursor.executemany("""
        INSERT INTO evidence (
            id, thing_account_id, thing_id, request_id, name, description, url, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, evidence)
    
    # Generate requests
    print(f"Generating {config['requests_count']} requests...")
    requests = []
    request_types = ['Insurance Claim', 'Warranty Service', 'Registration', 'Appraisal', 'Service Request']
    statuses = ['pending', 'in_progress', 'completed', 'cancelled']
    delivery_methods = ['email', 'sms', 'webhook', 'http_post']
    
    for i in range(config['requests_count']):
        created_at = 1640995200.0 + (i * 7200)  # Spread over time
        completed_at = created_at + (24 * 3600) if i % 3 == 0 else None  # Some completed
        
        requests.append((
            i + 1,  # id
            commons["owner_id"],  # account_id
            f"https://example.com/requests/{i + 1}",  # url
            (i % 3) + 1,  # universe_id
            request_types[i % len(request_types)],  # type
            f'{{"priority": "medium", "notes": "Large dataset request {i}"}}',  # data (JSON)
            statuses[i % len(statuses)],  # status
            created_at,
            completed_at,
            delivery_methods[i % len(delivery_methods)],  # delivery_method
            f"target{i}@example.com"  # delivery_target
        ))
    
    cursor.executemany("""
        INSERT INTO requests (
            id, account_id, url, universe_id, type, data, status, created_at, completed_at,
            delivery_method, delivery_target
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, requests)
    
    # Generate some universe records
    print("Generating universe records...")
    universes = [
        (
            "https://example.com/universe/large-dataset",
            "Large Dataset Universe",
            "Universe for large dataset testing",
            "2.0.0",
            "2024-01-01T00:00:00Z",
            "checksum_large_dataset",
            "SHA256",
            True, True, True, False, False, False, False, False, False,
            '["large_dataset"]',
            '["testing", "performance"]',
            '{"active": true, "size": "large"}'
        )
    ]
    
    cursor.executemany("""
        INSERT OR IGNORE INTO universe (
            url, name, description, version, date, checksum, checksum_type,
            is_downloaded, is_installed, is_running, is_paused, is_stopped,
            is_failed, is_completed, is_cancelled, is_deleted,
            enabled_menus, enabled_features, flags
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, universes)
    
    # Commit all changes
    conn.commit()
    conn.close()
    
    generation_time = time.time() - start_time
    
    # Get final statistics
    conn = connect_to_db(db_path, read_only=True)
    cursor = conn.cursor()
    
    stats = {}
    for table in ['accounts', 'things', 'evidence', 'evidence_type', 'document_type', 'requests', 'universe']:
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        stats[table] = cursor.fetchone()[0]
    
    conn.close()
    
    # Get file size
    file_size = db_path.stat().st_size
    
    result = {
        'generation_time': generation_time,
        'file_size': file_size,
        'file_size_mb': file_size / (1024 * 1024),
        'record_counts': stats,
        'total_records': sum(stats.values()),
        'config': config
    }
    
    print(f"\nLarge dataset generation complete!")
    print(f"Time: {generation_time:.2f} seconds")
    print(f"File size: {file_size:,} bytes ({file_size / (1024 * 1024):.2f} MB)")
    print(f"Total records: {sum(stats.values()):,}")
    print(f"Record breakdown: {stats}")
    
    return result


def main():
    """Main entry point."""
    if len(sys.argv) != 2:
        print("Usage: python generate_large_dataset.py <output_path>")
        sys.exit(1)
    
    output_path = Path(sys.argv[1])
    
    # Ensure output directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Generate large dataset
    config = {
        'things_count': 2000,
        'evidence_per_thing': 4,
        'requests_count': 400,
        'evidence_types_count': 150,
        'document_types_count': 75,
    }
    
    try:
        result = generate_large_dataset(output_path, config)
        
        # Save statistics
        stats_path = output_path.with_suffix('.json')
        import json
        with open(stats_path, 'w') as f:
            json.dump(result, f, indent=2)
        
        print(f"Statistics saved to: {stats_path}")
        
    except Exception as e:
        print(f"Error generating large dataset: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
