/*
See LICENSE folder for this sample's licensing information.

Abstract:
The single entry point for the RecordThing app on iOS and macOS.
*/

import Blackbird
import RecordLib
import SwiftUI
import os

#if os(macOS)
  import AppKit
#endif

#if os(iOS)
  import UIKit
#endif

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier ?? "com.thepia.RecordThing",
  category: "App"
)

// MARK: - Window State Observer
#if os(macOS)
  class WindowStateObserver: NSObject {
    private let logger = Logger(
      subsystem: Bundle.main.bundleIdentifier ?? "com.thepia.RecordThing", category: "WindowState")
    private let captureService: CaptureService

    init(captureService: CaptureService) {
      self.captureService = captureService
      super.init()
      setupObservers()
    }

    private func setupObservers() {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(windowWillMiniaturize),
        name: NSWindow.willMiniaturizeNotification,
        object: nil
      )

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(windowDidDeminiaturize),
        name: NSWindow.didDeminiaturizeNotification,
        object: nil
      )

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(windowDidBecomeKey),
        name: NSWindow.didBecomeKeyNotification,
        object: nil
      )
    }

    @objc private func windowWillMiniaturize() {
      logger.debug("Window will minimize")
      captureService.pauseStream()
    }

    @objc private func windowDidDeminiaturize() {
      logger.debug("Window did restore")
      captureService.resumeStream()
    }

    @objc private func windowDidBecomeKey() {
      logger.debug("Window became key window")
      captureService.resumeStream()
    }

    deinit {
      NotificationCenter.default.removeObserver(self)
    }
  }

  // MARK: - Window Management
  extension NSApplication {
    @objc func showAllWindows() {
      windows.forEach { window in
        window.makeKeyAndOrderFront(nil)
      }
    }
  }
#endif

struct DataBrowsingNav: Hashable {
  var title: String
  var path: String
}

struct FeedNav: Hashable {
  var path: String
}

struct AccountNav: Hashable {
  var path: String
}

/// - Tag: SingleAppDefinitionTag
@main
struct RecordThingApp: App {
  #if os(macOS)
    @NSApplicationDelegateAdaptor(RecordAppDelegate.self) var appDelegate
  #endif
  #if os(iOS)
    @UIApplicationDelegateAdaptor(RecordAppDelegate.self) var appDelegate
  #endif

  @Environment(\.scenePhase) private var scenePhase

  @StateObject var datasource = AppDatasource.shared  // Important for triggering updates after translation loaded.
  @StateObject private var model = Model(loadedLang: AppDatasource.shared.$loadedLang)
  @StateObject private var captureService = CaptureService()
  @StateObject private var assetsViewModel = AssetsViewModel()

  #if os(macOS)
    @State private var windowStateObserver: WindowStateObserver?
  #endif

  init() {
    // Configure logging to omit trace level logs
    Logger.configureLogging()
    logger.debug("RecordThingApp initialized")

    // Debug ShareExtension availability
    debugShareExtension()

    #if os(macOS)
      // Initialize window state observer
      windowStateObserver = WindowStateObserver(captureService: captureService)

      // Configure window management
      NSApplication.shared.windowsMenu = NSMenu(title: "Window")
      let showAllWindowsItem = NSMenuItem(
        title: "Show All Windows",
        action: #selector(NSApplication.showAllWindows),
        keyEquivalent: "0"
      )
      showAllWindowsItem.keyEquivalentModifierMask = [.command]
      NSApplication.shared.windowsMenu?.addItem(showAllWindowsItem)
    #endif
  }

