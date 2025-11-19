#!/usr/bin/env python3
"""
Translation Validator for Record Thing

This tool validates translations by comparing keys found in source code with entries
in the database, identifying issues, and providing detailed reference information.
"""

import argparse
import json
import os
import re
import sqlite3
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Set, Optional, Any, Tuple


class TranslationIssue:
    """Represents a translation issue with reference information."""
    
    def __init__(self, issue_type: str, key: str, details: str, references: List[Dict] = None):
        self.issue_type = issue_type  # Type of issue (missing, unused, etc.)
        self.key = key                # The translation key
        self.details = details        # Description of the issue
        self.references = references or []  # List of file/line references
        self.severity = self._determine_severity()
        
    def _determine_severity(self) -> str:
        """Determine issue severity based on type and context."""
        if self.issue_type == "missing":
            return "high"
        elif self.issue_type == "unused":
            return "medium"
        elif self.issue_type == "format_mismatch":
            return "high"
        elif self.issue_type == "key_violation":
            return "low"
        elif self.issue_type == "empty":
            return "medium"
        elif self.issue_type == "similar":
            return "low"
        else:
            return "medium"
        
    def to_dict(self) -> Dict:
        """Convert issue to dictionary for serialization."""
        return {
            "type": self.issue_type,
            "key": self.key,
            "details": self.details,
            "severity": self.severity,
            "references": self.references
        }


