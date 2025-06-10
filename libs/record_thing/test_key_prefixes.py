#!/usr/bin/env python3
"""
Test key prefix generation for the translation system.
This script demonstrates how the translation extractor determines
the appropriate prefix for different types of strings.
"""

import os
import sys
from translation_extractor import TranslationExtractor

def test_key_prefixes():
    """Test the generation of prefixed translation keys."""
    extractor = TranslationExtractor()
    
    # Sample string data for testing
    test_cases = [
        {
            "description": "Action button",
            "text": "Save Changes",
            "file_path": "/apps/RecordThing/Shared/Settings/SettingsView.swift",
            "line_content": "Button(\"Save Changes\") { saveSettings() }",
            "component_type": "Button"
        },
        {
            "description": "Section header",
            "text": "Account Settings",
            "file_path": "/apps/RecordThing/Shared/Settings/SettingsView.swift",
            "line_content": "Section { /* content */ } header: { Text(\"Account Settings\") }",
            "component_type": "Text"
        },
        {
            "description": "Navigation title",
            "text": "Evidence Details",
            "file_path": "/apps/RecordThing/Shared/Evidence/EvidenceDetailView.swift",
            "line_content": ".navigationTitle(\"Evidence Details\")",
            "component_type": "NavigationTitle"
        },
        {
            "description": "Agreement text",
            "text": "Terms of Service",
            "file_path": "/apps/RecordThing/Shared/Legal/AgreementsView.swift",
            "line_content": "Text(\"Terms of Service\")",
            "component_type": "Text"
        },
        {
            "description": "Account related",
            "text": "Profile Information",
            "file_path": "/apps/RecordThing/Shared/Account/ProfileView.swift",
            "line_content": "Text(\"Profile Information\")",
            "component_type": "Text"
        },
        {
            "description": "Team related",
            "text": "Manage Team Members",
            "file_path": "/apps/RecordThing/Shared/Team/TeamManagementView.swift",
            "line_content": "Text(\"Manage Team Members\")",
            "component_type": "Text"
        },
        {
            "description": "Status label",
            "text": "Completed",
            "file_path": "/apps/RecordThing/Shared/Evidence/EvidenceRow.swift",
            "line_content": "Text(\"Completed\").foregroundColor(.green)",
            "component_type": "Text"
        },
        {
            "description": "Accessibility label",
            "text": "Close Settings",
            "file_path": "/apps/RecordThing/Shared/Settings/SettingsView.swift",
            "line_content": "Button(action: { dismiss() }) { Image(systemName: \"xmark\") }.accessibilityLabel(\"Close Settings\")",
            "component_type": "AccessibilityLabel"
        },
        {
            "description": "Error message",
            "text": "Failed to save changes",
            "file_path": "/apps/RecordThing/Shared/Settings/SettingsView.swift",
            "line_content": "Text(\"Failed to save changes\").foregroundColor(.red)",
            "component_type": "Text"
        },
        {
            "description": "Database operation",
            "text": "Syncing database",
            "file_path": "/apps/RecordThing/Shared/Database/DatabaseSyncView.swift",
            "line_content": "Text(\"Syncing database\")",
            "component_type": "Text"
        },
        {
            "description": "Placeholder",
            "text": "Enter your email",
            "file_path": "/apps/RecordThing/Shared/Account/LoginView.swift",
            "line_content": "TextField(\"Enter your email\", text: $email)",
            "component_type": "TextField"
        },
        {
            "description": "Alert message",
            "text": "Confirm Deletion",
            "file_path": "/apps/RecordThing/Shared/Evidence/EvidenceDetailView.swift",
            "line_content": ".alert(\"Confirm Deletion\", isPresented: $showingAlert) {",
            "component_type": "Alert"
        },
        {
            "description": "Tooltip",
            "text": "Tap to add evidence",
            "file_path": "/apps/RecordThing/Shared/Evidence/EvidenceListView.swift",
            "line_content": "Button(action: { addEvidence() }) { Image(systemName: \"plus\") }.tooltip(\"Tap to add evidence\")",
            "component_type": "Tooltip"
        },
        {
            "description": "Loading message",
            "text": "Loading evidence data...",
            "file_path": "/apps/RecordThing/Shared/Evidence/EvidenceListView.swift",
            "line_content": "ProgressView(\"Loading evidence data...\")",
            "component_type": "ProgressView"
        }
    ]
    
    # Test each case and print results
    print("\n=== Translation Key Prefix Tests ===\n")
    print(f"{'Description':<20} {'Text':<30} {'Generated Key':<40}\n{'-'*90}")
    
    for case in test_cases:
        # Determine prefix first
        prefix = extractor.determine_prefix(
            file_path=case["file_path"],
            text=case["text"],
            line_content=case["line_content"],
            component_type=case.get("component_type", "")
        )
        
        # Generate full translation key
        key = extractor.generate_translation_key(
            text=case["text"],
            context="",
            line_content=case["line_content"],
            file_path=case["file_path"]
        )
        
        print(f"{case['description']:<20} {case['text']:<30} {key:<40}")

