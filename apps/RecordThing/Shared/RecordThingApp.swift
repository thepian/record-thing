/*
See LICENSE folder for this sample's licensing information.

Abstract:
The single entry point for the RecordThing app on iOS and macOS.
*/

import SwiftUI
import Blackbird

var dbPath = {
    // First check for test database on external volume
    let testPath = "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite"
    if FileManager.default.fileExists(atPath: testPath) {
        print("Using test database at", testPath)
        return URL(fileURLWithPath: testPath)
    }
    
    // Fall back to documents directory
    if let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        print("Using database in documents path:", documentsPathURL)
        return documentsPathURL.appendingPathComponent("record-thing.sqlite")
    }
    
    // Last resort fallback
    print("Using fallback database path: /tmp/record-thing.sqlite")
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
                .onChange(of: scenePhase) { phase in
//                    visionService.onScenePhase(phase)
                    
//                    public func onScenePhase(_ phase: ScenePhase) {
                        switch(phase) {
                        case .active: // On application startup or resume
                            if let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                //This gives you the URL of the path
//                                print("documents path", documentsPathURL)
                            }
                            break
                        case .inactive:
                            break
                        default:
                            break
                        }
//                    }
                }
        }
        .commands {
            SidebarCommands()
//            ProductCommands(model: model)
        }
    }
}
