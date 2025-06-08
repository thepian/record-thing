#!/usr/bin/env python3
"""
Schema Validation Tool for RecordThing
Validates consistency between SQL schema files and Swift Blackbird models
"""

import re
import sqlite3
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from enum import Enum
import json
import logging

logger = logging.getLogger(__name__)


class ValidationSeverity(Enum):
    ERROR = "ERROR"
    WARNING = "WARNING"
    INFO = "INFO"


@dataclass
class ValidationIssue:
    severity: ValidationSeverity
    category: str
    table: str
    column: Optional[str]
    message: str
    sql_definition: Optional[str] = None
    swift_definition: Optional[str] = None
    recommendation: Optional[str] = None


@dataclass
class TableSchema:
    name: str
    columns: Dict[str, 'ColumnSchema']
    primary_key: List[str]
    indexes: List[List[str]]
    unique_indexes: List[List[str]]


@dataclass
class ColumnSchema:
    name: str
    sql_type: str
    swift_type: Optional[str]
    nullable: bool
    default_value: Optional[str]
    constraints: List[str]


class SQLSchemaParser:
    """Parse SQL files to extract schema information"""
    
    def __init__(self, sql_dir: Path):
        self.sql_dir = sql_dir
        
    def parse_all_sql_files(self) -> Dict[str, TableSchema]:
        """Parse all SQL files and return complete schema"""
        tables = {}
        
        sql_files = [
            "account.sql",
            "categories.sql", 
            "evidence.sql",
            "assets.sql",
            "translations.sql",
            "product.sql"
        ]
        
        for sql_file in sql_files:
            file_path = self.sql_dir / sql_file
            if file_path.exists():
                file_tables = self.parse_sql_file(file_path)
                tables.update(file_tables)
                
        return tables
    
    def parse_sql_file(self, sql_file: Path) -> Dict[str, TableSchema]:
        """Parse a single SQL file"""
        tables = {}
        
        with open(sql_file, 'r') as f:
            content = f.read()
            
        # Find all CREATE TABLE statements
        create_table_pattern = r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([`"]?)(\w+)\1\s*\((.*?)\);'
        
        for match in re.finditer(create_table_pattern, content, re.IGNORECASE | re.DOTALL):
            table_name = match.group(2)
            table_definition = match.group(3)
            
            table_schema = self.parse_table_definition(table_name, table_definition)
            tables[table_name] = table_schema
            
        return tables
    
    def parse_table_definition(self, table_name: str, definition: str) -> TableSchema:
        """Parse table definition to extract columns and constraints"""
        columns = {}
        primary_key = []
        
        # Split by commas, but be careful with nested parentheses
        column_definitions = self.split_column_definitions(definition)
        
        for col_def in column_definitions:
            col_def = col_def.strip()
            
            if col_def.upper().startswith('PRIMARY KEY'):
                # Extract primary key columns
                pk_match = re.search(r'PRIMARY\s+KEY\s*\((.*?)\)', col_def, re.IGNORECASE)
                if pk_match:
                    pk_columns = [c.strip().strip('`"') for c in pk_match.group(1).split(',')]
                    primary_key.extend(pk_columns)
                continue
                
            # Parse column definition
            column = self.parse_column_definition(col_def)
            if column:
                columns[column.name] = column
                
        return TableSchema(
            name=table_name,
            columns=columns,
            primary_key=primary_key,
            indexes=[],
            unique_indexes=[]
        )
    
    def split_column_definitions(self, definition: str) -> List[str]:
        """Split column definitions by comma, respecting parentheses"""
        definitions = []
        current = ""
        paren_depth = 0
        
        for char in definition:
            if char == '(':
                paren_depth += 1
            elif char == ')':
                paren_depth -= 1
            elif char == ',' and paren_depth == 0:
                definitions.append(current.strip())
                current = ""
                continue
                
            current += char
            
        if current.strip():
            definitions.append(current.strip())
            
        return definitions
    
    def parse_column_definition(self, col_def: str) -> Optional[ColumnSchema]:
        """Parse individual column definition"""
        # Match: column_name TYPE [constraints...]
        match = re.match(r'([`"]?)(\w+)\1\s+([\w\(\)]+)(?:\s+(.*))?', col_def.strip())
        
        if not match:
            return None
            
        column_name = match.group(2)
        sql_type = match.group(3)
        constraints_str = match.group(4) or ""
        
        # Parse constraints
        nullable = True
        default_value = None
        constraints = []
        
        if 'NOT NULL' in constraints_str.upper():
            nullable = False
            constraints.append('NOT NULL')
            
        if 'PRIMARY KEY' in constraints_str.upper():
            constraints.append('PRIMARY KEY')
            
        # Extract default value
        default_match = re.search(r'DEFAULT\s+([^,\s]+)', constraints_str, re.IGNORECASE)
        if default_match:
            default_value = default_match.group(1)
            
        return ColumnSchema(
            name=column_name,
            sql_type=sql_type,
            swift_type=None,  # Will be filled by Swift parser
            nullable=nullable,
            default_value=default_value,
            constraints=constraints
        )


class SwiftModelParser:
    """Parse Swift Blackbird models to extract schema information"""
    
    def __init__(self, swift_dir: Path):
        self.swift_dir = swift_dir
        
    def parse_all_swift_models(self) -> Dict[str, TableSchema]:
        """Parse all Swift model files"""
        tables = {}
        
        # Find all Swift files in the model directory
        for swift_file in self.swift_dir.rglob("*.swift"):
            if "Model" in str(swift_file):
                file_tables = self.parse_swift_file(swift_file)
                tables.update(file_tables)
                
        return tables
    
    def parse_swift_file(self, swift_file: Path) -> Dict[str, TableSchema]:
        """Parse a single Swift file for Blackbird models"""
        tables = {}
        
        with open(swift_file, 'r') as f:
            content = f.read()
            
        # Find struct definitions that implement BlackbirdModel
        struct_pattern = r'struct\s+(\w+):\s*[^{]*BlackbirdModel[^{]*\{(.*?)\n\}'
        
        for match in re.finditer(struct_pattern, content, re.DOTALL):
            struct_name = match.group(1)
            struct_body = match.group(2)
            
            table_schema = self.parse_struct_body(struct_name, struct_body)
            if table_schema:
                tables[table_schema.name] = table_schema
                
        return tables
    
    def parse_struct_body(self, struct_name: str, body: str) -> Optional[TableSchema]:
        """Parse Swift struct body to extract table schema"""
        columns = {}
        primary_key = []
        table_name = struct_name.lower()
        
        # Extract table name if specified
        table_name_match = re.search(r'static.*var\s+tableName.*=\s*"(\w+)"', body)
        if table_name_match:
            table_name = table_name_match.group(1)
            
        # Extract primary key
        pk_match = re.search(r'static.*var\s+primaryKey.*=\s*\[(.*?)\]', body, re.DOTALL)
        if pk_match:
            pk_content = pk_match.group(1)
            # Extract column references like \.$id, \.$account_id
            pk_columns = re.findall(r'\\\.\$(\w+)', pk_content)
            primary_key = pk_columns
            
        # Extract columns
        column_pattern = r'@BlackbirdColumn\s+(?:public\s+)?var\s+(\w+):\s*([^=\n]+?)(?:\s*=.*?)?(?:\n|$)'
        
        for match in re.finditer(column_pattern, body):
            column_name = match.group(1)
            swift_type = match.group(2).strip()
            
            # Convert Swift type to SQL equivalent
            sql_type = self.swift_type_to_sql(swift_type)
            nullable = '?' in swift_type
            
            columns[column_name] = ColumnSchema(
                name=column_name,
                sql_type=sql_type,
                swift_type=swift_type,
                nullable=nullable,
                default_value=None,
                constraints=[]
            )
            
        return TableSchema(
            name=table_name,
            columns=columns,
            primary_key=primary_key,
            indexes=[],
            unique_indexes=[]
        )
    
    def swift_type_to_sql(self, swift_type: str) -> str:
        """Convert Swift type to equivalent SQL type"""
        # Remove optional marker
        base_type = swift_type.replace('?', '').strip()
        
        type_mapping = {
            'String': 'TEXT',
            'Int': 'INTEGER',
            'Bool': 'BOOLEAN',
            'Date': 'FLOAT',  # RecordThing uses FLOAT for timestamps
            'Data': 'BLOB',
            'URL': 'TEXT'
        }
        
        return type_mapping.get(base_type, 'TEXT')


class SchemaValidator:
    """Main schema validation class"""
    
    def __init__(self, sql_dir: Path, swift_dir: Path):
        self.sql_parser = SQLSchemaParser(sql_dir)
        self.swift_parser = SwiftModelParser(swift_dir)
        self.issues: List[ValidationIssue] = []
        
    def validate_all(self) -> List[ValidationIssue]:
        """Run all validation checks"""
        self.issues = []
        
        # Parse schemas
        sql_tables = self.sql_parser.parse_all_sql_files()
        swift_tables = self.swift_parser.parse_all_swift_models()
        
        # Run validation checks
        self.check_missing_swift_models(sql_tables, swift_tables)
        self.check_missing_sql_tables(sql_tables, swift_tables)
        self.check_table_consistency(sql_tables, swift_tables)
        
        return self.issues
    
    def check_missing_swift_models(self, sql_tables: Dict[str, TableSchema], swift_tables: Dict[str, TableSchema]):
        """Check for SQL tables without corresponding Swift models"""
        for table_name in sql_tables:
            if table_name not in swift_tables:
                self.issues.append(ValidationIssue(
                    severity=ValidationSeverity.WARNING,
                    category="Missing Swift Model",
                    table=table_name,
                    column=None,
                    message=f"SQL table '{table_name}' has no corresponding Swift Blackbird model",
                    recommendation=f"Create {table_name.capitalize()}.swift model or add to existing model file"
                ))
    
    def check_missing_sql_tables(self, sql_tables: Dict[str, TableSchema], swift_tables: Dict[str, TableSchema]):
        """Check for Swift models without corresponding SQL tables"""
        for table_name in swift_tables:
            if table_name not in sql_tables:
                self.issues.append(ValidationIssue(
                    severity=ValidationSeverity.ERROR,
                    category="Missing SQL Table",
                    table=table_name,
                    column=None,
                    message=f"Swift model '{table_name}' has no corresponding SQL table definition",
                    recommendation=f"Add CREATE TABLE statement for '{table_name}' to appropriate SQL file"
                ))
    
    def check_table_consistency(self, sql_tables: Dict[str, TableSchema], swift_tables: Dict[str, TableSchema]):
        """Check consistency between SQL tables and Swift models"""
        common_tables = set(sql_tables.keys()) & set(swift_tables.keys())
        
        for table_name in common_tables:
            sql_table = sql_tables[table_name]
            swift_table = swift_tables[table_name]
            
            self.check_primary_key_consistency(sql_table, swift_table)
            self.check_column_consistency(sql_table, swift_table)
    
    def check_primary_key_consistency(self, sql_table: TableSchema, swift_table: TableSchema):
        """Check primary key consistency"""
        if set(sql_table.primary_key) != set(swift_table.primary_key):
            self.issues.append(ValidationIssue(
                severity=ValidationSeverity.ERROR,
                category="Primary Key Mismatch",
                table=sql_table.name,
                column=None,
                message=f"Primary key mismatch in table '{sql_table.name}'",
                sql_definition=f"SQL: {sql_table.primary_key}",
                swift_definition=f"Swift: {swift_table.primary_key}",
                recommendation="Update Swift primaryKey to match SQL PRIMARY KEY constraint"
            ))
    
    def check_column_consistency(self, sql_table: TableSchema, swift_table: TableSchema):
        """Check column consistency between SQL and Swift"""
        # Check for missing columns in Swift
        for col_name, sql_col in sql_table.columns.items():
            if col_name not in swift_table.columns:
                self.issues.append(ValidationIssue(
                    severity=ValidationSeverity.WARNING,
                    category="Missing Swift Column",
                    table=sql_table.name,
                    column=col_name,
                    message=f"SQL column '{col_name}' missing in Swift model",
                    sql_definition=f"{sql_col.sql_type} {'NULL' if sql_col.nullable else 'NOT NULL'}",
                    recommendation=f"Add @BlackbirdColumn var {col_name}: {self.sql_type_to_swift(sql_col.sql_type, sql_col.nullable)}"
                ))
        
        # Check for extra columns in Swift
        for col_name, swift_col in swift_table.columns.items():
            if col_name not in sql_table.columns:
                self.issues.append(ValidationIssue(
                    severity=ValidationSeverity.WARNING,
                    category="Extra Swift Column",
                    table=sql_table.name,
                    column=col_name,
                    message=f"Swift column '{col_name}' not found in SQL table",
                    swift_definition=swift_col.swift_type,
                    recommendation=f"Add column to SQL: {col_name} {swift_col.sql_type}"
                ))
        
        # Check type consistency for common columns
        common_columns = set(sql_table.columns.keys()) & set(swift_table.columns.keys())
        for col_name in common_columns:
            sql_col = sql_table.columns[col_name]
            swift_col = swift_table.columns[col_name]
            
            if not self.types_compatible(sql_col.sql_type, swift_col.swift_type):
                self.issues.append(ValidationIssue(
                    severity=ValidationSeverity.ERROR,
                    category="Type Mismatch",
                    table=sql_table.name,
                    column=col_name,
                    message=f"Type mismatch for column '{col_name}'",
                    sql_definition=f"SQL: {sql_col.sql_type}",
                    swift_definition=f"Swift: {swift_col.swift_type}",
                    recommendation=self.get_type_fix_recommendation(sql_col.sql_type, swift_col.swift_type)
                ))
    
    def types_compatible(self, sql_type: str, swift_type: str) -> bool:
        """Check if SQL and Swift types are compatible"""
        # Remove optional marker from Swift type
        base_swift_type = swift_type.replace('?', '').strip()
        
        compatible_mappings = {
            'TEXT': ['String'],
            'INTEGER': ['Int', 'String'],  # RecordThing sometimes uses String for INTEGER IDs
            'BOOLEAN': ['Bool'],
            'FLOAT': ['Date', 'Double', 'Float'],
            'BLOB': ['Data']
        }
        
        sql_type_upper = sql_type.upper()
        for sql_pattern, swift_types in compatible_mappings.items():
            if sql_pattern in sql_type_upper and base_swift_type in swift_types:
                return True
                
        return False
    
    def sql_type_to_swift(self, sql_type: str, nullable: bool) -> str:
        """Convert SQL type to Swift type"""
        type_mapping = {
            'TEXT': 'String',
            'INTEGER': 'Int',
            'BOOLEAN': 'Bool',
            'FLOAT': 'Date',
            'BLOB': 'Data'
        }
        
        sql_type_upper = sql_type.upper()
        swift_type = 'String'  # Default
        
        for sql_pattern, swift_t in type_mapping.items():
            if sql_pattern in sql_type_upper:
                swift_type = swift_t
                break
                
        return f"{swift_type}?" if nullable else swift_type
    
    def get_type_fix_recommendation(self, sql_type: str, swift_type: str) -> str:
        """Get recommendation for fixing type mismatch"""
        recommended_swift = self.sql_type_to_swift(sql_type, '?' in swift_type)
        return f"Change Swift type to: {recommended_swift}"
    
    def print_report(self):
        """Print validation report to console"""
        if not self.issues:
            print("✅ Schema validation passed - no issues found!")
            return
            
        print(f"\n📋 Schema Validation Report")
        print("=" * 50)
        
        # Group by severity
        errors = [i for i in self.issues if i.severity == ValidationSeverity.ERROR]
        warnings = [i for i in self.issues if i.severity == ValidationSeverity.WARNING]
        
        if errors:
            print(f"\n❌ ERRORS ({len(errors)}):")
            for issue in errors:
                self.print_issue(issue)
                
        if warnings:
            print(f"\n⚠️  WARNINGS ({len(warnings)}):")
            for issue in warnings:
                self.print_issue(issue)
                
        print(f"\nSummary: {len(errors)} errors, {len(warnings)} warnings")
        
    def print_issue(self, issue: ValidationIssue):
        """Print individual issue"""
        location = f"{issue.table}"
        if issue.column:
            location += f".{issue.column}"
            
        print(f"  {location}: {issue.message}")
        
        if issue.sql_definition:
            print(f"    {issue.sql_definition}")
        if issue.swift_definition:
            print(f"    {issue.swift_definition}")
        if issue.recommendation:
            print(f"    💡 {issue.recommendation}")
        print()


def main():
    """Main CLI entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Validate RecordThing database schema consistency")
    parser.add_argument("--sql-dir", type=Path, default=Path(__file__).parent, help="SQL files directory")
    parser.add_argument("--swift-dir", type=Path, default=Path(__file__).parent.parent.parent.parent / "apps" / "libs" / "RecordLib" / "Sources" / "RecordLib", help="Swift models directory")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--strict", action="store_true", help="Exit with error code if issues found")
    
    args = parser.parse_args()
    
    validator = SchemaValidator(args.sql_dir, args.swift_dir)
    issues = validator.validate_all()
    
    if args.json:
        # Output as JSON for CI/CD integration
        json_output = {
            "issues": [
                {
                    "severity": issue.severity.value,
                    "category": issue.category,
                    "table": issue.table,
                    "column": issue.column,
                    "message": issue.message,
                    "sql_definition": issue.sql_definition,
                    "swift_definition": issue.swift_definition,
                    "recommendation": issue.recommendation
                }
                for issue in issues
            ],
            "summary": {
                "total": len(issues),
                "errors": len([i for i in issues if i.severity == ValidationSeverity.ERROR]),
                "warnings": len([i for i in issues if i.severity == ValidationSeverity.WARNING])
            }
        }
        print(json.dumps(json_output, indent=2))
    else:
        validator.print_report()
    
    # Exit with error code if strict mode and issues found
    if args.strict and issues:
        exit(1)


if __name__ == "__main__":
    main()
