//
//  AppDatasource.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 30.03.2025.
//

import Blackbird
import Foundation
import SwiftUI
import os

// MARK: - AppDatasourceAPI Protocol
public protocol AppDatasourceAPI: ObservableObject {
  var db: Blackbird.Database? { get }
  var translations: [String: String] { get }
  var loadedLang: String? { get }

  func reloadDatabase()
  func resetDatabase()
  func updateDatabase() async
  func forceLocalizeReload()
}

// MARK: - Database Environment Key
private struct DatabaseKey: EnvironmentKey {
  static let defaultValue: Blackbird.Database? = nil
}

private struct DatasourceKey: EnvironmentKey {
  static let defaultValue: (any AppDatasourceAPI)? = nil
}

extension EnvironmentValues {
  public var database: Blackbird.Database? {
    get { self[DatabaseKey.self] }
    set { self[DatabaseKey.self] = newValue }
  }

  public var appDatasource: (any AppDatasourceAPI)? {
    get { self[DatasourceKey.self] }
    set { self[DatasourceKey.self] = newValue }
  }
}

// MARK: - Default AppDatasource Implementation

open class AppDatasource: ObservableObject, AppDatasourceAPI {
  open class var shared: AppDatasource { AppDatasource() }

  private let logger = Logger(subsystem: "com.record-thing", category: "App")

  @Published public private(set) var db: Blackbird.Database?
  @Published public private(set) var translations: [String: String] = [:]
  @Published public private(set) var loadedLang: String?

  private var currentLocale: String = Locale.current.identifier
  private var workingDatabasePath: URL?
  private var backupDatabasePath: URL?

  public init() {
    logger.info("🚀 Initializing AppDatasource")
    setupDatabase()

    if let db = db {
      logger.info("✅ AppDatasource initialized successfully with database: \(db.id)")
    } else {
      logger.error("❌ AppDatasource initialized but database is nil")
    }

    logger.info("✅ Finished setup of AppDatasource.")
  }

  public func forceLocalizeReload() {
    loadedLang = nil
  }

  // MARK: - Database Setup

  private func setupDatabase() {
    logger.info("🔧 Setting up database with enhanced connectivity management")
    let connectivityManager = DatabaseConnectivityManager.shared

    // Try enhanced connection with fallback strategy
    Task.detached { [weak self] in
      // Ensure any existing translation loading is complete before connecting Blackbird
      await self?.waitForTranslationManagerToComplete()

      let (database, mode) = await connectivityManager.connectWithFallback()

      await MainActor.run {
        guard let self = self else { return }
        if let db = database {
          self.db = db
          self.updateConnectionInfo(for: mode)
          self.setupBackupObservers()
          self.logger.info(
            "✅ Database connected successfully in \(self.getModeDisplayName(mode)) mode")
        } else {
          self.logger.error("❌ All database connection attempts failed")
          Task {
            await self.setupFallbackDatabase()
          }
        }
      }
    }
  }

