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

var dbPath = {
    // First check for test database on external volume
    let testPath = "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite"
    if FileManager.default.fileExists(atPath: testPath) {
        logger.info("Using test database at \(testPath)")
        return URL(fileURLWithPath: testPath)
    }
    
    // Fall back to documents directory
    if let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        logger.info("Using database in documents path: \(documentsPathURL.path)")
        return documentsPathURL.appendingPathComponent("record-thing.sqlite")
    }
    
    // Last resort fallback
    logger.warning("Using fallback database path: /tmp/record-thing.sqlite")
    return URL(fileURLWithPath: "/tmp/record-thing.sqlite")
}()

/// - Tag: SingleAppDefinitionTag
@main
struct RecordThingApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var model = Model()
    
    // The database that all child views will automatically use
//    @StateObject var database = try! Blackbird.Database.inMemoryDatabase()
    @StateObject var database = try! Blackbird.Database(path: dbPath.absoluteString)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .environment(\.blackbirdDatabase, database)
                .task {
                    // Initialize translations when app starts
                    await DynamicLocalizer.shared.registerTranslations(from: database)
                }
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
