# Record Thing Database Management Plan

This document outlines the plan for managing the Record Thing SQLite database, including incremental updates, database regeneration, and translation management.

## 1. Current Database Creation Process

The `libs/record_thing/record-thing.sqlite` database is created through a multi-step process:

1. **Database Initialization**
   - The `init-db` command in `cli.py` creates a new database
   - `db_setup.py` coordinates the creation by calling:
     - `init_db_tables()` from `schema.py` to create tables
     - `insert_sample_data()` to populate tables with test data

2. **Table Creation Order**
   - Tables are created in dependency order:
     1. Account tables (account.sql)
     2. Category tables (categories.sql)
     3. Product tables (product.sql)
     4. Evidence tables (evidence.sql)
     5. Asset tables (assets.sql)
     6. Translation tables (translations.sql)

3. **Data Generation**
   - Sample data is inserted by `operations.py`
   - Includes default records for all tables (accounts, universes, products, etc.)
   - Translations are populated from `DEFAULT_TRANSLATIONS` in `test_data.py`

## 2. Database Management Plan

### A. Incremental Updates

Create a new module `db_updater.py` with these key functions:

```python
# 1. Schema Updates
def add_table(table_name, schema_definition, db_path=None):
    """Add a new table to the database."""
    
def add_column(table_name, column_definition, db_path=None):
    """Add a new column to an existing table."""
    
def modify_column(table_name, column_name, new_definition, db_path=None):
    """Modify column definition if possible (with data preservation)."""

# 2. Data Updates
def add_records(table_name, records, db_path=None):
    """Add new records to a table, skipping existing ones."""
    
def update_records(table_name, condition, updates, db_path=None):
    """Update existing records that match condition."""
    
def delete_records(table_name, condition, db_path=None):
    """Delete records that match a condition."""

# 3. Validation Functions
def validate_table_structure(table_name, expected_schema, db_path=None):
    """Validate table structure against expected schema."""
    
def validate_data_integrity(validation_rules, db_path=None):
    """Run custom validation rules on data."""
```

### B. Database Regeneration

Implement a `regenerate_db.py` script with these components:

1. **Schema Preservation**
   ```python
   def extract_schema(db_path):
       """Extract current schema to SQL statements."""
   ```

2. **Data Preservation**
   ```python
   def export_tables_data(db_path, tables=None):
       """Export data from tables to JSON format."""
   ```

3. **Full Regeneration**
   ```python
   def regenerate_database(db_path, schema_only=False):
       """Regenerate database from scratch with schema preservation."""
   ```

4. **Selective Regeneration**
   ```python
   def regenerate_tables(db_path, tables):
       """Regenerate specific tables while preserving others."""
   ```

### C. Testing & Validation

Add a validation system in `db_validator.py`:

```python
def run_schema_validation(db_path):
    """Validate database schema against expected structure."""
    
def run_data_validation(db_path):
    """Validate data consistency and referential integrity."""
    
def compare_databases(source_db, target_db):
    """Compare two databases for schema and data differences."""
```

### D. Migration System

Enhance the existing migration system in `migration_manager.py`:

1. **Version Tracking**
   - Record all schema and data changes with version numbers
   - Implement proper up/down migrations

2. **Automatic Migrations**
   - Execute necessary migrations when updating the database
   - Support selective migrations

3. **Backup System**
   - Create backups before major changes
   - Implement rollback functionality

## 3. Translation Table Management Process

### A. Translation Management Pipeline

1. **Extraction Phase**
   - Use `translation_extractor.py` to scan Swift files for hardcoded strings
   - Generate translation keys following the established pattern (category.item)
   - Output suggestions to a JSON file for review

2. **Review & Approval Phase**
   - Review extracted strings in JSON format
   - Approve/modify keys and values before adding to database
   - Validate context categorization

3. **Update Phase**
   - Add approved translations to `update_translations.py`
   - Run the script to update the database
   - Copy updated database to app resources

4. **Testing Phase**
   - Build the app to test translations
   - Verify that UI elements display correctly
   - Confirm all contexts are handled properly

### B. Translation Management Improvements

1. **Consolidated Translation Management**

```python
class TranslationManager:
    """Manage translations in the database."""
    
    def __init__(self, db_path=None):
        self.db_path = db_path or "record-thing.sqlite"
        
    def add_translation(self, lang, key, value, context):
        """Add a new translation or update existing one."""
        
    def add_translations_batch(self, translations):
        """Add multiple translations at once."""
        
    def get_translations(self, lang=None, context=None):
        """Get translations filtered by language and/or context."""
        
    def export_translations(self, output_path, lang=None, context=None):
        """Export translations to JSON or PO file."""
        
    def import_translations(self, input_path, lang=None, overwrite=False):
        """Import translations from JSON or PO file."""
        
    def scan_code(self, source_dir, debug_only=False):
        """Scan code for hardcoded strings and suggest translations."""
        
    def generate_swift_keys(self, output_path):
        """Generate Swift code with translation key constants."""
```

2. **Multilingual Support Extensions**