  private func setupFallbackDatabase() async {
    logger.info("🔧 Setting up fallback database connection")
    let monitor = DatabaseMonitor.shared

    // Working database should be in App Support folder per PRD
    // Use the robust path resolution method
    let appSupportPath = URL(fileURLWithPath: getProductionDatabasePath())

    // Backup database location in Documents folder (for iCloud sync)
    let documentsBackupPath = FileManager.default.urls(
      for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("record-thing-backup.sqlite")

    logger.info("📁 Working database path: \(appSupportPath.platformPath)")
    logger.info("📁 Backup database path: \(documentsBackupPath.platformPath)")

    // Check for legacy database migration before proceeding
    logger.info("🔄 Starting legacy database migration check...")
    migrateLegacyDatabaseIfNeeded()
    logger.info("🔄 Legacy database migration check completed")

    // Ensure App Support directory exists
    let appSupportDir = appSupportPath.deletingLastPathComponent()
    if !FileManager.default.fileExists(atPath: appSupportDir.path) {
      do {
        try FileManager.default.createDirectory(
          at: appSupportDir, withIntermediateDirectories: true)
        logger.info("✅ Created App Support directory: \(appSupportDir.path)")
      } catch {
        logger.error("❌ Failed to create App Support directory: \(error)")
      }
    }

    // Database initialization priority per PRD:
    // 1. Copy from Documents folder backup (if exists)
    // 2. Copy from Storage bucket (if user ID exists) - TODO: implement
    // 3. Download demo database from cloud - TODO: implement
    // 4. Fall back to Assets folder copy in App bundle

    logger.info("🔍 Checking if database exists at: \(appSupportPath.platformPath)")
    let databaseExists = FileManager.default.fileExists(atPath: appSupportPath.platformPath)
    logger.info("🔍 Database exists: \(databaseExists)")

    if !databaseExists {
      logger.info("📋 Working database not found, initializing...")

      // Priority 1: Copy from Documents folder backup
      if FileManager.default.fileExists(atPath: documentsBackupPath.platformPath) {
        logger.info("📋 Found backup database, copying to working location...")
        do {
          try FileManager.default.copyItem(
            atPath: documentsBackupPath.platformPath, toPath: appSupportPath.platformPath)
          logger.info("✅ Successfully copied backup DB to working location")
        } catch {
          logger.error("❌ Failed to copy backup database: \(error)")
        }
      }
      // Priority 4: Fall back to bundle database
      else if let bundleDbPath = Bundle.main.path(
        forResource: "default-db", ofType: "sqlite")
      {
        logger.info("📋 Copying default database from bundle...")
        logger.info("   Source: \(bundleDbPath)")
        logger.info("   Destination: \(appSupportPath.platformPath)")
        do {
          // Use URL-based copy which is more robust
          let sourceURL = URL(fileURLWithPath: bundleDbPath)
          try FileManager.default.copyItem(at: sourceURL, to: appSupportPath)

          // Database copied successfully from bundle

          logger.info("✅ Successfully copied DB from bundle to: \(appSupportPath.platformPath)")
        } catch {
          logger.error("❌ Failed to copy database from bundle: \(error)")
          logger.error("   Source exists: \(FileManager.default.fileExists(atPath: bundleDbPath))")
          logger.error(
            "   Destination dir exists: \(FileManager.default.fileExists(atPath: appSupportPath.deletingLastPathComponent().path))"
          )
        }
      } else {
        logger.error("❌ Bundle database 'default-db.sqlite' not found")
      }
    } else {
      logger.info("✅ Working database already exists at: \(appSupportPath.platformPath)")
    }

    // Connect to working database in App Support folder
    do {
      logger.info("🔗 Connecting to working database...")

      #if os(macOS)
        // Remove quarantine attributes that prevent Blackbird from opening the database
        removeQuarantineAttributes(from: appSupportPath.platformPath)
      #endif

      // Attempt database connection with retry logic
      db = try await connectToDatabase(at: appSupportPath.platformPath)
      logger.info("✅ Successfully opened working DB: \(appSupportPath.platformPath)")

      // Update monitoring
      let connectionInfo = DatabaseConnectionInfo(
        path: appSupportPath.platformPath,
        type: .production,
        connectedAt: Date(),
        fileSize: try? FileManager.default.attributesOfItem(atPath: appSupportPath.platformPath)[
          .size]
          as? Int64,
        isReadOnly: false
      )
      monitor.updateConnectionInfo(connectionInfo)

      // Store paths for backup operations
      workingDatabasePath = appSupportPath
      backupDatabasePath = documentsBackupPath

      // Set up app lifecycle observers for automatic backup
      setupBackupObservers()

    } catch {
      logger.error("❌ Working database connection error: \(error)")
      monitor.logError(error, context: "Failed to open working database", query: nil)
    }

    // Set up health monitoring with database
    monitor.setHealthCheckFunction { [weak self] in
      guard let self = self, let db = self.db else {
        throw NSError(
          domain: "DatabaseError", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "No database connection"])
      }
      let _ = try await db.query("SELECT 1")
    }
  }

  // MARK: - Translation Loading

  open func loadTranslations(for locale: String = Locale.current.identifier) async {
    guard let db = db else { return }

    let lang = String(locale.prefix(2))  // Extract language code (e.g., "en" from "en_US")

    // Skip if already loaded for this language
    if loadedLang == lang { return }

    do {
      let rows: [Dictionary] = try await db.query(
        "SELECT key, value FROM translations WHERE lang = ?", lang)

      var newTranslations: [String: String] = [:]
      for row in rows {
        if let key = row["key"]?.stringValue,
          let value = row["value"]?.stringValue
        {
          newTranslations[key] = value
        }
      }

      let finalTranslations = newTranslations
      await MainActor.run {
        self.translations = finalTranslations
        self.loadedLang = lang
      }

      logger.debug("\(newTranslations.count) Translations loaded from DB for \(lang)")
    } catch {
      loadedLang = "failed"  // TODO fallback
      logger.error("Error loading translations: \(error)")
      DatabaseMonitor.shared.logError(
        error, context: "Failed to load translations",
        query: "SELECT lang, key, value FROM translations")
    }
  }

  // MARK: - Translation Methods

  public func translate(key: String, defaultValue: String? = nil) -> String {
    return translations[key] ?? defaultValue ?? key
  }

