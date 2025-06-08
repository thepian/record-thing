#!/usr/bin/env python3
"""
Test script to demonstrate schema validation for RecordThing
"""

import sys
from pathlib import Path

# Add the project root to Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from libs.record_thing.db.schema_validator import SchemaValidator, ValidationSeverity


def main():
    """Test the schema validator with current RecordThing files"""
    
    # Define paths
    sql_dir = project_root / "libs" / "record_thing" / "db"
    swift_dir = project_root / "apps" / "libs" / "RecordLib" / "Sources" / "RecordLib"
    
    print("🔍 RecordThing Schema Validation Test")
    print("=" * 50)
    print(f"SQL Directory: {sql_dir}")
    print(f"Swift Directory: {swift_dir}")
    print()
    
    # Check if directories exist
    if not sql_dir.exists():
        print(f"❌ SQL directory not found: {sql_dir}")
        return 1
        
    if not swift_dir.exists():
        print(f"❌ Swift directory not found: {swift_dir}")
        return 1
    
    # Run validation
    print("🚀 Running schema validation...")
    validator = SchemaValidator(sql_dir, swift_dir)
    issues = validator.validate_all()
    
    # Print results
    validator.print_report()
    
    # Additional analysis
    print("\n📊 Detailed Analysis")
    print("-" * 30)
    
    # Count issues by category
    categories = {}
    for issue in issues:
        categories[issue.category] = categories.get(issue.category, 0) + 1
    
    if categories:
        print("Issues by category:")
        for category, count in sorted(categories.items()):
            print(f"  {category}: {count}")
    
    # Count issues by table
    tables = {}
    for issue in issues:
        tables[issue.table] = tables.get(issue.table, 0) + 1
    
    if tables:
        print("\nIssues by table:")
        for table, count in sorted(tables.items()):
            print(f"  {table}: {count}")
    
    # Show most critical issues
    errors = [i for i in issues if i.severity == ValidationSeverity.ERROR]
    if errors:
        print(f"\n🚨 Critical Issues Requiring Immediate Attention ({len(errors)}):")
        for i, error in enumerate(errors[:5], 1):  # Show top 5
            location = f"{error.table}"
            if error.column:
                location += f".{error.column}"
            print(f"  {i}. {location}: {error.message}")
            if error.recommendation:
                print(f"     💡 {error.recommendation}")
    
    # Provide next steps
    print(f"\n🎯 Next Steps")
    print("-" * 20)
    
    if not issues:
        print("✅ Schema is consistent! No action needed.")
    else:
        error_count = len([i for i in issues if i.severity == ValidationSeverity.ERROR])
        warning_count = len([i for i in issues if i.severity == ValidationSeverity.WARNING])
        
        if error_count > 0:
            print(f"1. Fix {error_count} critical errors first")
            print("2. These may cause runtime issues or compilation failures")
        
        if warning_count > 0:
            print(f"3. Address {warning_count} warnings for completeness")
            print("4. These indicate missing features or inconsistencies")
        
        print("5. Re-run validation after fixes")
        print("6. Consider adding to CI/CD pipeline")
    
    # Example commands
    print(f"\n🛠️  Example Commands")
    print("-" * 25)
    print("# Run validation manually:")
    print(f"python {__file__}")
    print()
    print("# Run with JSON output for CI/CD:")
    print(f"python libs/record_thing/db/schema_validator.py --json")
    print()
    print("# Run in strict mode (exit code 1 if issues):")
    print(f"python libs/record_thing/db/schema_validator.py --strict")
    
    return 1 if issues else 0


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