def test_with_tabulate():
    """Test the prefix determination with tabulate for better formatting."""
    try:
        from tabulate import tabulate
    except ImportError:
        print("The tabulate package is required for this test format.")
        print("Install it with: pip install tabulate")
        print("Falling back to basic format.")
        test_key_prefixes()
        return
    
    extractor = TranslationExtractor()
    
    # Sample string data for testing
    test_cases = [
        {
            "description": "Action button",
            "text": "Save Changes",
            "file_path": "/apps/RecordThing/Shared/Settings/SettingsView.swift",
            "line_content": "Button(\"Save Changes\") { saveSettings() }",
            "component_type": "Button",
            "expected_prefix": "act."
        },
        {
            "description": "Section header",
            "text": "Account Settings",
            "file_path": "/apps/RecordThing/Shared/Settings/SettingsView.swift",
            "line_content": "Section { /* content */ } header: { Text(\"Account Settings\") }",
            "component_type": "Text",
            "expected_prefix": "sect."
        },
        {
            "description": "Navigation title",
            "text": "Evidence Details",
            "file_path": "/apps/RecordThing/Shared/Evidence/EvidenceDetailView.swift",
            "line_content": ".navigationTitle(\"Evidence Details\")",
            "component_type": "NavigationTitle",
            "expected_prefix": "nav."
        },
        {
            "description": "Agreement text",
            "text": "Terms of Service",
            "file_path": "/apps/RecordThing/Shared/Legal/AgreementsView.swift",
            "line_content": "Text(\"Terms of Service\")",
            "component_type": "Text",
            "expected_prefix": "agr."
        }
    ]
    
    results = []
    
    # Test each case
    for case in test_cases:
        actual_prefix = extractor.determine_prefix(
            file_path=case["file_path"],
            text=case["text"],
            line_content=case["line_content"],
            component_type=case.get("component_type", "")
        )
        
        key = extractor.generate_translation_key(
            text=case["text"],
            context="",
            line_content=case["line_content"],
            file_path=case["file_path"]
        )
        
        results.append([
            case["description"],
            case["text"],
            key,
            actual_prefix,
            case["expected_prefix"],
            "✅" if actual_prefix == case["expected_prefix"] else "❌"
        ])
    
    # Print results
    headers = ["Context", "Text", "Generated Key", "Actual Prefix", "Expected Prefix", "Result"]
    print("\n=== Translation Key Prefix Tests with Tabulate ===\n")
    print(tabulate(results, headers=headers, tablefmt="grid"))
    
    # Calculate success rate
    success_count = sum(1 for r in results if r[5] == "✅")
    print(f"\nSuccess rate: {success_count}/{len(results)} = {success_count/len(results)*100:.1f}%\n")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--tabulate":
        test_with_tabulate()
    else:
        test_key_prefixes()