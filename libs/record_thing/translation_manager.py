#\!/usr/bin/env python3
"""
Translation Manager for RecordThing App

A comprehensive tool for managing translations in the RecordThing app.
Combines functionality from multiple translation scripts into a single utility.

Features:
- Scan Swift files for hardcoded strings
- Extract translation candidates
- Update database with new translations
- Generate YAML/JSON translation files
- Verify translations against database
- Modify Swift code to use translation keys (optional)
- Support for multiple languages

Usage:
    # Extract strings from source code
    python translation_manager.py extract --source ../../apps/RecordThing/Shared --db record-thing.sqlite

    # Update database with predefined translations
    python translation_manager.py update --db record-thing.sqlite

    # Export translations to YAML
    python translation_manager.py export --db record-thing.sqlite --format yaml --output translations.yaml

    # Import translations from YAML
    python translation_manager.py import --db record-thing.sqlite --input translations.yaml

    # Verify translations
    python translation_manager.py verify --source ../../apps --db record-thing.sqlite

    # Modify Swift code to use translation keys
    python translation_manager.py update --source ../../apps/RecordThing/Shared --db record-thing.sqlite --modify-code
"""

import argparse
import json
import os
import re
import shutil
import sqlite3
import yaml
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional, Any, Union


class TranslationManager:
    def __init__(self, debug_mode: bool = False):
        self.debug_mode = debug_mode
        self.hardcoded_strings: Set[str] = set()
        self.translation_keys: Set[str] = set()
        self.modified_files: List[str] = []

        # Patterns to identify hardcoded strings that should be translated
        self.string_patterns = [
            # Text component patterns - handle various formats and quotes
            r'Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)',            # Text("String") with escaped quotes
            r'Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*,',             # Text("String", ...) with escaped quotes
            
            # Button patterns with more flexible matching
            r'Button\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)',          # Button("Label")
            r'Button\s*\(\s*"((?:[^"\\]|\\.)*)"\s*,',           # Button("Label", ...)
            r'Button\s*\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*role:',   # Button("Label", role: ...)
            
            # Label patterns
            r'Label\s*\(\s*"((?:[^"\\]|\\.)*)"\s*,',            # Label("Text", ...)
            
            # Navigation and section patterns
            r'\.navigationTitle\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)', # .navigationTitle("Title")
            r'Section\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)',          # Section("Header")
            r'Section\s*\(\s*header:\s*Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)', # Section(header: Text("Header"))
            
            # Alert patterns - including all variations
            r'\.alert\s*\(\s*"((?:[^"\\]|\\.)*)"\s*[,)]',        # .alert("Title", ...)
            r'Alert\s*\(\s*title:\s*Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)', # Alert(title: Text("Title"))
            r'title:\s*Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)',    # title: Text("Title")
            
            # Button roles and actions
            r'\.default\s*\(\s*Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)\s*\)', # .default(Text("OK"))
            r'\.default\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)',        # .default("OK")
            r'\.cancel\s*\(\s*Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)\s*\)',  # .cancel(Text("Cancel"))
            r'\.cancel\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)',         # .cancel("Cancel")
            r'\.destructive\s*\(\s*Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)\s*\)', # .destructive(Text("Delete"))
            r'\.destructive\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)',    # .destructive("Delete")
            
            # Form elements
            r'TextField\s*\(\s*"((?:[^"\\]|\\.)*)"\s*,',         # TextField("Placeholder", ...)
            r'Toggle\s*\(\s*"((?:[^"\\]|\\.)*)"\s*[,)]',         # Toggle("Label", ...)
            r'Picker\s*\(\s*"((?:[^"\\]|\\.)*)"\s*,',            # Picker("Selection", ...)
            
            # Menu items
            r'Menu\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)',             # Menu("Label")
            
            # Property patterns
            r'title:\s*"((?:[^"\\]|\\.)*)"\s*[,)]',              # title: "Title"
            r'subtitle:\s*"((?:[^"\\]|\\.)*)"\s*[,)]',           # subtitle: "Subtitle"
            r'placeholder:\s*"((?:[^"\\]|\\.)*)"\s*[,)]',        # placeholder: "Placeholder"
            r'message:\s*"((?:[^"\\]|\\.)*)"\s*[,)]',            # message: "Message"
            r'message:\s*Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)',  # message: Text("Message")
            
            # Accessibility
            r'\.accessibilityLabel\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)', # .accessibilityLabel("Label")
            
            # Multiline text with patterns to catch various formats
            r'Text\s*\(\s*[\n\r]\s*"((?:[^"\\]|\\.)*)"\s*[\n\r]\s*\)', # Text(\n"Multiline"\n)
            r'Text\s*\(\s*[\n\r]\s*"((?:[^"\\]|\\.)*)"\s*\)',     # Text(\n"Multiline")
            
            # Error messages
            r'\.setError\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)',         # .setError("Error message")
            
            # Display values in code
            r'return\s+"((?:[^"\\]|\\.)*)"\s*',                    # return "Display text"
            
            # Concatenated strings
            r'Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\+',               # Text("Line 1" + ...)
            
            # Text with comments
            r'Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*comment:',     # Text("String", comment: ...)
        ]

        # Strings to exclude from translation (debug, technical, etc.)
        self.exclude_patterns = [
            r"^[A-Z_]+$",  # ALL_CAPS constants
            r"^\d+$",  # Numbers only
            r"^[a-z_]+\.[a-z_]+",  # Keys like "ui.button"
            r"^https?://",  # URLs
            r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",  # Email addresses
            r"^\$\d+",  # Prices like $4.99
            r"^\d+\.\d+",  # Version numbers
            r"^[A-Z]{2,}$",  # Country codes, etc.
            r"^$",  # Empty strings
            r"^\s+$",  # Whitespace only
        ]

        # Debug-only interfaces (exclude from translation unless debug_mode is True)
        self.debug_interfaces = [
            "DatabaseDebugView",
            "DatabaseConnectivityDebugView",
            "DatabaseErrorDetailsView",
            "DatabaseMonitor",
            "ConnectivityDebugWrapper",
            "Debug",
        ]

        # Development-only view annotation pattern
        self.dev_only_annotation = r'// @DEVELOPMENT_ONLY'

    def is_development_file(self, file_path: str) -> bool:
        """
        Check if a file is marked as development-only.
        Looks for // @DEVELOPMENT_ONLY annotation in the first 20 lines.
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                for i, line in enumerate(f):
                    if i > 20:  # Only check first 20 lines
                        break
                    if self.dev_only_annotation in line:
                        return True
        except Exception:
            pass
        return False
    
    def should_exclude_string(self, text: str) -> bool:
        """Check if a string should be excluded from translation."""
        for pattern in self.exclude_patterns:
            if re.match(pattern, text):
                return True
        return False

    def is_debug_interface(self, file_path: str) -> bool:
        """Check if the file is a debug-only interface."""
        file_name = Path(file_path).stem
        return any(debug_name in file_name for debug_name in self.debug_interfaces)

    def extract_strings_from_file(self, file_path: str) -> List[Dict]:
        """Extract translatable strings from a Swift file with detailed information."""
        if not file_path.endswith(".swift"):
            return []
            
        is_dev_file = self.is_development_file(file_path)
        strings_found = []

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()

            lines = content.split("\n")

            for line_num, line in enumerate(lines, 1):
                for pattern in self.string_patterns:
                    matches = re.finditer(pattern, line)
                    for match in matches:
                        text = match.group(1)
                        if (
                            not self.should_exclude_string(text)
                            and len(text.strip()) > 0
                        ):
                            # Generate the translation key with appropriate prefix
                            key = self.generate_translation_key(
                                text=text, 
                                line_content=line.strip(),
                                file_path=file_path
                            )
                            
                            # For backward compatibility
                            context = key.split('.')[0] if '.' in key else "ui"
                            
                            # Store the string data
                            string_data = {
                                "text": text,
                                "key": key,
                                "context": context,
                                "file": file_path,
                                "line": line_num,
                                "line_content": line.strip(),
                                "is_dev": is_dev_file or self.is_debug_interface(file_path),
                                "priority": "low" if is_dev_file else "high",
                                "match_start": match.start(1),
                                "match_end": match.end(1),
                                "pattern": pattern,
                            }
                            strings_found.append(string_data)

        except Exception as e:
            print(f"Error reading {file_path}: {e}")

        return strings_found

    def scan_directory(self, directory: str) -> List[Dict]:
        """Scan directory for Swift files and extract strings."""
        all_strings = []

        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.endswith(".swift"):
                    file_path = os.path.join(root, file)
                    strings = self.extract_strings_from_file(file_path)
                    all_strings.extend(strings)

        return all_strings

    def generate_translation_key(self, text: str, context: str = "", line_content: str = "", file_path: str = "") -> str:
        """
        Generate a terse, namespace-prefixed translation key from text.
        
        Args:
            text: The original text to generate a key for
            context: Legacy context (used if prefix not determined)
            line_content: The full line of code containing the text (for context)
            file_path: Path to the source file (for determining prefix)
            
        Returns:
            A translation key with appropriate prefix like "act.settings"
        """
        # Get the namespace prefix
        prefix = ""
        if file_path:
            prefix = self.determine_prefix(file_path, text, line_content)
        elif context:
            # Legacy support: convert old context to new prefix format
            prefix = f"{context}."
        
        # Create a terse key from the text (max 3-4 words)
        # Remove special chars, convert to lowercase
        words = re.sub(r"[^a-zA-Z0-9\s]", "", text.lower()).split()
        
        # Use only the most significant words (max 3-4)
        significant_words = []
        stop_words = {"and", "or", "the", "a", "an", "in", "on", "at", "to", "for", "with", 
                     "your", "my", "our", "their", "his", "her", "its", "of"}
        
        # Filter out stop words and limit to 3-4 significant words
        for word in words:
            if word not in stop_words and len(significant_words) < 4:
                significant_words.append(word)
        
        # If we have no significant words (rare), use the first 2-3 words
        if not significant_words and words:
            significant_words = words[:min(3, len(words))]
        
        # Join with underscores for better readability in keys
        key_suffix = "_".join(significant_words)
        
        # Combine prefix with key suffix
        key = f"{prefix}{key_suffix}"
        
        return key
        
    def swift_safe_identifier(self, key: str) -> str:
        """Convert a translation key to a Swift-safe identifier."""
        # Replace dots with underscores
        identifier = key.replace(".", "_")
        
        # Ensure identifier doesn't start with a number
        if identifier and identifier[0].isdigit():
            identifier = f"t_{identifier}"
            
        # Remove any characters not allowed in Swift identifiers
        identifier = re.sub(r"[^a-zA-Z0-9_]", "", identifier)
        
        # Ensure not empty
        if not identifier:
            identifier = "empty_key"
            
        return identifier

    def determine_prefix(self, file_path: str, text: str, line_content: str = "", component_type: str = "") -> str:
        """
        Determine the appropriate prefix for a translation key based on context.
        
        This uses a multi-layered approach to identify the most specific prefix:
        1. Check the file structure (directory/filename)
        2. Analyze the component type (Button, Text, etc.)
        3. Consider the context of the string within the view
        4. Look at the string content for clues
        
        Returns a terse but meaningful prefix like "act.", "sect.", etc.
        """
        file_name = Path(file_path).stem.lower()
        path_parts = [p.lower() for p in Path(file_path).parts]
        
        # Extract ViewName from path (e.g., ActionsView from ActionsView.swift)
        view_name = file_name.replace("view", "").strip()
        
        # 1. Check for special directory contexts first (highest priority)
        if any(p.lower() == "database" for p in path_parts):
            return "db."
        elif any(p.lower() == "settings" for p in path_parts):
            return "set."
        elif any(p.lower() == "evidence" for p in path_parts):
            return "ev."
        
        # 2. Check for section headers, navigation titles, etc.
        section_indicators = [
            "section header", "header:", "navigationtitle", ".navigationtitle"
        ]
        if any(indicator in line_content.lower() for indicator in section_indicators):
            return "sect."
        
        # 3. Check for action items, buttons, etc.
        action_indicators = ["button", "action", "onrecordtapped", "ontap"]
        if any(indicator in line_content.lower() for indicator in action_indicators):
            return "act."
        
        # 4. Check for agreement related text
        if "agreement" in file_name or any("agreement" in p.lower() for p in path_parts):
            return "agr."
        elif "agreement" in text.lower() or "terms" in text.lower() or "policy" in text.lower():
            return "agr."
        
        # 5. Account and profile related
        if "account" in file_name or "profile" in file_name:
            return "acc."
        elif "account" in text.lower() or "profile" in text.lower():
            return "acc."
        
        # 6. Team related
        if "team" in file_name or "team" in text.lower():
            return "team."
        
        # 7. Status related
        status_words = ["status", "accepted", "pending", "expired", "complete"]
        if any(word in text.lower() for word in status_words):
            return "stat."
        
        # 8. Accessibility labels
        if "accessibility" in line_content.lower() or ".accessibilitylabel" in line_content.lower():
            return "a11y."
        
        # 9. Error messages
        error_indicators = ["error", "failed", "invalid", "unable"]
        if any(indicator in text.lower() for indicator in error_indicators):
            return "err."
        
        # 10. Check for view-specific prefixes based on filename
        if "actions" in file_name:
            return "act."
        elif "settings" in file_name:
            return "set."
        elif "profile" in file_name:
            return "prof."
        elif "navigation" in file_name:
            return "nav."
            
        # 11. Default fallback for general UI elements
        return "ui."
    
    def determine_context(self, file_path: str, text: str, line_content: str = "") -> str:
        """
        Determine the context category for a translation.
        This is a legacy method maintained for compatibility.
        New code should use determine_prefix instead.
        """
        # Use the new prefix system, but drop the trailing dot for compatibility
        prefix = self.determine_prefix(file_path, text, line_content)
        return prefix[:-1]  # Drop the trailing dot

    def load_existing_translations(self, db_path: str) -> Dict[str, Dict[str, str]]:
        """
        Load existing translations from database.
        Returns a dictionary of {lang: {key: value}}
        """
        translations = defaultdict(dict)

        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            cursor.execute("SELECT lang, key, value, context FROM translations")
            for lang, key, value, context in cursor.fetchall():
                translations[lang][key] = {"value": value, "context": context}

            conn.close()

        except Exception as e:
            print(f"Error loading existing translations: {e}")

        return translations

    def update_database(self, db_path: str, new_translations: List[Dict]) -> int:
        """
        Update the SQLite database with new translations.
        Returns the number of translations added.
        """
        existing_translations = self.load_existing_translations(db_path)
        existing_keys = set(existing_translations.get("en", {}).keys())
        
        translations_to_add = []

        for translation in new_translations:
            key = translation["key"]
            if key not in existing_keys:
                translations_to_add.append((
                    "en",  # language
                    key,  # key
                    translation["text"],  # value
                    translation["context"],  # context
                ))

        if not translations_to_add:
            print("No new translations to add.")
            return 0

        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            # Check if translations table exists
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name='translations'
            """)

            if not cursor.fetchone():
                print("Creating translations table...")
                cursor.execute("""
                    CREATE TABLE translations (
                        lang VARCHAR NOT NULL,
                        key VARCHAR NOT NULL,
                        value TEXT NOT NULL,
                        context VARCHAR,
                        PRIMARY KEY (lang, key)
                    )
                """)

            # Add new translations
            cursor.executemany(
                "INSERT OR IGNORE INTO translations (lang, key, value, context) VALUES (?, ?, ?, ?)",
                translations_to_add,
            )

            conn.commit()
            
            # Ensure proper PRAGMA checkpoint
            cursor.execute("PRAGMA wal_checkpoint(FULL)")
            
            conn.close()

            print(f"Added {len(translations_to_add)} new translations to database.")
            return len(translations_to_add)

        except Exception as e:
            print(f"Error updating database: {e}")
            return 0

    def update_predefined_translations(self, db_path: str, translations: List[Tuple[str, str, str, str]]) -> int:
        """
        Update the database with predefined translations.
        Returns the number of translations added.
        """
        existing_translations = self.load_existing_translations(db_path)
        existing_keys = set()
        for lang in existing_translations:
            existing_keys.update((lang, key) for key in existing_translations[lang])
        
        translations_to_add = []
        translations_to_update = []

        for translation in translations:
            lang, key, value, context = translation
            if (lang, key) not in existing_keys:
                translations_to_add.append(translation)
            else:
                translations_to_update.append((value, context, lang, key))

        if not translations_to_add and not translations_to_update:
            print("No translations to add or update.")
            return 0

        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()

            # Check if translations table exists
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name='translations'
            """)

            if not cursor.fetchone():
                print("Creating translations table...")
                cursor.execute("""
                    CREATE TABLE translations (
                        lang VARCHAR NOT NULL,
                        key VARCHAR NOT NULL,
                        value TEXT NOT NULL,
                        context VARCHAR,
                        PRIMARY KEY (lang, key)
                    )
                """)

            # Add new translations
            if translations_to_add:
                cursor.executemany(
                    "INSERT INTO translations (lang, key, value, context) VALUES (?, ?, ?, ?)",
                    translations_to_add,
                )
                print(f"Added {len(translations_to_add)} new translations")

            # Update existing translations
            if translations_to_update:
                cursor.executemany(
                    "UPDATE translations SET value = ?, context = ? WHERE lang = ? AND key = ?",
                    translations_to_update,
                )
                print(f"Updated {len(translations_to_update)} existing translations")

            conn.commit()
            
            # Ensure proper PRAGMA checkpoint
            cursor.execute("PRAGMA wal_checkpoint(FULL)")
            
            conn.close()

            return len(translations_to_add) + len(translations_to_update)

        except Exception as e:
            print(f"Error updating database: {e}")
            return 0

    def copy_to_resources(self, source_db: str, target_db: str) -> bool:
        """
        Copy the updated database to the app resources.
        Returns True if successful, False otherwise.
        """
        try:
            source_path = Path(source_db)
            target_path = Path(target_db)

            if not source_path.exists():
                print(f"Source database not found: {source_path}")
                return False

            # Ensure target directory exists
            target_path.parent.mkdir(parents=True, exist_ok=True)

            # Copy the file
            shutil.copy2(source_path, target_path)
            print(f"Copied database from {source_path} to {target_path}")
            return True

        except Exception as e:
            print(f"Error copying database: {e}")
            return False

    def export_translations(self, db_path: str, output_format: str, output_file: str) -> bool:
        """
        Export translations from database to a file.
        Supported formats: json, yaml, sql
        Returns True if successful, False otherwise.
        """
        try:
            # Load translations from database
            translations = self.load_existing_translations(db_path)
            
            # Convert to a more exportable format
            export_data = defaultdict(dict)
            
            for lang in translations:
                for key, data in translations[lang].items():
                    context = data.get("context", "")
                    if context not in export_data[lang]:
                        export_data[lang][context] = {}
                    export_data[lang][context][key] = data["value"]
            
            # Export in the requested format
            if output_format == "json":
                with open(output_file, "w", encoding="utf-8") as f:
                    json.dump(export_data, f, indent=2, ensure_ascii=False)
            
            elif output_format == "yaml":
                with open(output_file, "w", encoding="utf-8") as f:
                    yaml.dump(export_data, f, default_flow_style=False, allow_unicode=True)
            
            elif output_format == "sql":
                with open(output_file, "w", encoding="utf-8") as f:
                    f.write("-- RecordThing Translations SQL\n\n")
                    
                    # Create table if not exists
                    f.write("""
