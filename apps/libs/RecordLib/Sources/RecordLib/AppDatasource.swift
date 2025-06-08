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
    logger.info("🔧 Setting up database")
    let monitor = DatabaseMonitor.shared

    // Working database should be in App Support folder per PRD
    let appSupportPath = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("record-thing.sqlite")

    // Backup database location in Documents folder (for iCloud sync)
    let documentsBackupPath = FileManager.default.urls(
      for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("record-thing-backup.sqlite")

    logger.info("📁 Working database path: \(appSupportPath.platformPath)")
    logger.info("📁 Backup database path: \(documentsBackupPath.platformPath)")

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

    if !FileManager.default.fileExists(atPath: appSupportPath.platformPath) {
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
        forResource: "default-record-thing", ofType: "sqlite")
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
        logger.error("❌ Bundle database 'default-record-thing.sqlite' not found")
      }
    } else {
      logger.info("✅ Working database already exists at: \(appSupportPath.platformPath)")
    }

    // Connect to working database in App Support folder
    do {
      logger.info("🔗 Connecting to working database...")
      db = try Blackbird.Database(path: appSupportPath.platformPath)
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
        .appendingPathComponent("record-thing.sqlite")

      // Also reset backup in Documents folder
      let documentsBackupPath = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("record-thing-backup.sqlite")

      // Remove existing databases
      try? FileManager.default.removeItem(atPath: appSupportPath.platformPath)
      try? FileManager.default.removeItem(atPath: documentsBackupPath.platformPath)

      // Copy default database to working location
      if let bundleDbPath = Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite")
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
    if let bundleDbPath = Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite") {
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
}
