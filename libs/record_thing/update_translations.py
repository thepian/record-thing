#!/usr/bin/env python3
"""
Translation updater for Record Thing app.
Updates translations in the database and generates Swift code to use translation keys.
"""

import os
import re
import sqlite3
import argparse
import logging
import sys
from typing import Dict, List, Set, Tuple
from pathlib import Path

from commons import resolve_path, resolve_directory, resolve_database_path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("update_translations")

class TranslationUpdater:
    """
    Updates translations in the database and generates Swift code to use translation keys.
    """
    
    def __init__(self, db_path: str = None):
        """
        Initialize the translation updater.
        
        Args:
            db_path: Path to the SQLite database (defaults to repo's record-thing.sqlite)
        """
        self.db_path = str(resolve_database_path(db_path))
        self.conn = None
        self.translations = {}  # {id: (text, en, da, ru)}
        
    def connect_db(self):
        """
        Connect to the SQLite database and load existing translations.
        """
        try:
            self.conn = sqlite3.connect(self.db_path)
            cursor = self.conn.cursor()
            
            # Check if translations table exists
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='table' AND name='translations'
            """)
            if not cursor.fetchone():
                logger.error("Translations table doesn't exist. Run translation_extractor.py first.")
                raise ValueError("Translations table doesn't exist")
            
            # Load all translations
            cursor.execute("SELECT id, text, en, da, ru FROM translations")
            for row in cursor.fetchall():
                key, text, en, da, ru = row
                self.translations[key] = (text, en, da, ru)
                
            logger.info(f"Loaded {len(self.translations)} translations from database")
            
        except sqlite3.Error as e:
            logger.error(f"Database error: {e}")
            raise
    
    def update_translation(self, key: str, language: str, translation: str):
        """
        Update a translation in the database.
        
        Args:
            key: Translation key
            language: Language code (en, da, ru)
            translation: The translated text
        """
        if not self.conn:
            self.connect_db()
        
        try:
            if key not in self.translations:
                logger.warning(f"Translation key '{key}' not found in database")
                return False
            
            # Update the translation
            cursor = self.conn.cursor()
            cursor.execute(f"""
                UPDATE translations
                SET {language} = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
            """, (translation, key))
            
            self.conn.commit()
            
            # Update our local cache
            text, en, da, ru = self.translations[key]
            if language == "en":
                self.translations[key] = (text, translation, da, ru)
            elif language == "da":
                self.translations[key] = (text, en, translation, ru)
            elif language == "ru":
                self.translations[key] = (text, en, da, translation)
            
            logger.info(f"Updated {language} translation for '{key}': {translation}")
            return True
            
        except sqlite3.Error as e:
            logger.error(f"Database error while updating translation: {e}")
            self.conn.rollback()
            return False
    
    def import_translations_from_file(self, file_path: str, language: str):
        """
        Import translations from a file in the format key=translation.
        
        Args:
            file_path: Path to the translations file
            language: Language code (en, da, ru)
        """
        if not self.conn:
            self.connect_db()
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            updated_count = 0
            for line in lines:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                
                # Parse key=translation format
                if '=' in line:
                    key, translation = line.split('=', 1)
                    key = key.strip()
                    translation = translation.strip()
                    
                    if self.update_translation(key, language, translation):
                        updated_count += 1
            
            logger.info(f"Imported {updated_count} translations for {language} from {file_path}")
            
        except Exception as e:
            logger.error(f"Error importing translations from {file_path}: {e}")
    
    def export_translations_to_file(self, file_path: str, language: str, missing_only: bool = False):
        """
        Export translations to a file in the format key=translation.
        
        Args:
            file_path: Path to the output file
            language: Language code (en, da, ru)
            missing_only: If True, only export keys with missing translations
        """
        if not self.conn:
            self.connect_db()
        
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(f"# {language.upper()} translations for Record Thing\n")
                f.write("# Format: key=translation\n\n")
                
                # Determine index for the requested language
                lang_index = {"en": 1, "da": 2, "ru": 3}.get(language, 1)
                
                # Sort keys by namespace for better organization
                sorted_keys = sorted(self.translations.keys())
                current_namespace = ""
                
                for key in sorted_keys:
                    # Get translation values
                    text, en, da, ru = self.translations[key]
                    translations = [en, da, ru]
                    
                    # Check if this translation should be included
                    if missing_only and translations[lang_index - 1]:
                        continue
                    
                    # Add namespace header if changed
                    namespace = key.split('.')[0] if '.' in key else key
                    if namespace != current_namespace:
                        current_namespace = namespace
                        f.write(f"\n# {namespace.upper()} namespace\n")
                    
                    # For non-English languages, include English as a comment for reference
                    if language != "en":
                        f.write(f"# Original: {text}\n")
                        if en:
                            f.write(f"# English: {en}\n")
                    
                    # Write the translation (or empty string if missing)
                    translation = translations[lang_index - 1] or ""
                    f.write(f"{key}={translation}\n")
            
            logger.info(f"Exported translations for {language} to {file_path}")
            
        except Exception as e:
            logger.error(f"Error exporting translations to {file_path}: {e}")
    
    def export_swift_strings_file(self, output_dir: str, language: str):
        """
        Export translations to a Swift .strings file.
        
        Args:
            output_dir: Directory to write the .strings file
            language: Language code (en, da, ru)
        """
        if not self.conn:
            self.connect_db()
        
        try:
            # Create language directory if it doesn't exist
            lang_dir = os.path.join(output_dir, f"{language}.lproj")
            os.makedirs(lang_dir, exist_ok=True)
            
            # Create Localizable.strings file
            file_path = os.path.join(lang_dir, "Localizable.strings")
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write("/* \n")
                f.write(f" * Localizable.strings ({language})\n")
                f.write(" * Record Thing\n")
                f.write(" * Generated by update_translations.py\n")
                f.write(" */\n\n")
                
                # Determine index for the requested language
                lang_index = {"en": 1, "da": 2, "ru": 3}.get(language, 1)
                
                # Sort keys by namespace for better organization
                sorted_keys = sorted(self.translations.keys())
                current_namespace = ""
                
                for key in sorted_keys:
                    # Get translation values
                    text, en, da, ru = self.translations[key]
                    translations = [en, da, ru]
                    translation = translations[lang_index - 1]
                    
                    # Skip if translation is missing
                    if not translation:
                        continue
                    
                    # Add namespace header if changed
                    namespace = key.split('.')[0] if '.' in key else key
                    if namespace != current_namespace:
                        current_namespace = namespace
                        f.write(f"\n// MARK: - {namespace.upper()} namespace\n")
                    
                    # Write the translation in Swift .strings format
                    f.write(f"\"{key}\" = \"{translation.replace('"', '\\"')}\";\n")
            
            logger.info(f"Exported Swift strings file for {language} to {file_path}")
            
        except Exception as e:
            logger.error(f"Error exporting Swift strings file to {file_path}: {e}")
    
    def update_swift_code(self, file_path: str, dry_run: bool = False):
        """
        Update Swift code to use translation keys.
        
        Args:
            file_path: Path to the Swift source file
            dry_run: If True, don't actually modify the file, just log what would change
        """
        if not self.conn:
            self.connect_db()
        
        try:
            # Create a text to key mapping
            text_to_key = {}
            for key, (text, _, _, _) in self.translations.items():
                text_to_key[text] = key
            
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Create a copy of the original content
            new_content = content
            
            # Find strings that might need translation
            # This regex matches quoted strings that aren't already using the .translated extension
            pattern = r'(?<![a-zA-Z0-9_])(?:"([^"\\]*(?:\\.[^"\\]*)*)")(?!\s*\.\s*translated)'
            
            for match in re.finditer(pattern, content):
                full_match = match.group(0)
                string = match.group(1)
                
                # Skip empty strings or strings that are likely not translatable
                if not string or string.isdigit() or re.match(r'^%[dfsiu]$', string):
                    continue
                
                # Skip strings that look like formatters, keys, or identifiers
                if '%' in string or string.startswith('$') or re.match(r'^[A-Za-z0-9_]+$', string):
                    continue
                
                # Check if we have a translation key for this string
                if string in text_to_key:
                    key = text_to_key[string]
                    # Replace with key.translated
                    replacement = f'"{key}".translated'
                    if dry_run:
                        logger.info(f"Would replace '{full_match}' with '{replacement}'")
                    else:
                        new_content = new_content.replace(full_match, replacement)
            
            # If content changed and not a dry run, write back to file
            if new_content != content and not dry_run:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                logger.info(f"Updated Swift code in {file_path}")
            elif new_content != content:
                logger.info(f"Would update Swift code in {file_path} (dry run)")
            else:
                logger.info(f"No changes needed in {file_path}")
            
        except Exception as e:
            logger.error(f"Error updating Swift code in {file_path}: {e}")
    
    def process_directory(self, directory: str, update_code: bool = False, dry_run: bool = False):
        """
        Process all Swift files in a directory to update code to use translation keys.
        
        Args:
            directory: Directory to process
            update_code: If True, update Swift code to use translation keys
            dry_run: If True, don't actually modify files
        """
        if not self.conn:
            self.connect_db()
        
        # Walk through directory structure
        for root, _, files in os.walk(directory):
            for file in files:
                # Only process Swift files
                if file.endswith('.swift'):
                    file_path = os.path.join(root, file)
                    logger.info(f"Processing file: {file_path}")
                    
                    if update_code:
                        self.update_swift_code(file_path, dry_run)
    
    def close(self):
        """Close database connection."""
        if self.conn:
            self.conn.close()
            self.conn = None

def main():
    """Main entry point for the translation updater script."""
    parser = argparse.ArgumentParser(description="Update translations and generate Swift code")
    parser.add_argument("--database", "-db", help="Path to SQLite database (defaults to libs/record_thing/record-thing.sqlite)")
    parser.add_argument("--import-file", "-i", help="Import translations from file (can be relative to repo root if starts with 'apps/' or 'libs/')")
    parser.add_argument("--language", "-l", default="en", choices=["en", "da", "ru"], help="Language for import/export")
    parser.add_argument("--export-file", "-e", help="Export translations to file (can be relative to repo root if starts with 'apps/' or 'libs/')")
    parser.add_argument("--missing-only", "-m", action="store_true", help="Export only missing translations")
    parser.add_argument("--export-strings", "-s", help="Export to Swift .strings file in directory (can be relative to repo root if starts with 'apps/' or 'libs/')")
    parser.add_argument("--update-code", "-u", help="Directory to update Swift code (can be relative to repo root if starts with 'apps/' or 'libs/')")
    parser.add_argument("--dry-run", "-d", action="store_true", help="Don't actually modify files")
    parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose logging")
    
    args = parser.parse_args()
    
    # Set logging level based on verbose flag
    if args.verbose:
        logging.getLogger("update_translations").setLevel(logging.DEBUG)
    
    try:
        # Run updater
        updater = TranslationUpdater(db_path=args.database)
        try:
            # Import translations if requested
            if args.import_file:
                import_path = resolve_path(args.import_file)
                logger.info(f"Importing translations from {import_path}")
                updater.import_translations_from_file(str(import_path), args.language)
            
            # Export translations if requested
            if args.export_file:
                export_path = resolve_path(args.export_file)
                logger.info(f"Exporting translations to {export_path}")
                updater.export_translations_to_file(str(export_path), args.language, args.missing_only)
            
            # Export Swift strings if requested
            if args.export_strings:
                strings_dir = resolve_directory(args.export_strings)
                logger.info(f"Exporting Swift strings to {strings_dir}")
                updater.export_swift_strings_file(str(strings_dir), args.language)
            
            # Update Swift code if requested
            if args.update_code:
                code_dir = resolve_directory(args.update_code)
                logger.info(f"Updating Swift code in {code_dir}")
                updater.process_directory(str(code_dir), True, args.dry_run)
        finally:
            updater.close()
        
        logger.info("Translation update complete")
        return 0
    except (FileNotFoundError, NotADirectoryError) as e:
        logger.error(f"Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())