  private func debugShareExtension() {
    logger.debug("🔍 Debugging ShareExtension availability...")

    // Check bundle structure
    let mainBundle = Bundle.main
    logger.debug("📱 Main app bundle ID: \(mainBundle.bundleIdentifier ?? "unknown")")
    logger.debug("📱 Main app bundle path: \(mainBundle.bundlePath)")

    // Check for PlugIns directory
    let plugInsPath = mainBundle.bundlePath + "/PlugIns"
    let fileManager = FileManager.default

    if fileManager.fileExists(atPath: plugInsPath) {
      logger.debug("✅ PlugIns directory exists at: \(plugInsPath)")

      do {
        let pluginContents = try fileManager.contentsOfDirectory(atPath: plugInsPath)
        logger.debug("📂 PlugIns contents: \(pluginContents)")

        // Look for ShareExtension.appex
        let shareExtensionPath = plugInsPath + "/ShareExtension.appex"
        if fileManager.fileExists(atPath: shareExtensionPath) {
          logger.debug("✅ ShareExtension.appex found at: \(shareExtensionPath)")

          // Try to load the extension bundle
          if let extensionBundle = Bundle(path: shareExtensionPath) {
            logger.debug("✅ ShareExtension bundle loaded successfully")
            logger.debug("🆔 Extension bundle ID: \(extensionBundle.bundleIdentifier ?? "unknown")")
            logger.debug(
              "📋 Extension display name: \(extensionBundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "unknown")"
            )

            // Check Info.plist configuration
            if let extensionInfo = extensionBundle.object(forInfoDictionaryKey: "NSExtension")
              as? [String: Any]
            {
              logger.debug("📄 NSExtension info found")

              if let attributes = extensionInfo["NSExtensionAttributes"] as? [String: Any],
                let activationRule = attributes["NSExtensionActivationRule"] as? [String: Any]
              {
                logger.debug("⚙️ Activation rules: \(activationRule)")
              }
            }
          } else {
            logger.error("❌ Failed to load ShareExtension bundle")
          }
        } else {
          logger.error("❌ ShareExtension.appex NOT found at expected path")
        }
      } catch {
        logger.error("❌ Failed to read PlugIns directory: \(error.localizedDescription)")
      }
    } else {
      logger.error("❌ PlugIns directory does NOT exist")
    }

    #if os(iOS)
      // Check if extension is registered with the system
      checkSystemExtensionRegistration()
    #endif
  }

  #if os(iOS)
    private func checkSystemExtensionRegistration() {
      logger.debug("🔍 Checking system extension registration...")

      // This will be called when the app becomes active
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        // Note: There's no public API to query system extensions directly
        // The extension registration happens automatically when the app is installed
        logger.debug("📋 Extension registration is handled automatically by iOS")
        logger.debug("🔗 Our extension should appear in share sheets if properly configured")
        logger.debug("💡 Check the ShareExtension Debug view for detailed bundle information")
      }
    }
  #endif

  var body: some Scene {
    WindowGroup {
      // TODO compact vs macOS/iPadOS CompactContentView vs SplitContentView
      ContentView(captureService: captureService)
        .environmentObject(model)
        .environment(\.blackbirdDatabase, AppDatasource.shared.db)
        .environment(\.appDatasource, AppDatasource.shared)
        .environment(\.assetsViewModel, assetsViewModel)
        .onReceive(datasource.$db) { newDb in
          logger.info("🔄 Database changed in app, updating AssetsViewModel")
          assetsViewModel.updateDatabase(newDb)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
          switch newPhase {
          case .active:  // On application startup or resume
            if let documentsPathURL = FileManager.default.urls(
              for: .documentDirectory, in: .userDomainMask
            ).first {
              logger.debug("Documents directory path: \(documentsPathURL.path)")
            }

          case .inactive:
            logger.debug("Application became inactive")
            // Ensure we update the app snapshot for the task switcher
            #if os(iOS)
              updateAppSnapshot()
            #endif

          case .background:
            logger.debug("Application entered background")

          @unknown default:
            logger.debug("Unknown scene phase")
          }
        }
    }
    #if os(macOS)
      .defaultSize(
        width: DesignSystemSetup.light.cameraWidth, height: DesignSystemSetup.light.cameraHeight
      )
      .windowResizability(.contentSize)
      .commands {
        SidebarCommands()

        CommandGroup(replacing: .newItem) {
          Button("New Window") {
            NSApplication.shared.requestUserAttention(.informationalRequest)
          }
          .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(after: .windowList) {
          Button("Show All Windows") {
            NSApplication.shared.showAllWindows()
          }
          .keyboardShortcut("0", modifiers: .command)
        }
      }
    #endif
  }

  #if os(iOS)
    // Function to update the app snapshot for the task switcher
    private func updateAppSnapshot() {
      // Get the current key window
      guard
        let window = UIApplication.shared.connectedScenes
          .filter({ $0.activationState == .foregroundActive })
          .compactMap({ $0 as? UIWindowScene })
          .first?.windows
          .first(where: { $0.isKeyWindow })
      else {
        logger.error("Could not find key window for snapshot")
        return
      }

      // Create a snapshot of the current UI state
      if let snapshotView = window.snapshotView(afterScreenUpdates: true) {
        // Add the snapshot view to the window temporarily
        window.addSubview(snapshotView)

        // Remove it after a short delay (after the system has taken its snapshot)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          snapshotView.removeFromSuperview()
        }

        logger.debug("Updated app snapshot for task switcher")
      } else {
        logger.error("Failed to create snapshot view")
      }
    }
  #endif
}
