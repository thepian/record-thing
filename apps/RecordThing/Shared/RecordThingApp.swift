/*
See LICENSE folder for this sample's licensing information.

Abstract:
The single entry point for the RecordThing app on iOS and macOS.
*/

import SwiftUI
import Blackbird
import RecordLib
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
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.thepia.RecordThing", category: "WindowState")
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
    
    @StateObject var datasource = AppDatasource.shared // Important for triggering updates after translation loaded.
    @StateObject private var model = Model(loadedLang: AppDatasource.shared.$loadedLang)
    @StateObject private var captureService = CaptureService()
    
    #if os(macOS)
    @State private var windowStateObserver: WindowStateObserver?
    #endif
    
    init() {
        // Configure logging to omit trace level logs
        Logger.configureLogging()
        logger.debug("RecordThingApp initialized")
        
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
    
    var body: some Scene {
        WindowGroup {
            // TODO compact vs macOS/iPadOS CompactContentView vs SplitContentView
            ContentView(captureService: captureService)
                .environmentObject(model)
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    switch(newPhase) {
                    case .active: // On application startup or resume
                        if let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
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
        .defaultSize(width: DesignSystemSetup.light.cameraWidth, height: DesignSystemSetup.light.cameraHeight)
        .windowResizability(.contentSize)
        .commands {
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
        guard let window = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
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

