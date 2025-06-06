//
//  AppDatasource.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 13.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Blackbird
import Foundation
import RecordLib
import SwiftUI
import os

#if os(macOS)
  import AppKit
#endif

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier ?? "com.thepia.RecordThing",
  category: "App"
)

// MARK: - LocalizedStringKey

/*
extension LocalizedStringKey {
    static var _installedCustomInit: Bool = false

    // https://stackoverflow.com/questions/34317766/how-to-swizzle-init-in-swift
    static func installCustomInit() {
        guard !_installedCustomInit else { return }

        if let methodOriginal = class_getClassMethod(self, #selector(LocalizedStringKey.init(stringLiteral:))),
           let methodCustom = class_getClassMethod(LocalizedStringKey.self, #selector(LocalizedStringKey.customInit(stringLiteral:))) {
            method_exchangeImplementations(methodOriginal, methodCustom)
        }

        _installedCustomInit = true
        print("installed Translations in LocalizedStringKey")
    }

    private func customInit(stringLiteral value: String) {
        let translated = AppDatasource.shared.translate(key: value, defaultValue: value)
        self.customInit(stringLiteral: translated)  // This will actually call the original init due to the swizzling
    }
}
*/

extension LocalizedStringKey {
  /* This overrides the default constructor hoping that it is the one most commonly used. It could be that stringLiteral is the more important to override.
   However we can only override a single one, unless we use swizzling.
  
   We would also want to support the variant init(stringInterpolation: LocalizedStringKey.StringInterpolation)
   */
  //    init(_ key: String) {
  //        let value = AppDatasource.shared.translate(key: key, defaultValue: key)
  //        logger.trace("translated \(value) (LocalizedStringKey)")
  //        self.init(stringLiteral: value)
  //    }

  init(stringLiteral: String) {
    let value = AppDatasource.shared.translate(key: stringLiteral, defaultValue: stringLiteral)
    logger.trace("translated \(value) (LocalizedStringKey)")
    self.init(value)
  }

  init(dbKey key: String) {
    let value = AppDatasource.shared.translate(key: key, defaultValue: key)
    logger.trace("translated \(value) (LocalizedStringKey)")
    self.init(value)
  }
}

extension String {
  var localized: String {
    let translated = AppDatasource.shared.translate(key: self, defaultValue: self)
    return NSLocalizedString(translated, comment: "")
  }

  func localized(_ args: CVarArg...) -> String {
    let translated = AppDatasource.shared.translate(key: self, defaultValue: self)
    let localizedString = NSLocalizedString(translated, comment: "")
    return String(format: localizedString, arguments: args)
  }
}

// MARK: - Bundle Extension for Blackbird Translations
extension Bundle {
  static var _installedBlackbirdTranslations: Bool = false

