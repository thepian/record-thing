//
//  DynamicLocalizer.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 09.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import Blackbird
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.thepia.RecordThing",
    category: "App"
)

class DynamicLocalizer {
    static let shared = DynamicLocalizer()
    private var translations: [String: [String: String]] = [:]
    
    func registerTranslations(from database: Blackbird.Database) async {
        do {
            // Fetch translations from SQLite
            let rows = try await database.query("""
                SELECT lang, key, value 
                FROM translations
                ORDER BY lang, key
            """)
            
            // Group by language
            for row in rows {
                let lang = row["lang"]?.stringValue ?? "en"
                let key = row["key"]?.stringValue ?? ""
                let value = row["value"]?.stringValue ?? key
                
                if translations[lang] == nil {
                    translations[lang] = [:]
                }
                translations[lang]?[key] = value
            }
            
            // Enable custom localization
            Bundle.enableCustomLocalization()
            
            // Register with Bundle
            for (lang, dict) in translations {
                
                // Add custom translations
                for (key, value) in dict {
                    Bundle.addCustomTranslation(language: lang, key: key, value: value)
                }

//                Bundle.main.localizations.append(lang)
//                Bundle.main.setLocalizationDictionary(dict, for: lang)
//                Bundle.main.set
            }
            logger.info("Loaded translations from Database.")
        } catch {
            logger.error("Error loading translations: \(error)")
        }
    }
    
    func translate(_ key: String, locale: Locale = .current) -> String {
        let lang = locale.language.languageCode?.identifier ?? "en"
        return translations[lang]?[key] ?? key
    }
}

private var customTranslations: [String: [String: String]] = [:]

extension Bundle {
    /// Swizzle the `localizedString(forKey:value:table:)` method
    static func enableCustomLocalization() {
        guard let originalMethod = class_getInstanceMethod(Bundle.self, #selector(localizedString(forKey:value:table:))),
              let swizzledMethod = class_getInstanceMethod(Bundle.self, #selector(custom_localizedString(forKey:value:table:))) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    /// Override localization lookup to provide custom translations
    @objc func custom_localizedString(forKey key: String, value: String?, table: String?) -> String {
        let language = Locale.preferredLanguages.first ?? "en"
        
        if let translation = customTranslations[language]?[key] {
            return translation
        }
        
        // Fallback to default behavior
        return custom_localizedString(forKey: key, value: value, table: table)
    }
    
    /// Add a new translation for a specific language
    static func addCustomTranslation(language: String, key: String, value: String) {
        if customTranslations[language] == nil {
            customTranslations[language] = [:]
        }
        customTranslations[language]?[key] = value
    }
    
    
//    func setLocalizationDictionary(_ dictionary: [String: String], for language: String) {
//        if var dict = self.localizedInfoDictionary as? [String: Any] {
//            dict[language] = dictionary
//            self.localizedInfoDictionary = dict
//        } else {
//            self.localizedInfoDictionary = [language: dictionary]
//        }
//    }
}
