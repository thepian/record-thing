# RecordThing Translation Management

This directory contains tools for managing translations in the RecordThing app.

## Overview

The translation system uses:
- **SQLite database** (`record-thing.sqlite`) to store all translations
- **Translation keys** defined in Swift code (`TranslationKeys`)
- **Extraction tools** to find hardcoded strings that need translation
- **Update scripts** to add new translations to the database

## Files

- `record-thing.sqlite` - Main translation database
- `translation_extractor.py` - Tool to scan Swift code for hardcoded strings
- `update_translations.py` - Script to add new translations to database
- `README_TRANSLATIONS.md` - This documentation

## Usage

### 1. Adding New Translations Manually

```bash
# Run the update script to add predefined translations
python update_translations.py
```

### 2. Scanning for Hardcoded Strings

```bash
# Scan the entire app for hardcoded strings
python translation_extractor.py --scan ../../apps --output suggestions.json

# Scan and automatically update database
python translation_extractor.py --scan ../../apps --update-db record-thing.sqlite --copy-to-resources

# Include debug interfaces in scan
python translation_extractor.py --scan ../../apps --debug-only --output debug_suggestions.json
```

### 3. Updating App Resources

After updating the database, copy it to the app resources:

```bash
cp record-thing.sqlite ../../apps/RecordThing/Shared/Resources/default-record-thing.sqlite
```

## Translation Key Structure

Translation keys follow a hierarchical structure:

```
category.subcategory.specific_item

Examples:
- database.actions
- database.statistics.errors
- settings.account.name
- ui.button.save
```

## Adding New Translation Keys

1. **Define the key** in `apps/libs/RecordLib/Sources/RecordLib/Translation/SwiftUI+Translation.swift`:
   ```swift
   public static let myNewKey = "category.my_new_key"
   ```

2. **Add translation** to `update_translations.py`:
   ```python
   ("en", "category.my_new_key", "My New Text", "category"),
   ```

3. **Use in Swift code**:
   ```swift
   Text(dbKey: TranslationKeys.myNewKey)
   ```

4. **Run update script**:
   ```bash
   python update_translations.py
   ```

## Debug vs Production Interfaces

- **Debug interfaces** (marked with comments) can use hardcoded English strings
- **Production interfaces** must use translation keys
- The extractor tool can filter debug interfaces with `--debug-only`

## Translation Context Categories

- `ui` - General user interface elements
- `database` - Database-related interfaces
- `settings` - Settings and preferences
- `error` - Error messages
- `navigation` - Navigation elements
- `premium` - Premium/upgrade features
- `demo` - Demo mode features

## Workflow for Adding Translations

1. **Scan for hardcoded strings**:
   ```bash
   python translation_extractor.py --scan ../../apps --output new_strings.json
   ```

2. **Review suggestions** in `new_strings.json`

3. **Add approved translations** to `update_translations.py`

4. **Update database**:
   ```bash
   python update_translations.py
   ```

5. **Test in app** to verify translations work

6. **Commit changes** to both database and Swift code

## Future Enhancements

- Support for multiple languages (currently English only)
- Integration with cloud translation services
- Automated scanning in CI/CD pipeline
- Translation validation tools