class TranslationValidator:
    """Validates translations between source code and database."""
    
    def __init__(self, db_path: Optional[str] = None):
        """Initialize the validator with optional database path."""
        self.db_path = db_path or "record-thing.sqlite"
        self.source_keys: Dict[str, List[Dict]] = {}  # {key: [{"file": file_path, "line": line_no}]}
        self.db_keys: Dict[str, Dict] = {}      # {key: {"value": value, "context": context}}
        self.issues: List[TranslationIssue] = []
        
        # String patterns to identify translation keys in code
        self.key_patterns = [
            # Direct key usage with .translated
            r'[\'"]([a-zA-Z0-9_.]+)[\'"]\.translated',
            
            # Text with translated initializer
            r'Text\s*\(\s*translated:\s*"([^"]+)"\s*\)',
            
            # Translation key constants
            r'public\s+static\s+let\s+\w+\s*=\s*"([a-zA-Z0-9_.]+)"',
            
            # LocalizedStringKey usage
            r'LocalizedStringKey\s*\(\s*stringLiteral:\s*"([^"]+)"\s*\)',
        ]
        
        # Filter for development-only files
        self.development_markers = [
            "// @DEVELOPMENT_ONLY",
            "#if DEBUG"
        ]
        
    def scan_source_code(self, source_dir: str) -> None:
        """Scan source code to extract all translation keys with locations."""
        print(f"Scanning source code in {source_dir}...")
        
        self.source_keys = {}
        files_scanned = 0
        keys_found = 0
        
        for root, _, files in os.walk(source_dir):
            for file in files:
                if not file.endswith(".swift"):
                    continue
                    
                file_path = os.path.join(root, file)
                files_scanned += 1
                
                # Skip development-only files
                if self._is_development_file(file_path):
                    continue
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        for line_no, line in enumerate(f, 1):
                            # Look for translation keys using different patterns
                            for pattern in self.key_patterns:
                                matches = re.finditer(pattern, line)
                                for match in matches:
                                    key = match.group(1)
                                    
                                    # Skip if not a valid translation key format
                                    if not self._is_translation_key(key):
                                        continue
                                        
                                    reference = {
                                        "file": file_path, 
                                        "line": line_no, 
                                        "column": match.start(1),
                                        "context": line.strip()
                                    }
                                    
                                    if key not in self.source_keys:
                                        self.source_keys[key] = []
                                    self.source_keys[key].append(reference)
                                    keys_found += 1
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")
        
        print(f"Scanned {files_scanned} files, found {keys_found} translation key references for {len(self.source_keys)} unique keys")
    
    def _is_development_file(self, file_path: str) -> bool:
        """Check if a file is development-only based on markers."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read(2000)  # Read just the first part to check for markers
                for marker in self.development_markers:
                    if marker in content:
                        return True
            return False
        except Exception:
            return False
    
    def _is_translation_key(self, key: str) -> bool:
        """Check if string appears to be a translation key."""
        # Translation keys typically follow a pattern like "category.item"
        return "." in key and len(key.split(".")[0]) > 0
    
    def load_database_keys(self) -> None:
        """Load all translation keys from the database."""
        print(f"Loading translation keys from database: {self.db_path}")
        
        if not os.path.exists(self.db_path):
            print(f"Error: Database file not found: {self.db_path}")
            return
        
        self.db_keys = {}
        
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            # Check if translations table exists
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='translations'")
            if not cursor.fetchone():
                print("Error: Translations table not found in database")
                conn.close()
                return
            
            # Get all translations for English language
            cursor.execute("SELECT key, value, context FROM translations WHERE lang = 'en'")
            rows = cursor.fetchall()
            
            for row in rows:
                self.db_keys[row['key']] = {
                    "value": row['value'],
                    "context": row['context']
                }
            
            conn.close()
            print(f"Loaded {len(self.db_keys)} translation keys from database")
            
        except Exception as e:
            print(f"Error loading database keys: {e}")
    
    def validate(self) -> None:
        """Run all validation checks and collect issues."""
        print("Running validation checks...")
        self.issues = []
        
        # Run all validation checks
        self._check_missing_translations()
        self._check_unused_translations()
        self._check_format_mismatches()
        self._check_naming_violations()
        self._check_similar_keys()
        self._check_empty_translations()
        
        # Sort issues by severity
        self.issues.sort(key=lambda x: {
            "high": 0,
            "medium": 1,
            "low": 2
        }.get(x.severity, 3))
        
        print(f"Found {len(self.issues)} issues")
    
    def _check_missing_translations(self) -> None:
        """Find keys used in code but missing from database."""
        for key, references in self.source_keys.items():
            if key not in self.db_keys:
                issue = TranslationIssue(
                    issue_type="missing",
                    key=key,
                    details=f"Translation key used in code but missing from database",
                    references=references
                )
                self.issues.append(issue)
    
    def _check_unused_translations(self) -> None:
        """Find keys in database but not used in code."""
        for key, data in self.db_keys.items():
            if key not in self.source_keys:
                issue = TranslationIssue(
                    issue_type="unused",
                    key=key,
                    details=f"Translation key exists in database but not found in code",
                    references=[{"value": data["value"], "context": data["context"]}]
                )
                self.issues.append(issue)
    
    def _check_format_mismatches(self) -> None:
        """Check for format specifier mismatches."""
        for key, references in self.source_keys.items():
            if key in self.db_keys:
                value = self.db_keys[key]["value"]
                
                # Extract format specifiers from value
                value_formats = re.findall(r'%[sdiouxXeEfFgGaAcsp]', value)
                
                # Check if any references use string formatting
                for ref in references:
                    if "context" in ref and "String(format:" in ref["context"]:
                        # This is a formatted string, check for potential issues
                        if not value_formats:
                            issue = TranslationIssue(
                                issue_type="format_mismatch",
                                key=key,
                                details=f"String formatting used in code but no format specifiers in translation",
                                references=[ref]
                            )
                            self.issues.append(issue)
    
    def _check_naming_violations(self) -> None:
        """Check for keys that don't follow naming conventions."""
        # Naming convention: lowercase with dots (e.g., "category.subcategory.name")
        naming_pattern = re.compile(r'^[a-z]+\.[a-z0-9_.]+$')
        
        for key in self.source_keys:
            if not naming_pattern.match(key):
                issue = TranslationIssue(
                    issue_type="key_violation",
                    key=key,
                    details=f"Translation key doesn't follow naming convention (lowercase with dots)",
                    references=self.source_keys[key]
                )
                self.issues.append(issue)
    
    def _check_similar_keys(self) -> None:
        """Find keys that are very similar and might be duplicates."""
        # Group keys by their first component
        key_groups = {}
        for key in self.db_keys:
            if "." in key:
                prefix = key.split(".")[0]
                if prefix not in key_groups:
                    key_groups[prefix] = []
                key_groups[prefix].append(key)
        
        # Check for similar keys within each group
        for prefix, keys in key_groups.items():
            if len(keys) <= 1:
                continue
                
            # Group by similar suffixes
            for i, key1 in enumerate(keys):
                suffix1 = key1.split(".", 1)[1] if "." in key1 else key1
                
                for key2 in keys[i+1:]:
                    suffix2 = key2.split(".", 1)[1] if "." in key2 else key2
                    
                    # Check if suffixes are very similar
                    if self._are_similar(suffix1, suffix2):
                        # Check if values are also similar
                        value1 = self.db_keys[key1]["value"]
                        value2 = self.db_keys[key2]["value"]
                        
                        if self._are_similar(value1, value2):
                            references = []
                            if key1 in self.source_keys:
                                references.extend(self.source_keys[key1])
                            if key2 in self.source_keys:
                                references.extend(self.source_keys[key2])
                                
                            issue = TranslationIssue(
                                issue_type="similar",
                                key=f"{key1} and {key2}",
                                details=f"Very similar translation keys with similar values",
                                references=references
                            )
                            self.issues.append(issue)
    
    def _are_similar(self, str1: str, str2: str) -> bool:
        """Check if two strings are very similar."""
        # Simple similarity check: remove spaces and compare
        s1 = str1.lower().replace(" ", "").replace("_", "")
        s2 = str2.lower().replace(" ", "").replace("_", "")
        
        # If one is contained in the other, they're similar
        if s1 in s2 or s2 in s1:
            return True
            
        # Count differences
        if abs(len(s1) - len(s2)) > 3:
            return False
            
        # Levenshtein distance would be better but this is simpler
        differences = 0
        for c1, c2 in zip(s1[:min(len(s1), len(s2))], s2[:min(len(s1), len(s2))]):
            if c1 != c2:
                differences += 1
                
        return differences <= 2
    
    def _check_empty_translations(self) -> None:
        """Check for keys with empty or very short values."""
        for key, data in self.db_keys.items():
            value = data["value"]
            if not value or len(value.strip()) <= 1:
                references = []
                if key in self.source_keys:
                    references = self.source_keys[key]
                
                issue = TranslationIssue(
                    issue_type="empty",
                    key=key,
                    details=f"Translation has empty or very short value: '{value}'",
                    references=references
                )
                self.issues.append(issue)
    
    def filter_issues(self, min_severity: str = "all", issue_types: List[str] = None) -> List[TranslationIssue]:
        """Filter issues by severity and type."""
        filtered = self.issues
        
        # Filter by severity
        if min_severity != "all":
            severity_levels = {
                "high": 0,
                "medium": 1,
                "low": 2
            }
            min_level = severity_levels.get(min_severity, 0)
            filtered = [issue for issue in filtered 
                       if severity_levels.get(issue.severity, 3) <= min_level]
        
        # Filter by issue type
        if issue_types:
            filtered = [issue for issue in filtered 
                       if issue.issue_type in issue_types]
        
        return filtered
    
    def generate_report(self, output_format: str = "text", output_path: Optional[str] = None) -> str:
        """Generate a validation report in the specified format."""
        if output_format == "text":
            report = self._generate_text_report()
        elif output_format == "json":
            report = self._generate_json_report()
        elif output_format == "html":
            report = self._generate_html_report()
        elif output_format == "vscode":
            report = self._generate_vscode_report()
        else:
            raise ValueError(f"Unsupported report format: {output_format}")
        
        if output_path:
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(report)
            print(f"Report saved to {output_path}")
        
        return report
    
    def _generate_text_report(self) -> str:
        """Generate a plain text report of translation issues."""
        lines = [
            "# Translation Validation Report",
            f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"Total issues: {len(self.issues)}",
            "",
        ]
        
        # Group issues by type
        by_type = {}
        for issue in self.issues:
            if issue.issue_type not in by_type:
                by_type[issue.issue_type] = []
            by_type[issue.issue_type].append(issue)
        
        # Generate report sections
        for issue_type, type_issues in by_type.items():
            lines.append(f"## {issue_type.replace('_', ' ').title()} Translations ({len(type_issues)})")
            lines.append("")
            
            for issue in type_issues:
                lines.append(f"- Key: {issue.key}")
                lines.append(f"  Details: {issue.details}")
                lines.append(f"  Severity: {issue.severity}")
                
                if issue.references:
                    lines.append("  References:")
                    for ref in issue.references:
                        if "file" in ref:
                            lines.append(f"    - {ref['file']}:{ref['line']}")
                        else:
                            # For database references
                            ref_details = []
                            if "value" in ref:
                                ref_details.append(f"value='{ref['value']}'")
                            if "context" in ref:
                                ref_details.append(f"context='{ref['context']}'")
                            lines.append(f"    - {', '.join(ref_details)}")
                
                lines.append("")
        
        return "\n".join(lines)
    
    def _generate_json_report(self) -> str:
        """Generate a JSON report of translation issues."""
        report_data = {
            "generated_at": datetime.now().isoformat(),
            "total_issues": len(self.issues),
            "issues": [issue.to_dict() for issue in self.issues],
            "statistics": {
                "by_severity": {
                    "high": len([i for i in self.issues if i.severity == "high"]),
                    "medium": len([i for i in self.issues if i.severity == "medium"]),
                    "low": len([i for i in self.issues if i.severity == "low"])
                },
                "by_type": {
                    issue_type: len([i for i in self.issues if i.issue_type == issue_type])
                    for issue_type in set(i.issue_type for i in self.issues)
                }
            }
        }
        
        return json.dumps(report_data, indent=2)
    
    def _generate_html_report(self) -> str:
        """Generate an HTML report of translation issues."""
        # Basic HTML template
        html = [
            "<!DOCTYPE html>",
            "<html>",
            "<head>",
            "  <title>Translation Validation Report</title>",
            "  <style>",
            "    body { font-family: Arial, sans-serif; margin: 20px; }",
            "    h1 { color: #333; }",
            "    h2 { color: #555; margin-top: 30px; }",
            "    .issue { margin-bottom: 20px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }",
            "    .high { border-left: 5px solid #f44336; }",
            "    .medium { border-left: 5px solid #ff9800; }",
            "    .low { border-left: 5px solid #4caf50; }",
            "    .key { font-weight: bold; }",
            "    .details { margin: 5px 0; }",
            "    .severity { font-size: 0.9em; color: #777; }",
            "    .references { margin-top: 10px; font-size: 0.9em; }",
            "    .file { color: #0066cc; cursor: pointer; }",
            "    .stats { display: flex; margin: 20px 0; }",
            "    .stat-box { flex: 1; padding: 15px; margin: 0 10px; text-align: center; background: #f5f5f5; border-radius: 5px; }",
            "    .stat-value { font-size: 24px; font-weight: bold; margin: 10px 0; }",
            "  </style>",
            "</head>",
            "<body>",
            f"  <h1>Translation Validation Report</h1>",
            f"  <p>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>",
            
            "  <div class='stats'>",
            f"    <div class='stat-box'><div>Total Issues</div><div class='stat-value'>{len(self.issues)}</div></div>",
            f"    <div class='stat-box'><div>High Severity</div><div class='stat-value'>{len([i for i in self.issues if i.severity == 'high'])}</div></div>",
            f"    <div class='stat-box'><div>Medium Severity</div><div class='stat-value'>{len([i for i in self.issues if i.severity == 'medium'])}</div></div>",
            f"    <div class='stat-box'><div>Low Severity</div><div class='stat-value'>{len([i for i in self.issues if i.severity == 'low'])}</div></div>",
            "  </div>",
        ]
        
        # Group issues by type
        by_type = {}
        for issue in self.issues:
            if issue.issue_type not in by_type:
                by_type[issue.issue_type] = []
            by_type[issue.issue_type].append(issue)
        
        # Generate issue sections
        for issue_type, type_issues in by_type.items():
            display_type = issue_type.replace('_', ' ').title()
            html.append(f"  <h2>{display_type} Issues ({len(type_issues)})</h2>")
            
            for issue in type_issues:
                html.append(f"  <div class='issue {issue.severity}'>")
                html.append(f"    <div class='key'>{issue.key}</div>")
                html.append(f"    <div class='details'>{issue.details}</div>")
                html.append(f"    <div class='severity'>Severity: {issue.severity}</div>")
                
                if issue.references:
                    html.append("    <div class='references'>")
                    html.append("      <div>References:</div>")
                    html.append("      <ul>")
                    for ref in issue.references:
                        if "file" in ref:
                            # Format with a file link that can be opened in editors
                            file_path = ref["file"]
                            line = ref.get("line", 1)
                            html.append(f"        <li><a class='file' href='vscode://file/{file_path}:{line}'>{os.path.basename(file_path)}:{line}</a></li>")
                        else:
                            # For database references
                            ref_details = []
                            if "value" in ref:
                                ref_details.append(f"value='{ref['value']}'")
                            if "context" in ref:
                                ref_details.append(f"context='{ref['context']}'")
                            html.append(f"        <li>{', '.join(ref_details)}</li>")
                    html.append("      </ul>")
                    html.append("    </div>")
                
                html.append("  </div>")
        
        # Close HTML
        html.extend([
            "</body>",
            "</html>"
        ])
        
        return "\n".join(html)
    
    def _generate_vscode_report(self) -> str:
        """Generate a report in a format VS Code can use for problem navigation."""
        vscode_problems = []
        
        for issue in self.issues:
            for ref in issue.references:
                if "file" in ref:
                    problem = {
                        "file": ref["file"],
                        "line": ref.get("line", 1),
                        "column": ref.get("column", 1),
                        "severity": "warning" if issue.severity == "high" else "information",
                        "message": f"{issue.issue_type.replace('_', ' ').title()}: {issue.details} (Key: {issue.key})"
                    }
                    vscode_problems.append(problem)
        
        return json.dumps(vscode_problems, indent=2)