  public func updateLocale(_ newLocale: String) async {
    translations.removeAll()
    await loadTranslations(for: newLocale)
  }

  // MARK: - AppDatasourceAPI Implementation

  public func reloadDatabase() {
    logger.debug("Reloading database")
    DatabaseMonitor.shared.logActivity(.databaseReloaded, details: "Database reload initiated")
    setupDatabase()
  }

  public func resetDatabase() {
    Task {
      await db?.close()
      logger.debug("Resetting database")
      DatabaseMonitor.shared.logActivity(.databaseReset, details: "Database reset initiated")

      // Reset working database in App Support folder
      let appSupportPath = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("app-db.sqlite")

      // Also reset backup in Documents folder
      let documentsBackupPath = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("app-db.sqlite")

      // Remove existing databases
      try? FileManager.default.removeItem(atPath: appSupportPath.platformPath)
      try? FileManager.default.removeItem(atPath: documentsBackupPath.platformPath)

      // Copy default database to working location
      if let bundleDbPath = Bundle.main.path(forResource: "default-db", ofType: "sqlite")
      {
        try? FileManager.default.copyItem(atPath: bundleDbPath, toPath: appSupportPath.platformPath)
        logger.debug("Copied default DB to: \(appSupportPath.platformPath)")
        DatabaseMonitor.shared.logActivity(
          .databaseReset, details: "Copied default database to App Support folder")
      }

      // Reload database
      await MainActor.run {
        reloadDatabase()
      }
    }
  }

  public func updateDatabase() async {
    guard let db = db else { return }

    // Update translations table from default database
    if let bundleDbPath = Bundle.main.path(forResource: "default-db", ofType: "sqlite") {
      do {
        let defaultDb = try Blackbird.Database(path: bundleDbPath)
        let rows: [Dictionary] = try await defaultDb.query(
          "SELECT lang, key, value FROM translations")

        // Update translations in current database
        for row in rows {
          if let lang = row["lang"]?.stringValue,
            let key = row["key"]?.stringValue,
            let value = row["value"]?.stringValue
          {
            try await db.query(
              """
                  INSERT OR REPLACE INTO translations (lang, key, value)
                  VALUES (?, ?, ?)
              """, lang, key, value)
          }
        }

        logger.debug("Updated translations from default database")

        // Reload database to apply changes
        await MainActor.run {
          reloadDatabase()
        }

      } catch {
        logger.error("Failed to update database: \(error)")
        DatabaseMonitor.shared.logError(
          error, context: "Failed to update database", query: "UPDATE translations")
      }
    }
  }

  // MARK: - Database Backup Implementation (PRD Requirement)

  /// Set up app lifecycle observers for automatic database backup
  private func setupBackupObservers() {
    #if os(iOS)
      NotificationCenter.default.addObserver(
        forName: UIApplication.didEnterBackgroundNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        Task {
          await self?.performDatabaseBackup()
        }
      }

      NotificationCenter.default.addObserver(
        forName: UIApplication.willResignActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        Task {
          await self?.performDatabaseBackup()
        }
      }
    #elseif os(macOS)
      NotificationCenter.default.addObserver(
        forName: NSApplication.willResignActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        Task {
          await self?.performDatabaseBackup()
        }
      }
    #endif

    logger.info("✅ Database backup observers configured")
  }

  /// Perform APFS Copy-on-Write database backup per PRD
  @MainActor
  public func performDatabaseBackup() async {
    guard let workingPath = workingDatabasePath,
      let backupPath = backupDatabasePath
    else {
      logger.warning("⚠️ Database paths not configured for backup")
      return
    }

    let startTime = CFAbsoluteTimeGetCurrent()

    do {
      // Close database connection temporarily for safe backup
      await db?.close()

      // Remove existing backup if it exists
      if FileManager.default.fileExists(atPath: backupPath.path) {
        try FileManager.default.removeItem(at: backupPath)
      }

      // Perform APFS Copy-on-Write backup
      try FileManager.default.copyItem(at: workingPath, to: backupPath)

      let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000  // Convert to milliseconds

      logger.info("✅ Database backup completed in \(String(format: "%.1f", duration))ms")
      logger.info("   From: \(workingPath.path)")
      logger.info("   To: \(backupPath.path)")

      // Log backup activity
      DatabaseMonitor.shared.logActivity(
        .databaseBackup,
        details: "APFS Copy-on-Write backup completed in \(String(format: "%.1f", duration))ms"
      )

      // Reconnect to working database
      db = try Blackbird.Database(path: workingPath.platformPath)
      logger.info("✅ Reconnected to working database after backup")

    } catch {
      logger.error("❌ Database backup failed: \(error)")
      DatabaseMonitor.shared.logError(
        error,
        context: "APFS Copy-on-Write backup operation",
        query: nil
      )

      // Ensure we reconnect even if backup fails
      do {
        db = try Blackbird.Database(path: workingPath.platformPath)
      } catch {
        logger.error("❌ Failed to reconnect to database after backup failure: \(error)")
      }
    }
  }

