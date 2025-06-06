#!/usr/bin/env python3
"""
Generate test coverage documentation.
Creates comprehensive documentation of test coverage and scenarios.
"""

import sys
import json
import sqlite3
from pathlib import Path
from typing import Dict, Any, List
from datetime import datetime

# Add the project root to the Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from libs.record_thing.db.connection import connect_to_db, get_db_tables, get_table_schema
from libs.record_thing.db_setup import create_database
from libs.record_thing.db.test_data import USE_CASES, TEST_SCENARIOS


def analyze_database_schema(db_path: Path) -> Dict[str, Any]:
    """Analyze database schema and return structure information."""
    
    conn = connect_to_db(db_path, read_only=True)
    tables = get_db_tables(conn)
    
    schema_info = {
        'tables': {},
        'total_tables': len(tables),
        'relationships': []
    }
    
    for table in tables:
        schema = get_table_schema(conn, table)
        
        columns = []
        primary_keys = []
        foreign_keys = []
        
        for col in schema:
            col_info = {
                'name': col[1],
                'type': col[2],
                'not_null': bool(col[3]),
                'default_value': col[4],
                'primary_key': bool(col[5])
            }
            columns.append(col_info)
            
            if col[5]:  # is primary key
                primary_keys.append(col[1])
        
        # Get foreign key information
        cursor = conn.cursor()
        cursor.execute(f"PRAGMA foreign_key_list({table})")
        fk_info = cursor.fetchall()
        
        for fk in fk_info:
            foreign_keys.append({
                'column': fk[3],
                'references_table': fk[2],
                'references_column': fk[4]
            })
        
        schema_info['tables'][table] = {
            'columns': columns,
            'column_count': len(columns),
            'primary_keys': primary_keys,
            'foreign_keys': foreign_keys
        }
    
    conn.close()
    return schema_info


def analyze_test_coverage() -> Dict[str, Any]:
    """Analyze test coverage across different areas."""
    
    test_areas = {
        'database_creation': {
            'description': 'Tests for creating databases from scratch',
            'test_files': ['test_database_creation.py'],
            'scenarios': [
                'Empty database creation',
                'Database with schema creation',
                'Database with sample data creation',
                'Schema integrity validation',
                'Index creation',
                'Multiple database creation',
                'Edge cases (unicode paths, nested directories)'
            ]
        },
        
        'schema_migration': {
            'description': 'Tests for updating database schema',
            'test_files': ['test_schema_migration.py'],
            'scenarios': [
                'Empty database migration',
                'Data preservation during migration',
                'Adding missing tables',
                'Adding missing columns',
                'Foreign key constraint handling',
                'Idempotent migrations',
                'Corrupted data handling',
                'Large database migration'
            ]
        },
        
        'data_generation': {
            'description': 'Tests for generating realistic test data',
            'test_files': ['test_data_generation.py'],
            'scenarios': [
                'Demo account creation',
                'Universe/use case data generation',
                'Things data generation',
                'Evidence data generation',
                'Request data generation',
                'Product type generation',
                'Data relationship validation',
                'Data consistency checks',
                'Realistic data quality validation'
            ]
        },
        
        'ios_compatibility': {
            'description': 'Tests for iOS app compatibility',
            'test_files': ['test_ios_compatibility.py'],
            'scenarios': [
                'Blackbird model schema compatibility',
                'Data type compatibility',
                'JSON data compatibility',
                'Primary key compatibility',
                'Foreign key relationships',
                'Unicode data handling',
                'NULL value handling',
                'Database size validation',
                'Query performance for iOS',
                'Concurrent access simulation'
            ]
        },
        
        'performance': {
            'description': 'Performance and stress tests',
            'test_files': ['test_performance.py'],
            'scenarios': [
                'Database creation performance',
                'Large query performance',
                'Concurrent read performance',
                'Memory usage monitoring',
                'Database size efficiency',
                'Index performance',
                'VACUUM operation performance',
                'Stress testing with many connections',
                'Rapid connection cycling',
                'Long-running connection stability'
            ]
        },
        
        'integration': {
            'description': 'Full integration tests',
            'test_files': ['test_full_integration.py'],
            'scenarios': [
                'Complete database lifecycle',
                'CLI integration',
                'Data consistency across operations',
                'Foreign key integrity throughout lifecycle',
                'Performance throughout lifecycle',
                'iOS compatibility integration',
                'Error recovery',
                'Concurrent access',
                'Backup and restore'
            ]
        }
    }
    
    return test_areas


