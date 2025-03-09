/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Tab based app structure.
*/

import SwiftUI
import Blackbird

struct AppTabNavigation: View {

    enum Tab {
        case menu
        case favorites
        case rewards // TODO
        case recipes
    }

    @State private var selection: Tab = .menu

    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                ThingsMenu()
            }
            .tabItem {
                let menuText = Text("Things", comment: "Smoothie menu tab title")
                Label {
                    menuText
                } icon: {
                    Image(systemName: "list.bullet")
                }.accessibility(label: menuText)
            }
            .tag(Tab.menu)
            
            NavigationView {
                EvidenceTypeMenu()
            }
            .tabItem {
                Label {
                    Text("Favorites",
                         comment: "Favorite smoothies tab title")
                } icon: {
                    Image(systemName: "heart.fill")
                }
            }
            .tag(Tab.favorites)
            
            #if EXTENDED_ALL
            NavigationView {
            }
            .tabItem {
                Label {
                    Text("Rewards",
                         comment: "Smoothie rewards tab title")
                } icon: {
                    Image(systemName: "seal.fill")
                }
            }
            .tag(Tab.rewards)
            
            NavigationView {
                RequestsMenu()
            }
            .tabItem {
                Label {
                    Text("Requests",
                         comment: "Smoothie recipes tab title")
                } icon: {
                    Image(systemName: "book.closed.fill")
                }
            }
            .tag(Tab.recipes)
            #endif
        }
    }
}

struct AppTabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        @Previewable @StateObject var database = try! Blackbird.Database(path: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite")
        @Previewable @StateObject var model = Model()

        AppTabNavigation()
            .environment(\.blackbirdDatabase, database)
            .environmentObject(model)
    }
}
