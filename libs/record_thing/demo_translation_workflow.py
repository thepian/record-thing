#!/usr/bin/env python3
"""
Demo translation workflow for Record Thing app.
Shows the complete workflow for extracting, updating, and using translations.
"""

import os
import argparse
import logging
import sqlite3
import tempfile
import shutil
import sys
from pathlib import Path

from translation_extractor import TranslationExtractor
from update_translations import TranslationUpdater
from commons import resolve_path, resolve_directory, resolve_database_path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("demo_translation_workflow")

def demo_workflow(swift_dir: str, output_dir: str, db_path: str = None, language: str = "da"):
    """
    Run through a complete translation workflow demonstration.
    
    Args:
        swift_dir: Directory containing Swift source files
        output_dir: Directory to output translation files
        db_path: Path to SQLite database (uses temporary if None)
        language: Language to demonstrate (default: da)
    """
    # Resolve paths
    swift_path = resolve_directory(swift_dir)
    output_path = resolve_path(output_dir)
    
    # Create output directory if it doesn't exist
    os.makedirs(output_path, exist_ok=True)
    
    # Use temporary database if not specified
    using_temp_db = False
    if not db_path:
        temp_dir = tempfile.mkdtemp()
        db_path = os.path.join(temp_dir, "demo-translations.sqlite")
        using_temp_db = True
    else:
        db_path = str(resolve_database_path(db_path))
    
    try:
        logger.info(f"=== DEMO TRANSLATION WORKFLOW ===")
        logger.info(f"Swift directory: {swift_dir}")
        logger.info(f"Output directory: {output_dir}")
        logger.info(f"Database path: {db_path}")
        logger.info(f"Target language: {language}")
        logger.info(f"============================")
        
        # Step 1: Extract translatable strings
        logger.info("\n\n=== STEP 1: Extract translatable strings ===")
        extractor = TranslationExtractor(db_path=db_path)
        extractor.process_directory(swift_dir)
        extractor.close()
        
        # Step 2: Export translations for translation
        logger.info("\n\n=== STEP 2: Export translations for translation ===")
        os.makedirs(output_dir, exist_ok=True)
        export_path = os.path.join(output_dir, f"translations_{language}.txt")
        
        updater = TranslationUpdater(db_path=db_path)
        updater.export_translations_to_file(export_path, language, missing_only=True)
        logger.info(f"Exported translations to {export_path}")
        
        # Step 3: Simulate translation by a translator
        logger.info("\n\n=== STEP 3: Simulate translation by translator ===")
        # Create a simplified translation for demo (just append language code)
        simulate_translation(export_path, language)
        logger.info(f"Simulated translation completed")
        
        # Step 4: Import translated strings
        logger.info("\n\n=== STEP 4: Import translated strings ===")
        updater.import_translations_from_file(export_path, language)
        
        # Step 5: Generate Swift .strings files
        logger.info("\n\n=== STEP 5: Generate Swift .strings files ===")
        updater.export_swift_strings_file(output_dir, "en")
        updater.export_swift_strings_file(output_dir, language)
        
        # Step 6: Update Swift code to use translation keys
        logger.info("\n\n=== STEP 6: Update Swift code to use translation keys ===")
        # Create a copy of the Swift directory to show before/after
        swift_copy_dir = os.path.join(output_dir, "swift_with_keys")
        shutil.copytree(swift_dir, swift_copy_dir, dirs_exist_ok=True)
        
        updater.process_directory(swift_copy_dir, update_code=True)
        updater.close()
        
        logger.info(f"\n\n=== DEMO COMPLETED SUCCESSFULLY ===")
        logger.info(f"You can find the results in: {output_dir}")
        logger.info(f"Original Swift code: {swift_dir}")
        logger.info(f"Updated Swift code with translation keys: {swift_copy_dir}")
        logger.info(f"Generated .strings files in: {output_dir}/{language}.lproj/")
        
    except Exception as e:
        logger.error(f"Error in demo workflow: {e}", exc_info=True)
    finally:
        # Clean up temporary database if created
        if using_temp_db:
            try:
                os.remove(db_path)
                os.rmdir(temp_dir)
            except:
                pass