CREATE TABLE IF NOT EXISTS translations (
    lang VARCHAR NOT NULL,
    key VARCHAR NOT NULL,
    value TEXT NOT NULL,
    context VARCHAR,
    PRIMARY KEY (lang, key)
);

""")
                    
                    # Insert statements
                    for lang in translations:
                        for key, data in translations[lang].items():
                            value = data["value"].replace("'", "''")  # Escape single quotes
                            context = data.get("context", "")
                            f.write(f"INSERT OR IGNORE INTO translations (lang, key, value, context) VALUES ('{lang}', '{key}', '{value}', '{context}');\n")
            
            else:
                print(f"Unsupported format: {output_format}")
                return False
            
            print(f"Exported translations to {output_file} in {output_format} format")
            return True
        
        except Exception as e:
            print(f"Error exporting translations: {e}")
            return False

    def import_translations(self, db_path: str, input_file: str) -> bool:
        """
        Import translations from a file to the database.
        Supports JSON and YAML formats.
        Returns True if successful, False otherwise.
        """
        try:
            # Determine format from file extension
            input_format = Path(input_file).suffix.lower()[1:]  # Remove leading dot
            
            # Load the input file
            if input_format == "json":
                with open(input_file, "r", encoding="utf-8") as f:
                    import_data = json.load(f)
            
            elif input_format in ["yaml", "yml"]:
                with open(input_file, "r", encoding="utf-8") as f:
                    import_data = yaml.safe_load(f)
            
            else:
                print(f"Unsupported format: {input_format}")
                return False
            
            # Convert to a list of tuples for database import
            translations_to_import = []
            
            for lang in import_data:
                for context, keys in import_data[lang].items():
                    for key, value in keys.items():
                        translations_to_import.append((lang, key, value, context))
            
            # Update database
            count = self.update_predefined_translations(db_path, translations_to_import)
            print(f"Imported {count} translations from {input_file}")
            return True
        
        except Exception as e:
            print(f"Error importing translations: {e}")
            return False

    def process_file(self, file_path, is_dev_file, modify_code):
        """Process a single file: extract strings and optionally modify it."""
        strings_found = []
        file_modified = False
        
        if not file_path.endswith(".swift"):
            return strings_found, file_modified
        
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            lines = content.split("\n")
            new_lines = lines.copy()
            modified = False
            
            for line_idx, line in enumerate(lines):
                line_strings = []
                
                for pattern in self.string_patterns:
                    matches = list(re.finditer(pattern, line))
                    
                    # Process matches in reverse order to avoid index shifts
                    for match in reversed(matches):
                        text = match.group(1)
                        if not self.should_exclude_string(text) and len(text.strip()) > 0:
                            key = self.generate_translation_key(
                                text=text,
                                line_content=line.strip(),
                                file_path=file_path
                            )
                            
                            # For backward compatibility
                            context = key.split('.')[0] if '.' in key else "ui"
                            
                            string_data = {
                                "text": text,
                                "key": key,
                                "context": context,
                                "file": file_path,
                                "line": line_idx + 1,
                                "line_content": line.strip(),
                                "is_dev": is_dev_file,
                                "priority": "low" if is_dev_file else "high",
                            }
                            strings_found.append(string_data)
                            line_strings.append((match, string_data))
                
                # If we're modifying code and have strings to replace
                if modify_code and line_strings and not is_dev_file:
                    new_line = line
                    
                    # Replace strings with translation keys (in reverse order)
                    for match, string_data in reversed(line_strings):
                        key = string_data["key"]
                        
                        # Get the full match and replace with key.translated pattern
                        full_match = match.group(0)
                        key = string_data["key"]
                        replacement = full_match.replace(
                            f'"{string_data["text"]}"', 
                            f'"{key}".translated'
                        )
                        
                        # Replace in the line
                        new_line = new_line[:match.start(0)] + replacement + new_line[match.end(0):]
                    
                    if new_line != line:
                        new_lines[line_idx] = new_line
                        modified = True
            
            # If code was modified, write back to file
            if modify_code and modified:
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write("\n".join(new_lines))
                file_modified = True
                self.modified_files.append(file_path)
        
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
        
        return strings_found, file_modified

    def process_directory(self, directory: str, db_path: str, modify_code: bool = False):
        """
        Process all Swift files in a directory: extract strings, update database, and modify code.
        Returns a tuple of (strings_found, files_modified).
        """
        all_strings = []
        modified_files = []
        
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.endswith(".swift"):
                    file_path = os.path.join(root, file)
                    is_dev_file = self.is_development_file(file_path) or self.is_debug_interface(file_path)
                    
                    strings, modified = self.process_file(file_path, is_dev_file, modify_code)
                    all_strings.extend(strings)
                    
                    if modified:
                        modified_files.append(file_path)
        
        # Update database with new translations
        if db_path:
            self.update_database(db_path, all_strings)
        
        return all_strings, modified_files

    def verify_translations(self, source_dir: str, db_path: str) -> Dict[str, List[Dict]]:
        """
        Verify translations against source code.
        Returns a dictionary of issues by category.
        """
        # Load all translations from database
        translations = self.load_existing_translations(db_path)
        db_keys = set(translations.get("en", {}).keys())
        
        # Scan source code for translation keys and hardcoded strings
        source_keys = set()
        hardcoded_strings = []
        
        for root, dirs, files in os.walk(source_dir):
            for file in files:
                if file.endswith(".swift"):
                    file_path = os.path.join(root, file)
                    is_dev_file = self.is_development_file(file_path) or self.is_debug_interface(file_path)
                    
                    # Extract hardcoded strings
                    strings = self.extract_strings_from_file(file_path)
                    
                    # Only flag non-dev files for hardcoded strings
                    if not is_dev_file and not self.debug_mode:
                        hardcoded_strings.extend(strings)
                    
                    # Look for translation keys in use
                    try:
                        with open(file_path, "r", encoding="utf-8") as f:
                            content = f.read()
                        
                        # Find translation keys: TranslationKeys.key_name
                        key_matches = re.finditer(r'TranslationKeys\.([a-zA-Z0-9_]+)', content)
                        for match in key_matches:
                            key_name = match.group(1)
                            # Convert underscore format to dot format
                            key = key_name.replace("_", ".")
                            source_keys.add(key)
                    except Exception as e:
                        print(f"Error reading {file_path}: {e}")
        
        # Check for missing translations (keys used in code but not in database)
        missing_translations = source_keys - db_keys
        
        # Check for unused translations (keys in database but not used in code)
        unused_translations = db_keys - source_keys
        
        # Prepare results
        results = {
            "missing_translations": [{"key": key} for key in missing_translations],
            "unused_translations": [{"key": key} for key in unused_translations],
            "hardcoded_strings": hardcoded_strings
        }
        
        return results

    def run_swiftlint(self, file_path: str, fix: bool = True) -> Tuple[bool, str]:
        """
        Run SwiftLint on a Swift file.
        
        Args:
            file_path: Path to the Swift file
            fix: Whether to automatically fix issues (default: True)
            
        Returns:
            Tuple of (success, output)
        """
        try:
            import subprocess
            
            # Check if SwiftLint is installed
            result = subprocess.run(["which", "swiftlint"], capture_output=True, text=True)
            if result.returncode != 0:
                return False, "SwiftLint not found. Install with 'brew install swiftlint'"
            
            # Prepare SwiftLint command
            cmd = ["swiftlint"]
            if fix:
                cmd.append("--fix")
            cmd.append(file_path)
            
            # Run SwiftLint
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                return True, "SwiftLint passed with no issues" if not result.stdout.strip() else result.stdout
            else:
                return False, result.stderr or result.stdout
                
        except Exception as e:
            return False, f"Error running SwiftLint: {e}"

    def generate_translation_keys_swift(self, db_path: str, output_file: str) -> bool:
        """
        Generate a Swift file with translation keys.
        Returns True if successful, False otherwise.
        """
        try:
            # Load translations from database
            translations = self.load_existing_translations(db_path)
            keys = set(translations.get("en", {}).keys())
            
            # Check for Swift-unsafe keys and duplicates
            swift_keys = {}
            problem_keys = []
            
            for key in keys:
                swift_key = self.swift_safe_identifier(key)
                
                # Check for duplicates
                if swift_key in swift_keys:
                    problem_keys.append((key, swift_key, "Duplicate after conversion"))
                else:
                    swift_keys[swift_key] = key
            
            # Print warnings for problem keys
            if problem_keys:
                print("\n⚠️ Warning: Found problematic translation keys:")
                for orig_key, swift_key, reason in problem_keys:
                    print(f"  - '{orig_key}' → '{swift_key}': {reason}")
                print("These keys may cause compiler errors if not fixed.")
            
            # Generate the Swift file
            with open(output_file, "w", encoding="utf-8") as f:
                f.write("""//
