/*
See LICENSE folder for this sample's licensing information.

Abstract:
The single entry point for the RecordThing app on iOS and macOS.
*/

import SwiftUI
import Blackbird
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.thepia.RecordThing",
    category: "App"
)

/// - Tag: SingleAppDefinitionTag
@main
struct RecordThingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) private var scenePhase

    @StateObject var datasource = AppDatasource.shared // Important for triggering updates after translation loaded.
    @StateObject private var model = Model(loadedLang: AppDatasource.shared.$loadedLang)
    
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
                    default:
                        break
                    }
                }
        }
        .commands {
            SidebarCommands()
//            ProductCommands(model: model)
        }
    }
}
