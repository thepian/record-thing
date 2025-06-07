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

// MARK: - App Datasource (extends RecordLib)
class AppDatasource: RecordLib.AppDatasource {
  private static let _shared = AppDatasource()  // (debugDb: true)
  override class var shared: AppDatasource { _shared }

  private var currentLocale: String = Locale.current.identifier

  //    init() {
  //        setupDatabase()
  //    }
  override init(debugDb: Bool = false) {
    super.init(debugDb: debugDb)
    logger.info("Finished setup of main app AppDatasource.")
  }

  // Database setup is now handled by the parent RecordLib.AppDatasource class

  @MainActor
  override func loadTranslations(for locale: String = Locale.current.identifier) async {
    if !Bundle._installedBlackbirdTranslations {
      Bundle._installedBlackbirdTranslations = true
      Bundle.installBlackbirdTranslations()
    }

    // Use the parent's loadTranslations method
    await super.loadTranslations(for: locale)

    // Update current locale for this app-specific implementation
    currentLocale = locale
  }

  // translate method is inherited from RecordLib.AppDatasource
  // updateLocale method is inherited from RecordLib.AppDatasource

  // MARK: - AppDatasourceAPI Implementation
  // Database operations are now inherited from RecordLib.AppDatasource
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
