/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Tab based app structure.
*/

import SwiftUI

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
                ProductMenu()
            }
            .tabItem {
                let menuText = Text("Menu", comment: "Smoothie menu tab title")
                Label {
                    menuText
                } icon: {
                    Image(systemName: "list.bullet")
                }.accessibility(label: menuText)
            }
            .tag(Tab.menu)
            
            NavigationView {
                FavoriteProducts()
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
                RecipeList()
            }
            .tabItem {
                Label {
                    Text("Recipes",
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
        AppTabNavigation()
    }
}
