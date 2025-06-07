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

  public init(debugDb: Bool = false) {
    logger.info("🚀 Initializing AppDatasource with debugDb: \(debugDb)")
    setupDatabase(debugDb: debugDb)

    if let db = db {
      logger.info("✅ AppDatasource initialized successfully with database")
    } else {
      logger.error("❌ AppDatasource initialized but database is nil")
    }

    logger.info("✅ Finished setup of AppDatasource.")
  }

  public func forceLocalizeReload() {
    loadedLang = nil
  }

  // MARK: - Database Setup

  private func setupDatabase(debugDb: Bool = false) {
    logger.info("🔧 Setting up database with debugDb: \(debugDb)")
    let monitor = DatabaseMonitor.shared

    if debugDb {
      let debugPath =
        "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing-debug.sqlite"
      logger.info("🔍 Checking for debug database at: \(debugPath)")

      if FileManager.default.fileExists(atPath: debugPath) {
        logger.info("✅ Debug database found, connecting...")
        let url = URL(fileURLWithPath: debugPath)

        do {
          db = try Blackbird.Database(path: url.absoluteString)
          logger.info("✅ Successfully opened Debug DB: \(url.absoluteString)")

          // Update monitoring
          let connectionInfo = DatabaseConnectionInfo(
            path: debugPath,
            type: .debug,
            connectedAt: Date(),
            fileSize: try? FileManager.default.attributesOfItem(atPath: debugPath)[.size]
              as? Int64,
            isReadOnly: false
          )
          monitor.updateConnectionInfo(connectionInfo)
        } catch {
          logger.error("❌ Debug database connection error: \(error)")
          monitor.logError(error, context: "Failed to open debug database", query: nil)
        }
        return
      } else {
        logger.warning("⚠️ Debug database not found at \(debugPath)")
      }
    }

    // First check for test database on external volume
    let testPath =
      "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite"
    logger.info("🔍 Checking for development database at: \(testPath)")

    if FileManager.default.fileExists(atPath: testPath) {
      logger.info("✅ Development database found, connecting...")
      let url = URL(fileURLWithPath: testPath)

      do {
        db = try Blackbird.Database(path: url.absoluteString)
        logger.info("✅ Successfully opened Dev DB: \(url.absoluteString)")

        // Update monitoring
        let connectionInfo = DatabaseConnectionInfo(
          path: testPath,
          type: .development,
          connectedAt: Date(),
          fileSize: try? FileManager.default.attributesOfItem(atPath: testPath)[.size] as? Int64,
          isReadOnly: false
        )
        monitor.updateConnectionInfo(connectionInfo)
      } catch {
        logger.error("❌ Development database connection error: \(error)")
        monitor.logError(error, context: "Failed to open development database", query: nil)
      }
      return
    } else {
      logger.info("ℹ️ Development database not found, falling back to production database")
    }

    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("record-thing.sqlite")

    logger.info("📁 Production database path: \(documentsPath.path)")

    // Copy default database if needed
    if !FileManager.default.fileExists(atPath: documentsPath.path) {
      logger.info("📋 Production database not found, copying from bundle...")

      if let bundleDbPath = Bundle.main.path(
        forResource: "default-record-thing", ofType: "sqlite")
      {
        do {
          try FileManager.default.copyItem(atPath: bundleDbPath, toPath: documentsPath.path)
          logger.info("✅ Successfully copied DB from bundle to: \(documentsPath.path)")
        } catch {
          logger.error("❌ Failed to copy database from bundle: \(error)")
        }
      } else {
        logger.error("❌ Bundle database 'default-record-thing.sqlite' not found")
      }
    } else {
      logger.info("✅ Production database already exists at: \(documentsPath.path)")
    }

    // Connect to database
    do {
      logger.info("🔗 Connecting to production database...")
      db = try Blackbird.Database(path: documentsPath.path)
      logger.info("✅ Successfully opened production DB: \(documentsPath.path)")

      // Update monitoring
      let connectionInfo = DatabaseConnectionInfo(
        path: documentsPath.path,
        type: .production,
        connectedAt: Date(),
        fileSize: try? FileManager.default.attributesOfItem(atPath: documentsPath.path)[.size]
          as? Int64,
        isReadOnly: false
      )
      monitor.updateConnectionInfo(connectionInfo)
    } catch {
      logger.error("❌ Production database connection error: \(error)")
      monitor.logError(error, context: "Failed to open production database", query: nil)
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
    setupDatabase(debugDb: false)
  }

  public func resetDatabase() {
    Task {
      await db?.close()
      logger.debug("Resetting database")
      DatabaseMonitor.shared.logActivity(.databaseReset, details: "Database reset initiated")

      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("record-thing.sqlite")

      // Remove existing database
      try? FileManager.default.removeItem(atPath: documentsPath.path)

      // Copy default database
      if let bundleDbPath = Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite")
      {
        try? FileManager.default.copyItem(atPath: bundleDbPath, toPath: documentsPath.path)
        logger.debug("Copied default DB to: \(documentsPath.path)")
        DatabaseMonitor.shared.logActivity(
          .databaseReset, details: "Copied default database to documents")
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
}