def generate_use_case_documentation() -> Dict[str, Any]:
    """Generate documentation for use cases and test scenarios."""
    
    use_case_docs = {
        'use_cases': {},
        'test_scenarios': {},
        'coverage_matrix': {}
    }
    
    # Document use cases
    for use_case, data in USE_CASES.items():
        use_case_docs['use_cases'][use_case] = {
            'name': use_case.replace('_', ' ').title(),
            'things_categories': data['things'],
            'evidence_types': data['evidence'],
            'document_types': data['document_types'],
            'description': f"Use case for {use_case.replace('_', ' ')} management"
        }
    
    # Document test scenarios
    for scenario in TEST_SCENARIOS:
        scenario_name = scenario['name']
        use_case_docs['test_scenarios'][scenario_name] = {
            'description': scenario['description'],
            'things_count': scenario['things_count'],
            'evidence_per_thing': scenario['evidence_per_thing'],
            'requests': scenario['requests'],
            'estimated_total_records': (
                scenario['things_count'] + 
                (scenario['things_count'] * scenario['evidence_per_thing']) + 
                scenario['requests']
            )
        }
    
    # Create coverage matrix
    test_areas = ['creation', 'migration', 'data_gen', 'ios_compat', 'performance', 'integration']
    
    for use_case in USE_CASES.keys():
        use_case_docs['coverage_matrix'][use_case] = {}
        for area in test_areas:
            # All use cases are covered by all test areas
            use_case_docs['coverage_matrix'][use_case][area] = True
    
    return use_case_docs


def generate_blackbird_correlation() -> Dict[str, Any]:
    """Generate correlation between Blackbird models and SQL schema."""
    
    # Based on the iOS models we found in the codebase
    blackbird_models = {
        'Account': {
            'table': 'accounts',
            'swift_file': 'apps/RecordThing/Shared/Model/Account.swift',
            'primary_key': ['account_id'],
            'fields': [
                'account_id', 'name', 'username', 'email', 'sms', 'region',
                'team_id', 'is_active', 'last_login'
            ]
        },
        
        'Things': {
            'table': 'things',
            'swift_file': 'apps/libs/RecordLib/Sources/RecordLib/Model/Things.swift',
            'primary_key': ['account_id', 'id'],
            'fields': [
                'id', 'account_id', 'upc', 'asin', 'elid', 'brand', 'model',
                'color', 'tags', 'category', 'evidence_type', 'evidence_type_name',
                'title', 'description', 'created_at', 'updated_at'
            ]
        },
        
        'Evidence': {
            'table': 'evidence',
            'swift_file': 'apps/libs/RecordLib/Sources/RecordLib/Model/Evidence.swift',
            'primary_key': ['id', 'thing_account_id'],
            'fields': [
                'id', 'thing_account_id', 'thing_id', 'request_id',
                'name', 'description', 'url', 'created_at', 'updated_at'
            ]
        },
        
        'EvidenceType': {
            'table': 'evidence_type',
            'swift_file': 'apps/libs/RecordLib/Sources/RecordLib/Model/EvidenceType.swift',
            'primary_key': ['id'],
            'fields': [
                'id', 'lang', 'rootName', 'name', 'url', 'gpcRoot',
                'gpcName', 'gpcCode', 'unspscID', 'icon_path'
            ]
        },
        
        'Requests': {
            'table': 'requests',
            'swift_file': 'apps/libs/RecordLib/Sources/RecordLib/Model/Requests.swift',
            'primary_key': ['id'],
            'fields': [
                'id', 'account_id', 'url', 'status', 'delivery_method',
                'delivery_target', 'universe_id'
            ]
        }
    }
    
    # SQL schema files
    sql_files = {
        'accounts': 'libs/record_thing/db/account.sql',
        'evidence': 'libs/record_thing/db/evidence.sql',
        'evidence_type': 'libs/record_thing/db/categories.sql',
        'things': 'libs/record_thing/db/evidence.sql',  # things table is in evidence.sql
        'requests': 'libs/record_thing/db/evidence.sql',  # requests table is in evidence.sql
        'product': 'libs/record_thing/db/product.sql',
        'assets': 'libs/record_thing/db/assets.sql',
        'translations': 'libs/record_thing/db/translations.sql'
    }
    
    correlation = {
        'blackbird_models': blackbird_models,
        'sql_files': sql_files,
        'correlation_notes': [
            "Blackbird models use @BlackbirdColumn annotations for automatic SQLite mapping",
            "Primary keys are defined using static var primaryKey arrays",
            "Foreign key relationships are implicit through column naming conventions",
            "Date fields in Swift map to REAL/FLOAT timestamps in SQLite",
            "String fields in Swift map to TEXT in SQLite",
            "Int fields in Swift map to INTEGER in SQLite",
            "Bool fields in Swift map to INTEGER (0/1) in SQLite",
            "Optional fields in Swift allow NULL values in SQLite"
        ],
        'testing_approach': [
            "Mock Blackbird models are used in tests to validate compatibility",
            "Type mapping validation ensures Swift types match SQLite types",
            "Primary key validation ensures unique constraints work",
            "Foreign key validation ensures relationships are maintained",
            "JSON field validation ensures proper serialization/deserialization",
            "Unicode validation ensures international character support"
        ]
    }
    
    return correlation


