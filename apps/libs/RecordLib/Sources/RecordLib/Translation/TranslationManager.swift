import Foundation
import SQLite3
import os.log

/// TranslationManager provides read-only access to translation databases
/// independent of the main app database. Supports fallback strategies and
/// development mode for reading from source repository.
public class TranslationManager {

  // MARK: - Singleton

  public static let shared = TranslationManager()

  // MARK: - Private Properties

  private let logger = Logger(subsystem: "com.thepia.recordthing", category: "TranslationManager")
  private var translationDB: OpaquePointer?
  private var translationCache: [String: [String: String]] = [:]
  private let cacheQueue = DispatchQueue(label: "translation.cache", attributes: .concurrent)

  // MARK: - Public Properties

  /// Current language code (e.g., "en", "es", "fr")
  public var currentLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"

  /// Whether translation database is successfully loaded
  public var isLoaded: Bool {
    return translationDB != nil
  }

  // MARK: - Initialization

  private init() {
    loadTranslationDatabase()
  }

  deinit {
    closeDatabase()
  }

  // MARK: - Public Methods

  /// Get translation for a key in the current language
  /// - Parameter key: Translation key
  /// - Returns: Translated string or key if translation not found
  public func translate(_ key: String) -> String {
    return translate(key, language: currentLanguage)
  }

  /// Get translation for a key in a specific language
  /// - Parameters:
  ///   - key: Translation key
  ///   - language: Language code
  /// - Returns: Translated string or key if translation not found
  public func translate(_ key: String, language: String) -> String {
    // Check cache first
    if let cachedTranslation = getCachedTranslation(key: key, language: language) {
      return cachedTranslation
    }

    // Query database
    guard let translation = queryDatabase(key: key, language: language) else {
      logger.warning("Translation not found for key: \(key), language: \(language)")
      return key  // Fallback to key itself
    }

    // Cache the result
    setCachedTranslation(key: key, language: language, translation: translation)

    return translation
  }

  /// Reload translation database (useful when settings change)
  public func reloadDatabase() {
    closeDatabase()
    translationCache.removeAll()
    loadTranslationDatabase()
  }

  /// Check if translation exists for a key
  /// - Parameters:
  ///   - key: Translation key
  ///   - language: Language code (optional, uses current language if nil)
  /// - Returns: True if translation exists
  public func hasTranslation(for key: String, language: String? = nil) -> Bool {
    let lang = language ?? currentLanguage
    return queryDatabase(key: key, language: lang) != nil
  }

  // MARK: - Private Methods

  private func loadTranslationDatabase() {
    logger.info("Loading translation database...")

    // Try loading in priority order
    if loadFromDownloaded() {
      logger.info("Loaded translations from downloaded database")
      return
    }

    if loadFromBundle() {
      logger.info("Loaded translations from bundled database")
      return
    }

    if shouldUseSourceRepository() && loadFromSourceRepository() {
      logger.info("Loaded translations from source repository")
      return
    }

    logger.error("Failed to load any translation database")
  }

  private func loadFromDownloaded() -> Bool {
    // Try to load from Documents directory (downloaded translations)
    guard
      let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first
    else {
      return false
    }

    let downloadedDBURL = documentsURL.appendingPathComponent("translations.sqlite")
    return openDatabase(at: downloadedDBURL)
  }

  private func loadFromBundle() -> Bool {
    // Load from app bundle
    guard let bundleDBURL = Bundle.main.url(forResource: "translations", withExtension: "sqlite")
    else {
      logger.warning("Bundled translation database not found")
      return false
    }

    return openDatabase(at: bundleDBURL)
  }

  private func loadFromSourceRepository() -> Bool {
    // Load from source repository (development mode)
    // This would typically be a path to the checked-in SQLite file
    guard let sourceDBURL = getSourceRepositoryDatabaseURL() else {
      logger.warning("Source repository translation database not found")
      return false
    }

    return openDatabase(at: sourceDBURL)
  }

  private func shouldUseSourceRepository() -> Bool {
    // Check if the setting is enabled to use source repository translations
    let userDefaults = UserDefaults(suiteName: "group.com.thepia.recordthing") ?? .standard
    return userDefaults.bool(forKey: "rt.use_source_translations")
  }

  private func getSourceRepositoryDatabaseURL() -> URL? {
    // In development, this could point to a file in the source repository
    // For now, return nil as this would be configured based on development setup
    return nil
  }

  private func openDatabase(at url: URL) -> Bool {
    guard FileManager.default.fileExists(atPath: url.path) else {
      logger.warning("Translation database file does not exist: \(url.path)")
      return false
    }

    let result = sqlite3_open_v2(url.path, &translationDB, SQLITE_OPEN_READONLY, nil)

    if result == SQLITE_OK {
      logger.info("Successfully opened translation database: \(url.path)")
      return true
    } else {
      if let db = translationDB {
        logger.error(
          "Failed to open translation database: \(String(cString: sqlite3_errmsg(db)))")
      } else {
        logger.error("Failed to open translation database: Unknown error")
      }
      translationDB = nil
      return false
    }
  }

  private func closeDatabase() {
    if let db = translationDB {
      sqlite3_close(db)
      translationDB = nil
    }
  }

  private func queryDatabase(key: String, language: String) -> String? {
    guard let db = translationDB else {
      return nil
    }

    let query = "SELECT translation FROM translations WHERE key = ? AND language_code = ? LIMIT 1"
    var statement: OpaquePointer?

    defer {
      sqlite3_finalize(statement)
    }

    guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
      logger.error("Failed to prepare translation query")
      return nil
    }

    sqlite3_bind_text(statement, 1, key, -1, nil)
    sqlite3_bind_text(statement, 2, language, -1, nil)

    if sqlite3_step(statement) == SQLITE_ROW {
      if let cString = sqlite3_column_text(statement, 0) {
        return String(cString: cString)
      }
    }

    return nil
  }

  // MARK: - Cache Management

  private func getCachedTranslation(key: String, language: String) -> String? {
    return cacheQueue.sync {
      return translationCache[language]?[key]
    }
  }

  private func setCachedTranslation(key: String, language: String, translation: String) {
    cacheQueue.async(flags: .barrier) { [weak self] in
      if self?.translationCache[language] == nil {
        self?.translationCache[language] = [:]
      }
      self?.translationCache[language]?[key] = translation
    }
  }
}

// MARK: - Convenience Extensions

extension TranslationManager {

  /// Convenience method for translating with interpolation
  /// - Parameters:
  ///   - key: Translation key
  ///   - arguments: Arguments for string interpolation
  /// - Returns: Translated and interpolated string
  public func translate(_ key: String, arguments: CVarArg...) -> String {
    let template = translate(key)
    return String(format: template, arguments: arguments)
  }
}