def main():
    """Main entry point for the translation validator."""
    parser = argparse.ArgumentParser(description="Validate translations in Record Thing")
    parser.add_argument("--source", required=True, help="Source code directory to scan")
    parser.add_argument("--db", default="record-thing.sqlite", help="Path to the database")
    parser.add_argument("--format", choices=["text", "json", "html", "vscode"], default="text", help="Report format")
    parser.add_argument("--output", help="Output file path (stdout if not specified)")
    parser.add_argument("--severity", choices=["high", "medium", "low", "all"], default="all", help="Minimum issue severity to include")
    parser.add_argument("--types", help="Comma-separated list of issue types to include")
    
    args = parser.parse_args()
    
    # Create validator
    validator = TranslationValidator(db_path=args.db)
    
    # Run validation
    validator.scan_source_code(args.source)
    validator.load_database_keys()
    validator.validate()
    
    # Filter issues
    issue_types = args.types.split(",") if args.types else None
    filtered_issues = validator.filter_issues(
        min_severity=args.severity,
        issue_types=issue_types
    )
    
    # Generate report
    report = validator.generate_report(
        output_format=args.format,
        output_path=args.output
    )
    
    # If no output file specified, print to console
    if not args.output:
        print(report)
    
    # Return success if no high-severity issues
    return 0 if not any(i.severity == "high" for i in filtered_issues) else 1


if __name__ == "__main__":
    sys.exit(main())