/*
See LICENSE folder for this sample's licensing information.

Abstract:
Tab based app structure.
*/

import SwiftUI
import Blackbird

struct BrowseTabNavigation: View {

    enum Tab {
        // Buttons in App Toolbar
        case record
        case assets
        case actions

        // Data Browsing tabs
        case things
        case types
        case feed
        case favorites
    }

    @Binding var selection: Tab
        
    var body: some View {
        VStack {
            TabView(selection: $selection) {
                Group {
                    Text("record")
                }
                .tabItem {
                    Label {
                        Text("Record", comment: "..")
                    } icon: {
                        Image(systemName: "camera")
                    }
                }
                .tag(Tab.record)
                
                NavigationView {
                    ThingsMenu()
                }
                .tabItem {
                    let menuText = Text("Things", comment: "..")
                    Label {
                        menuText
                    } icon: {
                        Image(systemName: "list.bullet")
                    }.accessibility(label: menuText)
                }
                .tag(Tab.things)
                
                NavigationView {
                    EvidenceTypeMenu()
                }
                .tabItem {
                    Label {
                        Text("Types",
                             comment: "..")
                    } icon: {
                        Image(systemName: "heart.fill")
                    }
                }
                .tag(Tab.types)
                
                NavigationView {
                    
                }
                .tabItem {
                    Label {
                        Text("Feed", comment: "..")
                    } icon: {
                        Image(systemName: "tray")
                    }
                }
                .tag(Tab.feed)
                
                NavigationView {
                    
                }
                .tabItem {
                    Label {
                        Text("Favorites", comment: "..")
                    } icon: {
                        Image(systemName: "star")
                    }
                }
                .tag(Tab.favorites)
            }
        }
    }
}

struct BrowseTabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        @Previewable @StateObject var database = try! Blackbird.Database(path: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite")
        @Previewable @StateObject var model = Model()
        @Previewable @State var selectedTab: BrowseTabNavigation.Tab = .record

        BrowseTabNavigation(selection: $selectedTab)
            .environment(\.blackbirdDatabase, database)
            .environmentObject(model)
    }
}
