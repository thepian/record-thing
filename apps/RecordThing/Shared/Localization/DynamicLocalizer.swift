import Foundation

class DynamicLocalizer {
    static let shared = DynamicLocalizer()
    private var translations: [String: [String: String]] = [:]
    
    func registerTranslations(from database: Blackbird.Database) async {
        do {
            // Fetch translations directly from translations table
            let rows = try await database.query("""
                SELECT lang, key, value 
                FROM translations
                ORDER BY lang, key
            """)
            
            // Group by language
            for row in rows {
                let lang = row["lang"] as? String ?? "en"
                let key = row["key"] as? String ?? ""
                let value = row["value"] as? String ?? key
                
                if translations[lang] == nil {
                    translations[lang] = [:]
                }
                translations[lang]?[key] = value
            }
            
            // Register with Bundle
            for (lang, dict) in translations {
                Bundle.main.localizations.append(lang)
                Bundle.main.setLocalizationDictionary(dict, for: lang)
            }
            
        } catch {
            print("Error loading translations: \(error)")
        }
    }
    
    func translate(_ key: String, locale: Locale = .current) -> String {
        let lang = locale.languageCode ?? "en"
        return translations[lang]?[key] ?? key
    }
}

extension Bundle {
    func setLocalizationDictionary(_ dictionary: [String: String], for language: String) {
        if var dict = self.localizedInfoDictionary as? [String: Any] {
            dict[language] = dictionary
            self.localizedInfoDictionary = dict
        } else {
            self.localizedInfoDictionary = [language: dictionary]
        }
    }
} 