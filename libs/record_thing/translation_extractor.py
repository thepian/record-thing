#!/usr/bin/env python3
"""
Translation extractor for Record Thing app.
Extracts translatable strings from Swift source files and generates translation keys
with appropriate namespaced prefixes.
"""

import os
import re
import sqlite3
from typing import Dict, List, Optional, Set, Tuple
import argparse
import logging
from pathlib import Path

from commons import resolve_path, resolve_directory, resolve_database_path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("translation_extractor")

class TranslationExtractor:
    """
    Extracts translatable strings from Swift source files and generates
    translation keys with appropriate namespaced prefixes.
    """
    
    # Common stop words to filter out for creating terse keys
    STOP_WORDS = {
        "a", "an", "the", "and", "or", "but", "is", "are", "was", "were", 
        "has", "have", "had", "will", "would", "shall", "should", "may", 
        "might", "can", "could", "of", "for", "in", "on", "at", "to", "by", 
        "with", "from", "about", "into", "through", "after", "before", "above",
        "below", "between", "under", "over", "this", "that", "these", "those",
        "do", "does", "did", "as"
    }
    
    def __init__(self, db_path: str = None):
        """
        Initialize the translation extractor.
        
        Args:
            db_path: Path to the SQLite database (defaults to repo's record-thing.sqlite)
        """
        self.db_path = str(resolve_database_path(db_path))
        self.conn = None
        self.existing_keys = set()
        self.existing_translations = {}
        self.namespace_counters = {}
        
    def connect_db(self):
        """
        Connect to the SQLite database and load existing translation keys.
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
                logger.info("Translations table doesn't exist. Creating it.")
                cursor.execute("""
                    CREATE TABLE translations (
                        id TEXT PRIMARY KEY,
                        text TEXT NOT NULL,
                        en TEXT,
                        da TEXT,
                        ru TEXT,
                        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                self.conn.commit()
            
            # Load existing keys
            cursor.execute("SELECT id, text, en FROM translations")
            for row in cursor.fetchall():
                key, text, translation = row
                self.existing_keys.add(key)
                self.existing_translations[text] = (key, translation)
                
                # Track namespace counters for ensuring unique keys
                prefix = key.split('.')[0] if '.' in key else key
                if prefix not in self.namespace_counters:
                    self.namespace_counters[prefix] = 0
                self.namespace_counters[prefix] += 1
                
            logger.info(f"Loaded {len(self.existing_keys)} existing translation keys")
            
        except sqlite3.Error as e:
            logger.error(f"Database error: {e}")
            raise
    
    def determine_prefix(self, file_path: str, text: str, line_content: str = "", component_type: str = "") -> str:
        """
        Determine the appropriate prefix for a translation key based on context.
        
        Args:
            file_path: Path to the source file
            text: The string being translated
            line_content: The line of code containing the string
            component_type: UI component type if known (Button, Text, etc.)
            
        Returns:
            A terse but meaningful prefix ending with "." (e.g., "act.", "nav.")
        """
        # Default prefix if we can't determine a more specific one
        default_prefix = "ui."
        
        # Extract file name and directory from path
        file_name = os.path.basename(file_path) if file_path else ""
        dir_name = os.path.basename(os.path.dirname(file_path)) if file_path else ""
        
        # Convert to lowercase for easier matching
        text_lower = text.lower()
        line_lower = line_content.lower() if line_content else ""
        file_lower = file_name.lower()
        dir_lower = dir_name.lower()
        
        # Check for common patterns in the component type
        if component_type:
            comp_lower = component_type.lower()
            if "button" in comp_lower:
                return "act."  # Actions (buttons, interactive elements)
            elif "navigationtitle" in comp_lower or "title" in comp_lower:
                return "nav."  # Navigation titles
            elif "label" in comp_lower:
                return "lbl."  # Labels
        
        # Check for patterns in the line content
        if line_content:
            if "button" in line_lower or "action" in line_lower:
                return "act."  # Action buttons
            elif "alert" in line_lower or "error" in line_lower:
                return "alrt."  # Alerts and errors
            elif "title" in line_lower:
                if "navigation" in line_lower:
                    return "nav."  # Navigation titles
                return "ttl."  # Generic titles
            elif "header" in line_lower or "section" in line_lower:
                return "sect."  # Section headers
            elif "placeholder" in line_lower:
                return "plh."  # Placeholders
            elif "tooltip" in line_lower or "hint" in line_lower:
                return "tip."  # Tooltips and hints
        
        # Check for patterns in the directory name
        if dir_name:
            if "settings" in dir_lower:
                return "set."  # Settings-related strings
            elif "navigation" in dir_lower:
                return "nav."  # Navigation-related strings
            elif "evidence" in dir_lower:
                return "ev."  # Evidence-related strings
            elif "database" in dir_lower:
                return "db."  # Database-related strings
            elif "model" in dir_lower:
                return "mdl."  # Model-related strings
            elif "component" in dir_lower:
                return "cmp."  # UI Component strings
            elif "debug" in dir_lower:
                return "dbg."  # Debug-related strings
            elif "shareextension" in dir_lower:
                return "shr."  # Share extension strings
        
        # Check for patterns in the file name
        if file_name:
            if "view" in file_lower:
                if "settingsview" in file_lower:
                    return "set."  # Settings view
                elif "detailview" in file_lower:
                    return "dtl."  # Detail view
                elif "actionview" in file_lower or "actionsview" in file_lower:
                    return "act."  # Actions view
                elif "evidenceview" in file_lower or "evidencetypeview" in file_lower:
                    return "ev."  # Evidence view
                elif "shareextensionview" in file_lower:
                    return "shr."  # Share extension view
                return "view."  # Generic view
            elif "row" in file_lower:
                return "row."  # Row-related strings
            elif "list" in file_lower:
                return "lst."  # List-related strings
            elif "menu" in file_lower:
                return "mnu."  # Menu-related strings
            elif "model" in file_lower:
                return "mdl."  # Model-related strings
            elif "service" in file_lower:
                return "svc."  # Service-related strings
        
        # Check for patterns in the text content
        if text:
            # Look for common text patterns
            if any(word in text_lower for word in ["error", "failed", "invalid", "cannot"]):
                return "err."  # Error messages
            elif any(word in text_lower for word in ["success", "completed", "done"]):
                return "succ."  # Success messages
            elif any(word in text_lower for word in ["confirm", "agree", "accept", "terms"]):
                return "agr."  # Agreement/confirmation texts
            elif any(word in text_lower for word in ["wait", "loading", "processing"]):
                return "load."  # Loading/waiting messages
            elif len(text.split()) >= 10 or len(text) > 100:
                return "msg."  # Longer messages or paragraphs
        
        # If we couldn't determine a specific prefix, return the default
        return default_prefix
    
    def generate_translation_key(self, text: str, context: str = "", line_content: str = "", file_path: str = "") -> str:
        """
        Generate a terse, namespace-prefixed translation key from text.
        
        Args:
            text: The string to create a key for
            context: Additional context about the string
            line_content: The line of code containing the string
            file_path: Path to the source file
            
        Returns:
            A unique translation key in the format "prefix.key_words"
        """
        # Get namespace prefix (already includes trailing period)
        prefix = self.determine_prefix(file_path, text, line_content)
        
        # Clean up the text to create the key suffix
        # Remove any leading/trailing whitespace and quotes
        clean_text = text.strip().strip('"\'')
        
        # Replace special characters with spaces
        clean_text = re.sub(r'[^\w\s]', ' ', clean_text)
        
        # Split into words and filter out stop words
        words = clean_text.lower().split()
        significant_words = [word for word in words if word not in self.STOP_WORDS and len(word) > 1]
        
        # If no significant words remain, use the first few original words
        if not significant_words and words:
            significant_words = words[:3]
        
        # Limit to first 4 significant words for terseness
        significant_words = significant_words[:4]
        
        # Join with underscores for duck casing
        key_suffix = "_".join(significant_words)
        
        # Combine with namespace prefix (prefix already includes period)
        key = f"{prefix}{key_suffix}"
        
        # Ensure key is unique within namespace
        if key in self.existing_keys:
            # Get namespace prefix without the trailing period
            namespace = prefix[:-1]
            
            # Increment counter for this namespace
            if namespace not in self.namespace_counters:
                self.namespace_counters[namespace] = 0
            self.namespace_counters[namespace] += 1
            
            # Add counter to make key unique
            key = f"{prefix}{key_suffix}_{self.namespace_counters[namespace]}"
        
        return key
    
    def extract_strings_from_file(self, file_path: str) -> List[Tuple[str, str]]:
        """
        Extract translatable strings from a Swift source file.
        
        Args:
            file_path: Path to the Swift source file
            
        Returns:
            List of tuples containing (string, context)
        """
        strings = []
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.readlines()
                
            # Process file line by line to maintain context
            for i, line in enumerate(content):
                # Skip comments
                if line.strip().startswith("//"):
                    continue
                
                # Find quoted strings that are likely to be user-facing
                # This regex matches both double-quoted and triple-quoted strings
                # but avoids matching code like String(format: "%d items")
                matches = re.finditer(r'(?<![a-zA-Z0-9_])(?:"([^"\\]*(?:\\.[^"\\]*)*)")', line)
                
                for match in matches:
                    # Get the full quoted string and remove the quotes
                    string = match.group(1)
                    
                    # Skip empty strings or strings that are likely not translatable
                    if not string or string.isdigit() or re.match(r'^%[dfsiu]$', string):
                        continue
                    
                    # Skip strings that look like formatters, keys, or identifiers
                    if '%' in string or string.startswith('$') or re.match(r'^[A-Za-z0-9_]+$', string):
                        continue
                    
                    # Get context from surrounding lines for better key generation
                    start_ctx = max(0, i - 1)
                    end_ctx = min(len(content), i + 2)
                    context = "".join(content[start_ctx:end_ctx])
                    
                    strings.append((string, context, line, file_path))
        
        except Exception as e:
            logger.error(f"Error extracting strings from {file_path}: {e}")
        
        return strings
    
    def save_translations(self, translations: List[Tuple[str, str, str]]):
        """
        Save extracted translations to the database.
        
        Args:
            translations: List of tuples containing (key, text, context)
        """
        if not self.conn:
            self.connect_db()
        
        try:
            cursor = self.conn.cursor()
            for key, text, _ in translations:
                # Check if this exact text already exists with a different key
                if text in self.existing_translations:
                    existing_key, _ = self.existing_translations[text]
                    logger.info(f"String '{text}' already exists with key '{existing_key}', skipping")
                    continue
                
                # Check if key already exists
                if key in self.existing_keys:
                    logger.info(f"Key '{key}' already exists, skipping")
                    continue
                
                # Insert new translation
                cursor.execute("""
                    INSERT INTO translations (id, text, en)
                    VALUES (?, ?, ?)
                """, (key, text, text))
                
                # Update our tracking sets
                self.existing_keys.add(key)
                self.existing_translations[text] = (key, text)
                
                logger.info(f"Added translation: {key} = '{text}'")
            
            self.conn.commit()
            logger.info(f"Saved {len(translations)} new translations to database")
            
        except sqlite3.Error as e:
            logger.error(f"Database error while saving translations: {e}")
            self.conn.rollback()
    
    def process_directory(self, directory: str, extensions: List[str] = ['.swift']):
        """
        Process all files in a directory (and subdirectories) to extract translatable strings.
        
        Args:
            directory: Directory to process
            extensions: List of file extensions to process
        """
        logger.info(f"Processing directory: {directory}")
        
        # Connect to database if not already connected
        if not self.conn:
            self.connect_db()
        
        all_translations = []
        
        # Walk through directory structure
        for root, _, files in os.walk(directory):
            for file in files:
                # Check if file has one of the target extensions
                if any(file.endswith(ext) for ext in extensions):
                    file_path = os.path.join(root, file)
                    logger.info(f"Processing file: {file_path}")
                    
                    # Extract strings from file
                    strings = self.extract_strings_from_file(file_path)
                    
                    # Generate translation keys
                    for string, context, line, path in strings:
                        key = self.generate_translation_key(string, context, line, path)
                        all_translations.append((key, string, context))
        
        # Save all translations to database
        self.save_translations(all_translations)
        logger.info(f"Processed {len(all_translations)} strings from {directory}")
    
    def close(self):
        """Close database connection."""
        if self.conn:
            self.conn.close()
            self.conn = None

def main():
    """Main entry point for the translation extractor script."""
    parser = argparse.ArgumentParser(description="Extract translatable strings from Swift source files")
    parser.add_argument("--directory", "-d", required=True, 
                      help="Directory to process (can be relative to repo root if starts with 'apps/' or 'libs/')")
    parser.add_argument("--database", "-db", 
                      help="Path to SQLite database (defaults to libs/record_thing/record-thing.sqlite)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose logging")
    parser.add_argument("--output", "-o", help="Output file for extracted strings (optional)")
    
    args = parser.parse_args()
    
    # Set logging level based on verbose flag
    if args.verbose:
        logging.getLogger("translation_extractor").setLevel(logging.DEBUG)
    
    try:
        # Resolve directory path
        directory_path = resolve_directory(args.directory)
        logger.info(f"Processing directory: {directory_path}")
        
        # Run extractor
        extractor = TranslationExtractor(db_path=args.database)
        try:
            extractor.process_directory(str(directory_path))
            
            # If output file specified, export extracted strings
            if args.output:
                output_path = resolve_path(args.output)
                logger.info(f"Exporting extracted strings to {output_path}")
                # TODO: Add export functionality if needed
        finally:
            extractor.close()
        
        logger.info("Translation extraction complete")
        
    except (FileNotFoundError, NotADirectoryError) as e:
        logger.error(f"Error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())