  /// Manual backup trigger for debug/testing purposes
  public func triggerManualBackup() {
    Task {
      await performDatabaseBackup()
    }
  }

  // MARK: - Enhanced Database Management

  /// Update database connection with new database and mode
  public func updateDatabase(
    _ database: Blackbird.Database, mode: DatabaseConnectivityManager.DatabaseMode
  ) {
    self.db = database
    updateConnectionInfo(for: mode)
    logger.info("✅ Database updated to \(self.getModeDisplayName(mode)) mode")
  }

  /// Update connection info for monitoring
  private func updateConnectionInfo(for mode: DatabaseConnectivityManager.DatabaseMode) {
    let monitor = DatabaseMonitor.shared

    let connectionType: DatabaseConnectionInfo.DatabaseType
    switch mode {
    case .production:
      connectionType = .production
    case .development:
      connectionType = .development
    case .debug:
      connectionType = .debug
    case .inMemory:
      connectionType = .debug  // Treat in-memory as debug mode
    case .bundled:
      connectionType = .bundled
    }

    let path = getDatabasePath(for: mode)
    let connectionInfo = DatabaseConnectionInfo(
      path: path,
      type: connectionType,
      connectedAt: Date(),
      fileSize: getFileSize(at: path),
      isReadOnly: mode == .bundled
    )

    monitor.updateConnectionInfo(connectionInfo)
  }

  /// Get database path for specific mode with robust containerization support
  private func getDatabasePath(for mode: DatabaseConnectivityManager.DatabaseMode) -> String {
    switch mode {
    case .production:
      return getProductionDatabasePath()
    case .development:
      return "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite"
    case .debug:
      return NSHomeDirectory() + "/Desktop/record-thing-debug.sqlite"
    case .inMemory:
      return ":memory:"
    case .bundled:
      return Bundle.main.path(forResource: "default-db", ofType: "sqlite") ?? ""
    }
  }

  /// Get the production database path with proper containerization support
  private func getProductionDatabasePath() -> String {
    let fileManager = FileManager.default

    // Always use the runtime-determined App Support directory
    // This automatically handles containerization correctly
    let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let databaseURL = appSupportURL.appendingPathComponent("app-db.sqlite")

    logger.info("📁 Production database path: \(databaseURL.platformPath)")

    #if os(macOS)
      // Additional logging for macOS containerization
      if let bundleId = Bundle.main.bundleIdentifier {
        logger.info("📱 Using bundle ID: \(bundleId)")

        // Verify we're in the correct container
        let actualPath = appSupportURL.platformPath
        if actualPath.contains(bundleId) {
          logger.info("✅ Database correctly located in bundle ID container")
        } else {
          logger.warning("⚠️ Database path may not be in expected container")
          logger.warning("   Expected to contain: \(bundleId)")
          logger.warning("   Actual path: \(actualPath)")
        }
      }
    #endif

    return databaseURL.platformPath
  }

  /// Get file size for path
  private func getFileSize(at path: String) -> Int64? {
    guard path != ":memory:" else { return nil }
    return try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64
  }

  /// Get display name for database mode
  private func getModeDisplayName(_ mode: DatabaseConnectivityManager.DatabaseMode) -> String {
    switch mode {
    case .production: return "Production"
    case .development: return "Development"
    case .debug: return "Debug"
    case .inMemory: return "In-Memory"
    case .bundled: return "Bundled"
    }
  }

