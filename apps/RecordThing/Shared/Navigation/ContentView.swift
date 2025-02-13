/*
See LICENSE folder for this sample's licensing information.

Abstract:
The primary entry point for the app's user interface. Can change between tab-based and sidebar-based navigation.
*/

import SwiftUI
import Blackbird

struct ContentView: View {
    @EnvironmentObject private var model: Model

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
        
    var body: some View {
        if model.loadedLang == nil {
            ProgressView()
        } else {
#if os(iOS)
            if horizontalSizeClass == .compact {
                AppTabNavigation()
            } else {
                AppSidebarNavigation()
            }
#else
            AppSidebarNavigation()
#endif
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Regular view preview
            ContentView()
                .environmentObject(Model(loadedLangConst: "en"))
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .previewDisplayName("Loaded")
            
            // Redacted view preview
            ContentView()
                .environmentObject(Model(loadedLangConst: "en"))
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .redacted(reason: .placeholder)
                .previewDisplayName("Redacted")

            // Loading view preview
            ContentView()
                .environmentObject(Model())
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .onAppear {
                    AppDatasource.shared.forceLocalizeReload()
                }
                .previewDisplayName("Loading")
        }
    }
}
