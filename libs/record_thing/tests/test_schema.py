import pytest
from pathlib import Path
from ..db.schema import parse_sql_schema

# Test SQL content
TEST_SQL = """
-- Test table with migrations
CREATE TABLE IF NOT EXISTS test_table (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT
);

-- version: 1
ALTER TABLE test_table ADD COLUMN value DECIMAL(10,2);
ALTER TABLE test_table ADD COLUMN currency TEXT DEFAULT 'USD';

-- version: 2
ALTER TABLE test_table ADD COLUMN status TEXT CHECK(status IN ('active', 'inactive')) DEFAULT 'active';

-- Another table
CREATE TABLE IF NOT EXISTS another_table (
    id INTEGER PRIMARY KEY,
    test_id TEXT,
    data TEXT
);

-- version: 3
ALTER TABLE another_table ADD COLUMN tags TEXT;
"""

def test_parse_sql_schema(tmp_path):
    """Test parsing SQL schema with migrations."""
    # Create temporary SQL file
    sql_file = tmp_path / "test.sql"
    sql_file.write_text(TEST_SQL)
    
    # Parse schema
    migrations = parse_sql_schema(sql_file)
    
    # Test base schema (version 0)
    assert 0 in migrations
    base_columns = {c['column']: c for c in migrations[0]}
    assert 'id' in base_columns
    assert 'name' in base_columns
    assert base_columns['name']['definition'].upper().startswith('TEXT')
    
    # Test migrations
    assert 1 in migrations
    version1_changes = {c['column']: c for c in migrations[1]}
    assert 'value' in version1_changes
    assert 'currency' in version1_changes
    assert version1_changes['currency']['definition'].endswith("DEFAULT 'USD'")
    
    assert 2 in migrations
    version2_changes = {c['column']: c for c in migrations[2]}
    assert 'status' in version2_changes
    assert 'CHECK' in version2_changes['status']['definition']
    
    assert 3 in migrations
    version3_changes = {c['column']: c for c in migrations[3]}
    assert 'tags' in version3_changes
    assert version3_changes['tags']['table'] == 'another_table'

def test_parse_sql_schema_with_constraints():
    """Test parsing SQL schema with various constraints."""
    sql = """
    CREATE TABLE test_constraints (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        age INTEGER CHECK(age >= 0),
        status TEXT DEFAULT 'pending',
        FOREIGN KEY (id) REFERENCES other_table(id)
    );
    """
    sql_file = Path("test_constraints.sql")
    sql_file.write_text(sql)
    
    try:
        migrations = parse_sql_schema(sql_file)
        
        assert 0 in migrations
        columns = {c['column']: c for c in migrations[0]}
        
        assert 'email' in columns
        assert 'UNIQUE' in columns['email']['definition']
        assert 'NOT NULL' in columns['email']['definition']
        
        assert 'age' in columns
        assert 'CHECK' in columns['age']['definition']
        
        assert 'status' in columns
        assert "DEFAULT 'pending'" in columns['status']['definition']
    
    finally:
        sql_file.unlink()

def test_parse_sql_schema_empty_file(tmp_path):
    """Test parsing empty SQL file."""
    sql_file = tmp_path / "empty.sql"
    sql_file.write_text("")
    
    migrations = parse_sql_schema(sql_file)
    assert len(migrations) == 0

def test_parse_sql_schema_no_migrations(tmp_path):
    """Test parsing SQL with no migrations."""
    sql = """
    CREATE TABLE test_table (
        id TEXT PRIMARY KEY,
        name TEXT
    );
    """
    sql_file = tmp_path / "no_migrations.sql"
    sql_file.write_text(sql)
    
    migrations = parse_sql_schema(sql_file)
    assert len(migrations) == 1  # Only version 0 (base schema)
    assert 0 in migrations
    columns = {c['column']: c for c in migrations[0]}
    assert len(columns) == 2
    assert 'id' in columns
    assert 'name' in columns

def test_parse_sql_schema_invalid_version(tmp_path):
    """Test parsing SQL with invalid version comment."""
    sql = """
    CREATE TABLE test_table (id TEXT PRIMARY KEY);
    
    -- version: invalid
    ALTER TABLE test_table ADD COLUMN name TEXT;
    """
    sql_file = tmp_path / "invalid_version.sql"
    sql_file.write_text(sql)
    
    migrations = parse_sql_schema(sql_file)
    # Should default to version 1 for invalid version
    assert 1 in migrations
    assert len(migrations[1]) == 1
    assert migrations[1][0]['column'] == 'name'

def test_parse_sql_schema_multiple_tables(tmp_path):
    """Test parsing SQL with multiple tables and shared version numbers."""
    sql = """
    CREATE TABLE table1 (id TEXT PRIMARY KEY);
    CREATE TABLE table2 (id TEXT PRIMARY KEY);
    
    -- version: 1
    ALTER TABLE table1 ADD COLUMN field1 TEXT;
    ALTER TABLE table2 ADD COLUMN field2 TEXT;
    """
    sql_file = tmp_path / "multiple_tables.sql"
    sql_file.write_text(sql)
    
    migrations = parse_sql_schema(sql_file)
    assert 1 in migrations
    version1_changes = {f"{c['table']}.{c['column']}" for c in migrations[1]}
    assert "table1.field1" in version1_changes
    assert "table2.field2" in version1_changes 