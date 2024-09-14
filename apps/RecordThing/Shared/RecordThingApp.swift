/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The single entry point for the RecordThing app on iOS and macOS.
*/

import SwiftUI
/// - Tag: SingleAppDefinitionTag
@main
struct RecordThingApp: App {
    @StateObject private var model = Model()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
        .commands {
            SidebarCommands()
            ProductCommands(model: model)
        }
    }
}