```python
def add_language(db_path, lang_code, base_lang='en'):
    """Add support for a new language by copying base language structure."""
    
def translate_using_service(db_path, source_lang, target_lang, service='google'):
    """Use translation service to translate strings to target language."""
    
def export_language_file(db_path, lang, format='strings'):
    """Export translations for a language in specific format."""
```

3. **Workflow Automation**

Add a new script `translation_workflow.py` that combines all steps:
- Scan codebase for hardcoded strings
- Review and process suggestions
- Update database with new translations
- Generate Swift translation keys
- Export language files for localization

## 4. Implementation Plan

### Phase 1: Core Management Framework
1. Create the `db_updater.py` module with incremental update functions
2. Enhance the migration system in `migration_manager.py`
3. Implement basic validation in `db_validator.py`

### Phase 2: Translation Management
1. Consolidate the translation scripts into a cohesive system
2. Implement the `TranslationManager` class
3. Add multilingual support and workflow automation

### Phase 3: Regeneration System
1. Implement the database schema and data preservation
2. Create the regeneration functionality with testing
3. Integrate with the updater and migration systems

### Phase 4: Validation & Testing
1. Add comprehensive validation rules
2. Create integration tests for the entire system
3. Document the complete process for team usage

## 5. Database Regeneration Verification

To verify that the database regeneration works correctly, we'll implement these functions:

```python
def extract_schema_from_existing_db(db_path):
    """Extract complete schema from the existing database."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Get all table definitions
    cursor.execute("SELECT name, sql FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    
    schema = {}
    for table_name, create_sql in tables:
        schema[table_name] = create_sql
        
        # Get indexes for this table
        cursor.execute(f"SELECT name, sql FROM sqlite_master WHERE type='index' AND tbl_name='{table_name}'")
        indexes = cursor.fetchall()
        schema[f"{table_name}_indexes"] = indexes
    
    conn.close()
    return schema

def extract_data_samples(db_path, sample_size=100):
    """Extract representative data samples from each table."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Get all tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [row[0] for row in cursor.fetchall()]
    
    data_samples = {}
    for table in tables:
        # Skip sqlite internal tables
        if table.startswith('sqlite_'):
            continue
            
        # Get column names
        cursor.execute(f"PRAGMA table_info({table})")
        columns = [row[1] for row in cursor.fetchall()]
        
        # Get sample data
        cursor.execute(f"SELECT * FROM {table} LIMIT {sample_size}")
        rows = cursor.fetchall()
        
        data_samples[table] = {
            'columns': columns,
            'rows': rows
        }
    
    conn.close()
    return data_samples

def verify_regeneration(existing_db_path, temp_dir=None):
    """Generate a new database and compare with existing one."""
    import tempfile
    import os
    
    # Create temporary directory if not provided
    if temp_dir is None:
        temp_dir = tempfile.mkdtemp()
    
    # Path for the regenerated database
    new_db_path = os.path.join(temp_dir, "regenerated.sqlite")
    
    # Step 1: Extract schema and sample data from existing DB
    original_schema = extract_schema_from_existing_db(existing_db_path)
    original_samples = extract_data_samples(existing_db_path)
    
    # Step 2: Regenerate the database from scratch
    regenerate_database(new_db_path)
    
    # Step 3: Extract schema and sample data from new DB
    new_schema = extract_schema_from_existing_db(new_db_path)
    new_samples = extract_data_samples(new_db_path)
    
    # Step 4: Compare schemas
    schema_diffs = compare_schemas(original_schema, new_schema)
    
    # Step 5: Compare data structures and patterns
    data_diffs = compare_data_structures(original_samples, new_samples)
    
    # Step 6: Generate verification report
    report = {
        'schema_differences': schema_diffs,
        'data_structure_differences': data_diffs,
        'verification_passed': len(schema_diffs) == 0 and len(data_diffs) == 0
    }
    
    return report
```

### Additional Verification Strategies

1. **Record Count Verification**
   - Verify that tables have similar record counts
   
2. **Foreign Key Constraint Verification**
   - Verify that foreign key constraints are satisfied

3. **Data Distribution Verification**
   - Verify that data has similar statistical distribution

4. **Performance Benchmark**
   - Benchmark the regeneration process and resulting database performance

## 6. Improvement Areas & Open Points

### Prioritization
- Identify which components provide the most immediate value
- Establish criteria for prioritizing updates

### Performance Considerations
- Consider optimization strategies for large datasets
- Add benchmarking for database operations
- Identify and optimize bottlenecks

### Error Handling & Recovery
- Enhance error handling with specific error types
- Implement transaction management for atomic operations
- Create recovery procedures for failed operations

### Documentation & Standards
- Establish naming conventions and coding standards
- Create usage examples for common operations
- Add user documentation for database management tools

### Open Questions
1. Should we migrate to a more formal migration framework like Alembic?
2. How should we handle schema conflicts between different app versions?
3. What level of data validation is appropriate for the app?
4. How can we best manage translations across multiple languages?
5. Should we implement a continuous integration testing strategy for database changes?

## 7. Next Steps

1. Review and approve this plan
2. Implement the highest priority components
3. Create test cases for database operations
4. Develop documentation for the implemented components
5. Integrate with existing codebase
6. Deploy and monitor in production