// TranslationKeys.swift
// RecordThing
//
// Generated by translation_manager.py - DO NOT EDIT MANUALLY
//

import Foundation

/// Translation keys for the RecordThing app
/// Generated automatically - do not modify directly
public struct TranslationKeys {
""")
                
                # Group keys by context for better organization
                context_groups = defaultdict(list)
                for swift_key, orig_key in swift_keys.items():
                    context = orig_key.split('.')[0] if '.' in orig_key else 'general'
                    context_groups[context].append((swift_key, orig_key))
                
                # Write keys by context group
                for context, keys in sorted(context_groups.items()):
                    f.write(f"\n    // MARK: - {context.capitalize()} keys\n")
                    for swift_key, orig_key in sorted(keys):
                        value = translations.get("en", {}).get(orig_key, {}).get("value", "")
                        f.write(f'    /// {value}\n')
                        f.write(f'    public static let {swift_key} = "{orig_key}"\n')
                
                f.write("}\n")
            
            print(f"✅ Generated translation keys in {output_file}")
            print(f"   Total keys: {len(swift_keys)}")
            return True
        
        except Exception as e:
            print(f"Error generating translation keys: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(
        description="Translation Manager for RecordThing App"
    )
    
    # Create subparsers for different commands
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")
    
    # Extract command
    extract_parser = subparsers.add_parser("extract", help="Extract translatable strings from source code")
    extract_parser.add_argument("--source", required=True, help="Directory to scan for translatable strings")
    extract_parser.add_argument("--db", help="Path to SQLite database to update")
    extract_parser.add_argument("--output", help="Output file for extracted strings (JSON)")
    extract_parser.add_argument("--debug-only", action="store_true", help="Include debug interfaces")
    extract_parser.add_argument("--modify-code", action="store_true", help="Modify Swift code to use translation keys")
    
    # Update command
    update_parser = subparsers.add_parser("update", help="Update database with translations")
    update_parser.add_argument("--db", required=True, help="Path to SQLite database to update")
    update_parser.add_argument("--source", help="Directory to scan for translatable strings")
    update_parser.add_argument("--copy-to-resources", action="store_true", help="Copy database to app resources")
    update_parser.add_argument("--modify-code", action="store_true", help="Modify Swift code to use translation keys")
    update_parser.add_argument("--generate-swift", help="Generate Swift translation keys file")
    update_parser.add_argument("--swift-package", help="Path to Swift package to build (validates Swift compilation)")
    update_parser.add_argument("--swift-module", help="Module name for the generated Swift file")
    update_parser.add_argument("--run-swiftlint", action="store_true", help="Run SwiftLint on generated Swift file")
    
    # Export command
    export_parser = subparsers.add_parser("export", help="Export translations from database")
    export_parser.add_argument("--db", required=True, help="Path to SQLite database")
    export_parser.add_argument("--format", required=True, choices=["json", "yaml", "sql"], help="Output format")
    export_parser.add_argument("--output", required=True, help="Output file path")
    
    # Import command
    import_parser = subparsers.add_parser("import", help="Import translations to database")
    import_parser.add_argument("--db", required=True, help="Path to SQLite database")
    import_parser.add_argument("--input", required=True, help="Input file path (JSON or YAML)")
    import_parser.add_argument("--copy-to-resources", action="store_true", help="Copy database to app resources")
    
    # Verify command
    verify_parser = subparsers.add_parser("verify", help="Verify translations against source code")
    verify_parser.add_argument("--source", required=True, help="Source directory to scan")
    verify_parser.add_argument("--db", required=True, help="Path to SQLite database")
    verify_parser.add_argument("--output", help="Output file for verification results (JSON)")
    verify_parser.add_argument("--include-debug", action="store_true", help="Include debug interfaces in verification")
    
    args = parser.parse_args()
    
    # Default resource path
    resources_db_path = "../../apps/RecordThing/Shared/Resources/default-record-thing.sqlite"
    
    # Create translation manager
    manager = TranslationManager(debug_mode=getattr(args, "debug_only", False) or getattr(args, "include_debug", False))
    
    if args.command == "extract":
        print(f"🔍 Scanning directory: {args.source}")
        
        if args.modify_code:
            strings, modified_files = manager.process_directory(args.source, args.db, True)
            print(f"✅ Processed {len(strings)} strings, modified {len(modified_files)} files")
            
            if modified_files:
                print("\nModified files:")
                for file in modified_files[:10]:
                    print(f"  - {file}")
                if len(modified_files) > 10:
                    print(f"  ... and {len(modified_files) - 10} more")
        else:
            strings = manager.scan_directory(args.source)
            print(f"✅ Found {len(strings)} translation candidates")
            
            if args.db:
                manager.update_database(args.db, strings)
        
        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                json.dump(strings, f, indent=2, ensure_ascii=False)
            print(f"💾 Saved extraction results to {args.output}")
    
    elif args.command == "update":
        try:
            # Try to import from update_translations.py
            import update_translations
            DATABASE_DEBUG_TRANSLATIONS = update_translations.DATABASE_DEBUG_TRANSLATIONS
        except ImportError:
            # Define minimal translations if import fails
            DATABASE_DEBUG_TRANSLATIONS = [
                ("en", "ui.done", "Done", "ui"),
                ("en", "ui.close", "Close", "ui"),
                ("en", "ui.refresh", "Refresh", "ui")
            ]
            print("Warning: Could not import from update_translations.py - using minimal translations")
        
        print(f"🔄 Updating translations in database: {args.db}")
        
        # Update with predefined translations
        manager.update_predefined_translations(args.db, DATABASE_DEBUG_TRANSLATIONS)
        
        # Scan source if provided
        if args.source:
            print(f"🔍 Scanning directory: {args.source}")
            
            if args.modify_code:
                strings, modified_files = manager.process_directory(args.source, args.db, True)
                print(f"✅ Processed {len(strings)} strings, modified {len(modified_files)} files")
                
                if modified_files:
                    print("\nModified files:")
                    for file in modified_files[:10]:
                        print(f"  - {file}")
                    if len(modified_files) > 10:
                        print(f"  ... and {len(modified_files) - 10} more")
            else:
                strings = manager.scan_directory(args.source)
                print(f"✅ Found {len(strings)} translation candidates")
                manager.update_database(args.db, strings)
        
        # Generate Swift keys file if requested
        if args.generate_swift:
            swift_file_path = args.generate_swift
            success = manager.generate_translation_keys_swift(args.db, swift_file_path)
            
            # Run SwiftLint if requested
            if success and args.run_swiftlint:
                print(f"\n🔍 Running SwiftLint on {swift_file_path}...")
                lint_success, lint_output = manager.run_swiftlint(swift_file_path)
                if lint_success:
                    print(f"✅ SwiftLint passed")
                    if lint_output and lint_output != "SwiftLint passed with no issues":
                        print(lint_output)
                else:
                    print(f"⚠️ SwiftLint reported issues:")
                    print(lint_output)
            
            # Verify Swift compilation if package path provided
            if success and args.swift_package:
                try:
                    print(f"\n🔍 Verifying Swift compilation...")
                    module_name = args.swift_module or "RecordLib"
                    
                    # Copy to proper location in Swift package
                    swift_dir = os.path.join(args.swift_package, "Sources", module_name)
                    if not os.path.exists(swift_dir):
                        os.makedirs(swift_dir, exist_ok=True)
                    
                    target_path = os.path.join(swift_dir, "TranslationKeys.swift")
                    shutil.copy2(swift_file_path, target_path)
                    print(f"Copied TranslationKeys.swift to {target_path}")
                    
                    # Try to build the package
                    import subprocess
                    build_result = subprocess.run(
                        ["swift", "build", "--package-path", args.swift_package],
                        capture_output=True, text=True
                    )
                    
                    if build_result.returncode == 0:
                        print("✅ Swift compilation successful!")
                    else:
                        print("❌ Swift compilation failed:")
                        print(build_result.stderr)
                        print("\nPlease fix the Swift code generation or manually adjust the translation keys.")
                except Exception as e:
                    print(f"Error verifying Swift compilation: {e}")
        
        # Copy to resources if requested
        if args.copy_to_resources:
            manager.copy_to_resources(args.db, resources_db_path)
    
    elif args.command == "export":
        print(f"📤 Exporting translations from {args.db} to {args.output} in {args.format} format")
        manager.export_translations(args.db, args.format, args.output)
    
    elif args.command == "import":
        print(f"📥 Importing translations from {args.input} to {args.db}")
        manager.import_translations(args.db, args.input)
        
        # Copy to resources if requested
        if args.copy_to_resources:
            manager.copy_to_resources(args.db, resources_db_path)
    
    elif args.command == "verify":
        print(f"🔍 Verifying translations in {args.source} against {args.db}")
        results = manager.verify_translations(args.source, args.db)
        
        # Print summary
        print("\n📊 Verification Results:")
        print(f"  Missing translations: {len(results['missing_translations'])}")
        print(f"  Unused translations: {len(results['unused_translations'])}")
        print(f"  Hardcoded strings: {len(results['hardcoded_strings'])}")
        
        # Save results if requested
        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                json.dump(results, f, indent=2, ensure_ascii=False)
            print(f"💾 Saved verification results to {args.output}")
    
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
