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
    
    init() {
        // Configure logging to omit trace level logs
        Logger.configureLogging()
        logger.debug("RecordThingApp initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
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
        .commands {
            SidebarCommands()
//            ProductCommands(model: model)
        }
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