def simulate_translation(file_path: str, language: str):
    """
    Simulate translation by modifying the export file.
    For demo purposes, we'll just append the language code to each string.
    
    Args:
        file_path: Path to the exported translation file
        language: Target language code
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    with open(file_path, 'w', encoding='utf-8') as f:
        for line in lines:
            line = line.strip()
            # Skip comments and empty lines
            if not line or line.startswith('#'):
                f.write(line + '\n')
                continue
            
            # Process key=translation lines
            if '=' in line:
                key, translation = line.split('=', 1)
                # If translation is empty, create a simulated one
                if not translation.strip():
                    # Get English text from comments above (if any)
                    english_text = ""
                    for i in range(len(lines)):
                        if lines[i].strip() == line:
                            # Look for "# English: " comment above
                            for j in range(i-1, max(0, i-5), -1):
                                if "# English:" in lines[j]:
                                    english_text = lines[j].split("# English:", 1)[1].strip()
                                    break
                                elif "# Original:" in lines[j]:
                                    english_text = lines[j].split("# Original:", 1)[1].strip()
                                    break
                            break
                    
                    if english_text:
                        # Create "translation" by adding language marker
                        if language == "da":
                            translation = f"{english_text} [på dansk]"
                        elif language == "ru":
                            translation = f"{english_text} [на русском]"
                        else:
                            translation = f"{english_text} [{language}]"
                
                f.write(f"{key.strip()}={translation}\n")
            else:
                f.write(line + '\n')

def create_sample_swift_file(output_dir: str):
    """
    Create a sample Swift file for testing the translation workflow.
    
    Args:
        output_dir: Directory to create the sample file
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Create a sample Swift file
    sample_file = os.path.join(output_dir, "ActionsView.swift")
    
    with open(sample_file, 'w', encoding='utf-8') as f:
        f.write("""
import SwiftUI

struct ActionsView: View {
    @State private var showingAlert = false
    
    var body: some View {
        VStack {
            Text("Available Actions")
                .font(.headline)
            
            Button("Save Settings") {
                // Save settings action
            }
            .padding()
            
            Button("Delete Account") {
                showingAlert = true
            }
            .foregroundColor(.red)
            .padding()
            
            Text("These actions will affect your account settings.")
                .font(.caption)
                .padding()
        }
        .alert("Confirm Deletion", isPresented: $showingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .navigationTitle("Account Settings")
    }
}
""")
    
    return sample_file

def main():
    """Main entry point for the demo translation workflow script."""
    parser = argparse.ArgumentParser(description="Demo the translation workflow")
    parser.add_argument("--swift-dir", "-s", 
                      help="Directory containing Swift source files (can be relative to repo root if starts with 'apps/' or 'libs/')")
    parser.add_argument("--output-dir", "-o", default="libs/record_thing/translation_demo_output", 
                      help="Directory to output translation files (can be relative to repo root if starts with 'apps/' or 'libs/')")
    parser.add_argument("--database", "-db", 
                      help="Path to SQLite database (uses temporary if not specified)")
    parser.add_argument("--language", "-l", default="da", choices=["en", "da", "ru"], help="Target language")
    parser.add_argument("--create-sample", "-c", action="store_true", help="Create a sample Swift file for testing")
    
    args = parser.parse_args()
    
    try:
        # Create sample Swift file if requested or if no Swift directory specified
        if args.create_sample or not args.swift_dir:
            output_path = resolve_path(args.output_dir)
            os.makedirs(output_path, exist_ok=True)
            sample_dir = os.path.join(str(output_path), "sample_swift")
            sample_file = create_sample_swift_file(sample_dir)
            logger.info(f"Created sample Swift file: {sample_file}")
            args.swift_dir = sample_dir
        
        # Run the demo workflow
        demo_workflow(args.swift_dir, args.output_dir, args.database, args.language)
        return 0
    except (FileNotFoundError, NotADirectoryError) as e:
        logger.error(f"Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())