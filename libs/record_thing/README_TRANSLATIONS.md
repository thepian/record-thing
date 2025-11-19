# RecordThing Translation Management

This directory contains tools for managing translations in the RecordThing app.

> **Note:** All scripts now handle paths relative to the repository root automatically. You can run scripts from any directory, and paths starting with `apps/` or `libs/` will be resolved relative to the repository root. Absolute paths are also supported.

## Overview

The translation system uses:
- **SQLite database** (`record-thing.sqlite`) to store all translations
- **Translation keys** defined in Swift code (`TranslationKeys`)
- **Extraction tools** to find hardcoded strings that need translation
- **Update scripts** to add new translations to the database
- **Validation tools** to ensure translations are complete and correct

## Files

- `record-thing.sqlite` - Main translation database
- `translation_manager.py` - Comprehensive tool for translation management
- `translation_extractor.py` - Tool to scan Swift code for hardcoded strings
- `update_translations.py` - Script to add new translations to database
- `demo_translation_workflow.py` - Demonstrates the translation workflow
- `commons.py` - Common utilities, including path resolution relative to repository root
- `README_TRANSLATIONS.md` - This documentation

## Translation Key Structure

Translation keys follow a terse, namespace-prefixed structure:

```
prefix.concise_descriptive_words
```

Examples:
- `act.save_settings` (action-related: Save Settings button)
- `nav.account_settings` (navigation-related: Account settings title)
- `err.connection_failed` (error message: Connection failed)

### Namespace Prefixes

The system intelligently determines the appropriate namespace prefix based on context:

| Prefix    | Description                                | Example                    |
|-----------|--------------------------------------------|----------------------------|
| `act.`    | Actions (buttons, interactive elements)    | `act.save_settings`        |
| `nav.`    | Navigation titles and related strings      | `nav.evidence_details`     |
| `ttl.`    | Titles (not navigation-related)            | `ttl.welcome_screen`       |
| `sect.`   | Section headers                            | `sect.account_info`        |
| `err.`    | Error messages                             | `err.invalid_credentials`  |
| `alrt.`   | Alerts and warnings                        | `alrt.delete_confirmation` |
| `succ.`   | Success messages                           | `succ.changes_saved`       |
| `msg.`    | General messages and paragraphs            | `msg.intro_text`           |
| `lbl.`    | Labels                                     | `lbl.username`             |
| `plh.`    | Placeholders                               | `plh.enter_email`          |
| `tip.`    | Tooltips and hints                         | `tip.password_requirements`|
| `set.`    | Settings-related strings                   | `set.language_preference`  |
| `ev.`     | Evidence-related strings                   | `ev.capture_receipt`       |
| `db.`     | Database-related strings                   | `db.connection_failed`     |
| `agr.`    | Agreement/confirmation texts               | `agr.terms_service`        |
| `load.`   | Loading/waiting messages                   | `load.processing_data`     |
| `acc.`    | Account and profile related                | `acc.edit_account`         |
| `team.`   | Team management related                    | `team.invite_member`       |
| `stat.`   | Status indicators, state descriptions      | `stat.processing`          |
| `a11y.`   | Accessibility labels                       | `a11y.close_button`        |
| `ui.`     | General UI strings (default)               | `ui.cancel`                |

## Extracting and Saving Translations

### Using the Translation Extractor

To extract strings from Swift code and save to the database:

```bash
# You can run these scripts from any directory
# The scripts automatically resolve paths relative to the repository root

# Extract from the main app
python libs/record_thing/translation_extractor.py --directory apps/RecordThing/Shared

# Extract from RecordLib package
python libs/record_thing/translation_extractor.py --directory apps/libs/RecordLib/Sources

# Specify a different database path (optional)
python libs/record_thing/translation_extractor.py --directory apps/RecordThing/Shared --database path/to/my-database.sqlite
```

The database path defaults to `libs/record_thing/record-thing.sqlite` in the repository.

### Using the Translation Manager

The translation manager combines multiple functionalities:

```bash
# You can run these scripts from any directory
# The scripts automatically resolve paths relative to the repository root

# Extract strings and output to JSON
python libs/record_thing/translation_manager.py extract --source apps/RecordThing/Shared --output libs/record_thing/strings.json

# Extract and update database in one step
python libs/record_thing/translation_manager.py extract --source apps/RecordThing/Shared

# Include debug interfaces
python libs/record_thing/translation_manager.py extract --source apps/RecordThing/Shared --debug-only

# Modify Swift code to use translation keys
python libs/record_thing/translation_manager.py extract --source apps/RecordThing/Shared --modify-code
```

## Managing Translations

### Update Database with Predefined Translations

```bash
# Update database with predefined translations
python libs/record_thing/translation_manager.py update

# Update and copy to app resources
python libs/record_thing/translation_manager.py update --copy-to-resources

# Generate reference-only translation keys file (optional)
python libs/record_thing/translation_manager.py update --generate-swift apps/RecordThing/Shared/Resources/TranslationKeys.swift
```

### Export/Import Translations

```bash
# Export to YAML (more human-readable)
python libs/record_thing/translation_manager.py export --format yaml --output libs/record_thing/translations.yaml

# Export to JSON
python libs/record_thing/translation_manager.py export --format json --output libs/record_thing/translations.json

# Import from YAML/JSON
python libs/record_thing/translation_manager.py import --input libs/record_thing/translations.yaml
```

### Verify Translations

```bash
# Check for missing or unused translations
python libs/record_thing/translation_manager.py verify --source apps/RecordThing

# Save verification results
python libs/record_thing/translation_manager.py verify --source apps/RecordThing --output libs/record_thing/verification.json
```

## Translation Context Categories