  /// Migrate database from legacy locations if needed
  private func migrateLegacyDatabaseIfNeeded() {
    let fileManager = FileManager.default
    let currentPath = URL(fileURLWithPath: getProductionDatabasePath())

    logger.info("🔍 Migration check - Current path: \(currentPath.platformPath)")
    logger.info(
      "🔍 Migration check - File exists: \(fileManager.fileExists(atPath: currentPath.platformPath))"
    )

    // If current database already exists, no migration needed
    if fileManager.fileExists(atPath: currentPath.platformPath) {
      logger.info("✅ Database already exists at current location - skipping migration")
      return
    }

    logger.info("🔍 Checking for legacy database locations...")

    #if os(macOS)
      // Check for potential legacy locations
      let homeDir = NSHomeDirectory()
      let legacyPaths = [
        // Potential legacy container with display name
        "\(homeDir)/Library/Containers/Record Thing/Data/Library/Application Support/app-db.sqlite",
        // Other potential legacy paths
        "\(homeDir)/Library/Application Support/RecordThing/app-db.sqlite",
        "\(homeDir)/Library/Application Support/Record Thing/app-db.sqlite",
      ]

      for legacyPath in legacyPaths {
        if fileManager.fileExists(atPath: legacyPath) {
          logger.info("📦 Found legacy database at: \(legacyPath)")

          do {
            // Ensure the target directory exists
            let targetDir = currentPath.deletingLastPathComponent()
            try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)

            // Copy the legacy database to the current location
            try fileManager.copyItem(atPath: legacyPath, toPath: currentPath.platformPath)
            logger.info("✅ Successfully migrated database from legacy location")

            // Optionally, you could remove the legacy database here
            // try fileManager.removeItem(atPath: legacyPath)

            return
          } catch {
            logger.error("❌ Failed to migrate legacy database: \(error)")
          }
        }
      }
    #endif

    logger.info("ℹ️ No legacy database found, will use bundled database")
  }

  /// Wait for TranslationManager to complete any ongoing operations to prevent concurrent access
  private func waitForTranslationManagerToComplete() async {
    logger.info("🔄 Waiting for TranslationManager to complete operations...")

    // Give TranslationManager a moment to complete any ongoing operations
    // This prevents concurrent access to the same SQLite file
    try? await Task.sleep(nanoseconds: 100_000_000)  // 100ms

    logger.info("✅ TranslationManager wait completed")
  }

  /// Connect to database with retry logic to handle potential conflicts
  private func connectToDatabase(at path: String, maxRetries: Int = 3) async throws
    -> Blackbird.Database
  {
    var lastError: Error?

    for attempt in 1...maxRetries {
      do {
        logger.info("🔗 Database connection attempt \(attempt)/\(maxRetries)")

        // Small delay between attempts to allow any concurrent operations to complete
        if attempt > 1 {
          try await Task.sleep(nanoseconds: 200_000_000)  // 200ms
        }

        let database = try Blackbird.Database(path: path)
        logger.info("✅ Database connection successful on attempt \(attempt)")
        return database

      } catch {
        lastError = error
        logger.warning("⚠️ Database connection attempt \(attempt) failed: \(error)")

        // If this is a file locking issue, wait a bit longer
        if error.localizedDescription.contains("database is locked")
          || error.localizedDescription.contains("SQLITE_BUSY")
        {
          logger.info("🔒 Database appears to be locked, waiting longer...")
          try? await Task.sleep(nanoseconds: 500_000_000)  // 500ms
        }
      }
    }

    // All attempts failed
    logger.error("❌ All database connection attempts failed")
    throw lastError
      ?? NSError(
        domain: "DatabaseError",
        code: 1,
        userInfo: [
          NSLocalizedDescriptionKey: "Failed to connect to database after \(maxRetries) attempts"
        ]
      )
  }

  #if os(macOS)
    /// Remove quarantine attributes from database file to allow Blackbird access
    private func removeQuarantineAttributes(from path: String) {
      let fileManager = FileManager.default

      guard fileManager.fileExists(atPath: path) else {
        logger.warning("⚠️ Cannot remove quarantine attributes - file doesn't exist: \(path)")
        return
      }

      do {
        let url = URL(fileURLWithPath: path)

        // Remove com.apple.quarantine attribute
        try url.removeExtendedAttribute(forName: "com.apple.quarantine")
        logger.info("✅ Removed com.apple.quarantine attribute from database")
      } catch {
        // This is expected if the attribute doesn't exist
        logger.debug("ℹ️ No com.apple.quarantine attribute to remove (this is normal)")
      }

      do {
        let url = URL(fileURLWithPath: path)

        // Remove com.apple.provenance attribute
        try url.removeExtendedAttribute(forName: "com.apple.provenance")
        logger.info("✅ Removed com.apple.provenance attribute from database")
      } catch {
        // This is expected if the attribute doesn't exist
        logger.debug("ℹ️ No com.apple.provenance attribute to remove (this is normal)")
      }
    }
  #endif
}

#if os(macOS)
  extension URL {
    /// Remove an extended attribute from the file
    func removeExtendedAttribute(forName name: String) throws {
      let result = removexattr(self.path, name, 0)
      if result != 0 {
        throw NSError(
          domain: NSPOSIXErrorDomain,
          code: Int(errno),
          userInfo: [NSLocalizedDescriptionKey: "Failed to remove extended attribute \(name)"]
        )
      }
    }
  }
#endif