  // Replace the default localization with our Blackbird-based one
  static func installBlackbirdTranslations() {
    let bundleClass: AnyClass = Bundle.self

    if let methodOriginal = class_getClassMethod(
      bundleClass, #selector(localizedString(forKey:value:table:))),
      let methodCustom = class_getClassMethod(
        bundleClass, #selector(blackbirdLocalizedString(forKey:value:table:)))
    {
      method_exchangeImplementations(methodOriginal, methodCustom)
    }
    logger.trace("installed Translations in Bundle")
  }

  @objc private class func blackbirdLocalizedString(
    forKey key: String, value: String?, table: String?
  ) -> String {
    print("translating \(key)")
    return AppDatasource.shared.translate(key: key, defaultValue: value ?? key)
  }
}

// MARK: - App Datasource
class AppDatasource: ObservableObject, AppDatasourceAPI {
  static let shared = AppDatasource()  // (debugDb: true)

  var db: Blackbird.Database?
  @Published private(set) var translations: [String: String] = [:]
  private var currentLocale: String = Locale.current.identifier

  @Published private(set) var loadedLang: String?

  //    init() {
  //        setupDatabase()
  //    }
  init(debugDb: Bool = false) {
    setupDatabase(debugDb: debugDb)
    logger.info("Finished setup of AppDatasource.")
  }

  func forceLocalizeReload() {
    loadedLang = nil
  }

  private func setupDatabase(debugDb: Bool = false) {
    let monitor = DatabaseMonitor.shared

    if debugDb {
      let debugPath =
        "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing-debug.sqlite"
      if FileManager.default.fileExists(atPath: debugPath) {
        logger.info("Using test database at \(debugPath)")
        let url = URL(fileURLWithPath: debugPath)

        do {
          db = try Blackbird.Database(path: url.absoluteString)
          logger.debug("Opened Debug DB: \(url.absoluteString)")

          // Update monitoring
          let connectionInfo = DatabaseConnectionInfo(
            path: debugPath,
            type: .debug,
            connectedAt: Date(),
            fileSize: try? FileManager.default.attributesOfItem(atPath: debugPath)[.size] as? Int64,
            isReadOnly: false
          )
          monitor.updateConnectionInfo(connectionInfo)
        } catch {
          logger.error("\(url.absoluteString)\nDatabase connection error: \(error)")
          monitor.logError(error, context: "Failed to open debug database", query: nil)
        }
        return
      }
    }
    // First check for test database on external volume
    let testPath = "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite"
    if FileManager.default.fileExists(atPath: testPath) {
      logger.info("Using test database at \(testPath)")
      let url = URL(fileURLWithPath: testPath)

      do {
        db = try Blackbird.Database(path: url.absoluteString)
        logger.debug("Opened Dev DB: \(url.absoluteString)")

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
        logger.error("\(url.absoluteString)\nDatabase connection error: \(error)")
        monitor.logError(error, context: "Failed to open development database", query: nil)
      }
      return
    }

    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("record-thing.sqlite")

    // Copy default database if needed
    if !FileManager.default.fileExists(atPath: documentsPath.path) {
      if let bundleDbPath = Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite")
      {
        try? FileManager.default.copyItem(atPath: bundleDbPath, toPath: documentsPath.path)
        logger.debug("Copied DB from assets to: \(documentsPath.path)")
      }
    }

    // Connect to database
    do {
      db = try Blackbird.Database(path: documentsPath.path)
      logger.debug("Opened DB: \(documentsPath.path)")

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
      logger.error("Database connection error: \(error)")
      monitor.logError(error, context: "Failed to open production database", query: nil)
    }
  }

  @MainActor
  func loadTranslations(for locale: String?) async {
    if !Bundle._installedBlackbirdTranslations {
      Bundle._installedBlackbirdTranslations = true
      Bundle.installBlackbirdTranslations()
    }
    do {
      guard let db = db else { return }
      let rows: [Dictionary] =
        try await db
        .query(
          """
              SELECT lang, key, value 
              FROM `translations`
              ORDER BY lang, key
          """)

      if let locale = locale {
        currentLocale = locale
      }

      // FIXME hacky fallback values that shouldn't occur
      let keysWithValues = rows.compactMap {
        ($0["key"]?.stringValue ?? "", $0["value"]?.stringValue ?? "")
      }
      translations = Dictionary(uniqueKeysWithValues: keysWithValues)
      loadedLang = locale
      //            logger.info
      print("\(keysWithValues.count) Translations loaded from DB for \(locale ?? "en")")
    } catch {
      loadedLang = "failed"  // TODO fallback
      logger.error("Error loading translations: \(error)")
      DatabaseMonitor.shared.logError(
        error, context: "Failed to load translations",
        query: "SELECT lang, key, value FROM translations")
    }
  }

  func translate(key: String, defaultValue: String? = nil) -> String {
    return translations[key] ?? defaultValue ?? key
  }

  func updateLocale(_ newLocale: String) async {
    translations.removeAll()
    await loadTranslations(for: newLocale)
  }

  // MARK: - AppDatasourceAPI Implementation

  func reloadDatabase() {
    logger.debug("Reloading database")
    DatabaseMonitor.shared.logActivity(.databaseReloaded, details: "Database reload initiated")
    setupDatabase(debugDb: false)
  }

  func resetDatabase() {
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
      reloadDatabase()
    }
  }

  func updateDatabase() async {
    logger.debug("Updating database")
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

// MARK: - App Delegate

class RecordAppDelegate: NSObject {
  #if os(macOS)
    var window: NSWindow?
  #endif

  func loadTranslations(for locale: String) {
    if !Bundle._installedBlackbirdTranslations {
      Bundle._installedBlackbirdTranslations = true
      Bundle.installBlackbirdTranslations()
    }
    Task(priority: .userInitiated) {
      await AppDatasource.shared.loadTranslations(for: locale)
    }
  }
}

#if os(iOS)
  extension RecordAppDelegate: UIApplicationDelegate {
    func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
      // Configure logging to omit trace level logs
      Logger.configureLogging()
      logger.debug("iOS app delegate initialized")

      let locale = Locale.current.language.languageCode?.identifier ?? "en"
      loadTranslations(for: locale)
      return true
    }
  }
#endif
#if os(macOS)
  extension RecordAppDelegate: NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
      // Configure logging to omit trace level logs
      Logger.configureLogging()
      logger.debug("macOS app delegate initialized")

      // Initialize any necessary app state here
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
      return true
    }
  }
#endif

// Preview wrapper that mimics your app structure
struct AppDelegatePreviewWrapper: View {
  #if os(macOS)
    @NSApplicationDelegateAdaptor(RecordAppDelegate.self) var appDelegate
  #endif
  #if os(iOS)
    @UIApplicationDelegateAdaptor(RecordAppDelegate.self) var appDelegate
  #endif

  let content: AnyView

  var body: some View {
    content
  }
}

// MARK: - Example Usage
struct SampleView: View {
  @StateObject private var datasource = AppDatasource.shared

  var body: some View {
    Group {
      if datasource.loadedLang == nil {
        ProgressView()
      } else {
        VStack {
          // These will use the Blackbird translations automatically
          Text(LocalizedStringKey("welcome_message"))
          Text(LocalizedStringKey("request.status"))
          Text("Hello, world!", tableName: "CustomTable")
          Text("ui.filter".localized)
          Text(LocalizedStringKey("Evidence.recipe"))

          // For dynamic strings with arguments
          Text(String(format: NSLocalizedString("greeting", comment: ""), "John"))

          // Labels will automatically use localized strings
          Label(LocalizedStringKey("profile"), systemImage: "person.circle")
        }
      }
    }
    .environment(\.appDatasource, datasource)
  }
}

// Then update the preview
struct SampleView_Previews: PreviewProvider {
  static var previews: some View {
    AppDelegatePreviewWrapper(content: AnyView(SampleView()))
  }
}