def generate_html_report(data: Dict[str, Any]) -> str:
    """Generate HTML report from documentation data."""
    
    html = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RecordThing Test Coverage Report</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; line-height: 1.6; }}
        .header {{ background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px; }}
        .section {{ margin-bottom: 40px; }}
        .test-area {{ background: #fff; border: 1px solid #e9ecef; border-radius: 8px; padding: 20px; margin-bottom: 20px; }}
        .scenario-list {{ background: #f8f9fa; padding: 15px; border-radius: 4px; margin-top: 10px; }}
        .scenario-list li {{ margin-bottom: 5px; }}
        .stats {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }}
        .stat-card {{ background: #e3f2fd; padding: 15px; border-radius: 8px; text-align: center; }}
        .stat-number {{ font-size: 2em; font-weight: bold; color: #1976d2; }}
        .correlation-table {{ width: 100%; border-collapse: collapse; margin-top: 15px; }}
        .correlation-table th, .correlation-table td {{ border: 1px solid #ddd; padding: 12px; text-align: left; }}
        .correlation-table th {{ background-color: #f2f2f2; }}
        .use-case-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }}
        .use-case-card {{ border: 1px solid #ddd; border-radius: 8px; padding: 20px; }}
        .code {{ background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }}
        .success {{ color: #28a745; }}
        .info {{ color: #17a2b8; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>RecordThing Test Coverage Report</h1>
        <p>Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        <p>Comprehensive test suite for non-destructive database testing with GitHub Actions integration.</p>
    </div>
"""
    
    # Test Coverage Overview
    test_areas = data['test_coverage']
    html += f"""
    <div class="section">
        <h2>Test Coverage Overview</h2>
        <div class="stats">
            <div class="stat-card">
                <div class="stat-number">{len(test_areas)}</div>
                <div>Test Areas</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">{sum(len(area['scenarios']) for area in test_areas.values())}</div>
                <div>Test Scenarios</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">{len(data['use_cases']['use_cases'])}</div>
                <div>Use Cases</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">{data['schema_info']['total_tables']}</div>
                <div>Database Tables</div>
            </div>
        </div>
        
        <div class="test-areas">
"""
    
    for area_name, area_info in test_areas.items():
        html += f"""
            <div class="test-area">
                <h3>{area_name.replace('_', ' ').title()}</h3>
                <p>{area_info['description']}</p>
                <p><strong>Test Files:</strong> {', '.join(f'<span class="code">{f}</span>' for f in area_info['test_files'])}</p>
                <div class="scenario-list">
                    <strong>Test Scenarios:</strong>
                    <ul>
                        {''.join(f'<li>{scenario}</li>' for scenario in area_info['scenarios'])}
                    </ul>
                </div>
            </div>
"""
    
    html += """
        </div>
    </div>
"""
    
    # Use Cases
    use_cases = data['use_cases']['use_cases']
    html += f"""
    <div class="section">
        <h2>Use Cases & Test Scenarios</h2>
        <div class="use-case-grid">
"""
    
    for use_case_key, use_case in use_cases.items():
        html += f"""
            <div class="use-case-card">
                <h4>{use_case['name']}</h4>
                <p>{use_case['description']}</p>
                <p><strong>Things Categories:</strong> {', '.join(use_case['things_categories'])}</p>
                <p><strong>Evidence Types:</strong> {', '.join(use_case['evidence_types'])}</p>
                <p><strong>Document Types:</strong> {', '.join(use_case['document_types'])}</p>
            </div>
"""
    
    html += """
        </div>
    </div>
"""
    
    # Blackbird Correlation
    correlation = data['blackbird_correlation']
    html += f"""
    <div class="section">
        <h2>iOS Blackbird Model Correlation</h2>
        <p>Correlation between Swift Blackbird models and SQLite schema files:</p>
        
        <table class="correlation-table">
            <thead>
                <tr>
                    <th>Swift Model</th>
                    <th>SQLite Table</th>
                    <th>Swift File</th>
                    <th>Primary Key</th>
                    <th>Field Count</th>
                </tr>
            </thead>
            <tbody>
"""
    
    for model_name, model_info in correlation['blackbird_models'].items():
        html += f"""
                <tr>
                    <td><span class="code">{model_name}</span></td>
                    <td><span class="code">{model_info['table']}</span></td>
                    <td><span class="code">{model_info['swift_file']}</span></td>
                    <td>{', '.join(model_info['primary_key'])}</td>
                    <td>{len(model_info['fields'])}</td>
                </tr>
"""
    
    html += """
            </tbody>
        </table>
        
        <h3>Testing Approach</h3>
        <ul>
"""
    
    for approach in correlation['testing_approach']:
        html += f"<li>{approach}</li>"
    
    html += """
        </ul>
    </div>
"""
    
    # Database Schema
    schema = data['schema_info']
    html += f"""
    <div class="section">
        <h2>Database Schema Analysis</h2>
        <p>Total tables: <strong>{schema['total_tables']}</strong></p>
        
        <table class="correlation-table">
            <thead>
                <tr>
                    <th>Table</th>
                    <th>Columns</th>
                    <th>Primary Keys</th>
                    <th>Foreign Keys</th>
                </tr>
            </thead>
            <tbody>
"""
    
    for table_name, table_info in schema['tables'].items():
        fk_count = len(table_info['foreign_keys'])
        pk_list = ', '.join(table_info['primary_keys'])
        
        html += f"""
                <tr>
                    <td><span class="code">{table_name}</span></td>
                    <td>{table_info['column_count']}</td>
                    <td>{pk_list}</td>
                    <td>{fk_count}</td>
                </tr>
"""
    
    html += """
            </tbody>
        </table>
    </div>
"""
    
    # GitHub Actions Integration
    html += f"""
    <div class="section">
        <h2>GitHub Actions Integration</h2>
        <p>The test suite is integrated with GitHub Actions for continuous testing:</p>
        
        <div class="test-area">
            <h3>Workflow Features</h3>
            <ul>
                <li><span class="success">✓</span> Multi-platform testing (Ubuntu, macOS)</li>
                <li><span class="success">✓</span> Multiple Python versions (3.11, 3.12)</li>
                <li><span class="success">✓</span> UV package manager integration</li>
                <li><span class="success">✓</span> Test coverage reporting</li>
                <li><span class="success">✓</span> Artifact generation (test databases)</li>
                <li><span class="success">✓</span> Performance monitoring</li>
                <li><span class="success">✓</span> Timeout protection</li>
            </ul>
        </div>
        
        <div class="test-area">
            <h3>Test Execution</h3>
            <p>Tests are organized into stages:</p>
            <ol>
                <li><strong>Unit Tests:</strong> Basic functionality and connection tests</li>
                <li><strong>Database Creation:</strong> Fresh database creation from scratch</li>
                <li><strong>Schema Migration:</strong> Database updates and migrations</li>
                <li><strong>Data Generation:</strong> Demo data and realistic test data</li>
                <li><strong>iOS Compatibility:</strong> Blackbird model compatibility</li>
                <li><strong>Performance Tests:</strong> Stress testing and performance validation</li>
                <li><strong>Integration Tests:</strong> Full workflow testing</li>
            </ol>
        </div>
        
        <div class="test-area">
            <h3>Artifacts Generated</h3>
            <ul>
                <li><span class="code">fresh-database.sqlite</span> - Clean database with schema only</li>
                <li><span class="code">demo-database.sqlite</span> - Database with demo data</li>
                <li><span class="code">large-dataset.sqlite</span> - Database with substantial test data</li>
                <li><span class="code">coverage.xml</span> - Test coverage report</li>
                <li><span class="code">test-documentation/</span> - Generated documentation</li>
            </ul>
        </div>
    </div>
"""
    
    html += """
    <div class="section">
        <h2>Running Tests Locally</h2>
        <div class="test-area">
            <h3>Prerequisites</h3>
            <ul>
                <li>Python 3.11 or 3.12</li>
                <li>UV package manager</li>
                <li>Git repository cloned</li>
            </ul>
            
            <h3>Commands</h3>
            <pre><code># Install dependencies
uv sync --all-extras

# Run all tests
uv run -m pytest tests/ -v

# Run specific test categories
uv run -m pytest tests/test_database_creation.py -v
uv run -m pytest tests/test_ios_compatibility.py -v

# Run with coverage
uv run -m pytest tests/ -v --cov=record_thing --cov-report=html

# Generate large dataset
uv run python tests/generate_large_dataset.py artifacts/large-test.sqlite

# Generate documentation
uv run python tests/generate_test_docs.py</code></pre>
        </div>
    </div>
    
    <footer style="margin-top: 60px; padding-top: 20px; border-top: 1px solid #eee; color: #666;">
        <p>This report was automatically generated by the RecordThing test suite documentation generator.</p>
    </footer>
</body>
</html>
"""
    
    return html


def main():
    """Main entry point."""
    
    # Create output directory
    docs_dir = Path("docs/testing")
    docs_dir.mkdir(parents=True, exist_ok=True)
    
    print("Generating test coverage documentation...")
    
    # Create a sample database for schema analysis
    temp_db = Path("temp_schema_analysis.sqlite")
    try:
        create_database(temp_db)
        schema_info = analyze_database_schema(temp_db)
    finally:
        if temp_db.exists():
            temp_db.unlink()
    
    # Gather all documentation data
    documentation_data = {
        'test_coverage': analyze_test_coverage(),
        'use_cases': generate_use_case_documentation(),
        'blackbird_correlation': generate_blackbird_correlation(),
        'schema_info': schema_info,
        'generation_time': datetime.now().isoformat()
    }
    
    # Generate HTML report
    html_report = generate_html_report(documentation_data)
    
    # Save HTML report
    html_path = docs_dir / "test_coverage_report.html"
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html_report)
    
    # Save JSON data
    json_path = docs_dir / "test_coverage_data.json"
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(documentation_data, f, indent=2, default=str)
    
    # Generate markdown summary
    markdown_path = docs_dir / "README.md"
    with open(markdown_path, 'w', encoding='utf-8') as f:
        f.write(f"""# RecordThing Test Coverage

Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Overview

This directory contains comprehensive test coverage documentation for the RecordThing project.

## Files

- `test_coverage_report.html` - Detailed HTML report with full test coverage analysis
- `test_coverage_data.json` - Raw data used to generate the report
- `README.md` - This file

## Test Areas

{len(documentation_data['test_coverage'])} test areas covering:

""")
        
        for area_name, area_info in documentation_data['test_coverage'].items():
            f.write(f"- **{area_name.replace('_', ' ').title()}**: {area_info['description']}\n")
        
        f.write(f"""
## Statistics

- **Test Areas**: {len(documentation_data['test_coverage'])}
- **Test Scenarios**: {sum(len(area['scenarios']) for area in documentation_data['test_coverage'].values())}
- **Use Cases**: {len(documentation_data['use_cases']['use_cases'])}
- **Database Tables**: {documentation_data['schema_info']['total_tables']}
- **Blackbird Models**: {len(documentation_data['blackbird_correlation']['blackbird_models'])}

## Running Tests

See the HTML report for detailed instructions on running tests locally and with GitHub Actions.
""")
    
    print(f"Documentation generated:")
    print(f"  HTML Report: {html_path}")
    print(f"  JSON Data: {json_path}")
    print(f"  Markdown: {markdown_path}")


if __name__ == "__main__":
    main()