- `ui` - General user interface elements
- `database` - Database-related interfaces
- `settings` - Settings and preferences
- `error` - Error messages
- `navigation` - Navigation elements
- `evidence` - Evidence-related interfaces
- `premium` - Premium/upgrade features
- `demo` - Demo mode features

## Development vs. Production Views

The translation system distinguishes between development-only and production views:

1. **Development-Only Views**:
   - Annotate with `// @DEVELOPMENT_ONLY` in the first 20 lines of the file
   - Can use hardcoded strings (excluded from translation requirements)
   - Useful for debugging, monitoring, and internal tools

2. **Production Views**:
   - Must use translation keys for all user-facing strings
   - Can be validated using the verification tool

## Direct Tools Usage

For more granular control, you can use the specific tools directly:

### 1. Translation Extractor (`translation_extractor.py`)

This tool extracts translatable strings from Swift source files and generates appropriate translation keys.

```bash
python libs/record_thing/translation_extractor.py --directory apps/RecordThing/Shared --verbose
```

Key features:
- Scans Swift files for translatable strings
- Intelligently determines namespace prefixes based on context
- Generates terse, meaningful translation keys
- Ensures keys are unique within namespaces
- Stores strings and keys in a SQLite database

### 2. Translation Updater (`update_translations.py`)

This tool manages translations and updates Swift code to use the translation framework.

```bash
# Export translations for Danish
python libs/record_thing/update_translations.py --export-file libs/record_thing/translations_da.txt --language da --missing-only

# Import translated strings
python libs/record_thing/update_translations.py --import-file libs/record_thing/translations_da.txt --language da

# Generate Swift .strings files
python libs/record_thing/update_translations.py --export-strings apps/RecordThing/Shared/Resources --language da

# Update Swift code to use translation keys
python libs/record_thing/update_translations.py --update-code apps/RecordThing/Shared --dry-run
```

### 3. Demo Workflow (`demo_translation_workflow.py`)

This script demonstrates the complete translation workflow from extraction to code update.

```bash
python libs/record_thing/demo_translation_workflow.py --swift-dir apps/RecordThing/Shared/Navigation --output-dir libs/record_thing/demo_output --language da
```

## Database Schema

The translations are stored in a SQLite database with the following schema:

```sql
CREATE TABLE translations (
    id TEXT PRIMARY KEY,           -- The translation key (e.g., "act.save_settings")
    text TEXT NOT NULL,            -- The original text
    en TEXT,                       -- English translation
    da TEXT,                       -- Danish translation
    ru TEXT,                       -- Russian translation
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
)
```

## Swift Integration

The Swift code uses a String extension for accessing translations:

```swift
extension String {
    var translated: String {
        NSLocalizedString(self, comment: "")
    }
}
```

This allows for a clean syntax in the code:

```swift
// Before
Text("Save Settings")

// After
Text("act.save_settings".translated)
```

## Complete Workflow for Adding Translations

1. **Extract strings** from source code:
   ```bash
   python libs/record_thing/translation_manager.py extract --source apps/RecordThing/Shared --output libs/record_thing/new_strings.json
   ```

2. **Review strings** in `new_strings.json`

3. **Update database** with approved translations:
   ```bash
   python libs/record_thing/translation_manager.py update
   ```

4. **Export to YAML** for version control:
   ```bash
   python libs/record_thing/translation_manager.py export --format yaml --output libs/record_thing/translations.yaml
   ```

5. **Generate Swift keys file**:
   ```bash
   python libs/record_thing/translation_manager.py update --generate-swift apps/RecordThing/Shared/Resources/TranslationKeys.swift
   ```

6. **Modify Swift code** to use translation keys:
   ```bash
   python libs/record_thing/translation_manager.py extract --source apps/RecordThing/Shared --modify-code
   ```

7. **Copy database** to app resources:
   ```bash
   python libs/record_thing/translation_manager.py update --copy-to-resources
   ```

8. **Test in app** to verify translations work

9. **Commit changes** to both database and Swift code

## Adding New Translation Keys Manually

1. **Add translation** to the database using one of these methods:
   
   a. Add to `update_translations.py`:
   ```python
   ("en", "act.my_new_key", "My New Text", "action"),
   ```
   
   b. Use the translation_manager.py directly:
   ```bash
   python libs/record_thing/translation_manager.py update
   ```

2. **Use in Swift code** with the String extension:
   ```swift
   Text("act.my_new_key".translated)
   ```
   
   Or with the Text extension:
   ```swift
   Text(translationKey: "act.my_new_key")
   ```

3. **Automatically update code**:
   ```bash
   python libs/record_thing/translation_manager.py update --source apps/RecordThing/Shared --modify-code
   ```
   This will replace hardcoded strings like `Text("My Text")` with `Text("act.my_text".translated)`

## Best Practices

1. **Run Translation Extraction Regularly**: As new strings are added to the codebase, run the extractor to keep the database up to date.

2. **Review Generated Keys**: Occasionally review the generated keys to ensure they follow the expected pattern and are meaningful.

3. **Update All Languages**: When adding new strings, make sure to update translations for all supported languages.

4. **Prefer Context-Rich Keys**: The system automatically generates context-aware keys, but you can improve them by providing clear context in your code.

5. **Keep Strings in Context**: Avoid splitting sentences across multiple translatable strings, as this can make translation difficult.

6. **Use Format Specifiers**: For strings with variables, use format specifiers rather than string concatenation:
   ```swift
   String(format: "act.found_items".translated, count)  // "Found %d items"
   ```

## Future Enhancements

- Integration with cloud translation services
- Automated scanning in CI/CD pipeline
- Enhanced validation tools
- Support for more languages