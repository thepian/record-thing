/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's navigation with a configuration that offers a sidebar, content list, and detail pane.
*/

import SwiftUI

struct AppSidebarNavigation: View {

    enum NavigationItem {
        case menu
        case favorites
        case recipes
    }

    @EnvironmentObject private var model: Model
    @State private var presentingRewards: Bool = false
    @State private var selection: NavigationItem? = .menu
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(tag: NavigationItem.menu, selection: $selection) {
                    ProductMenu()
                } label: {
                    Label("Products", systemImage: "list.bullet")
                }
                
                NavigationLink(tag: NavigationItem.menu, selection: $selection) {
                    ProductMenu()
                } label: {
                    Label("Documents", systemImage: "doc")
                }
                
                NavigationLink(tag: NavigationItem.menu, selection: $selection) {
                    ProductMenu()
                } label: {
                    Label("Recent", systemImage: "clock")
                }
                
                NavigationLink(tag: NavigationItem.favorites, selection: $selection) {
                    FavoriteProducts()
                } label: {
                    Label("Flagged", systemImage: "flag")
                }
            
                NavigationLink(tag: NavigationItem.favorites, selection: $selection) {
                    FavoriteProducts()
                } label: {
                    Label("Favorites", systemImage: "heart")
                }

                NavigationLink(tag: NavigationItem.recipes, selection: $selection) {
                    RecipeList()
                } label: {
                    Label("ML Models", systemImage: "book.closed")
                }

                #if EXTENDED_ALL
                NavigationLink(tag: NavigationItem.recipes, selection: $selection) {
                    RecipeList()
                } label: {
                    Label("Recipes", systemImage: "book.closed")
                }
                #endif
            }
            .navigationTitle("Record Thing")
            #if EXTENDED_ALL
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Pocket()
            }
            #endif
            
            Text("Select a category")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background()
                .ignoresSafeArea()
            
            Text("Select a product")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background()
                .ignoresSafeArea()
                .toolbar {
                    ProductFavoriteButton()
                        .environmentObject(model)
                        .disabled(true)
                }
        }
    }
    
    struct Pocket: View {
        @State private var presentingRewards: Bool = false
        @EnvironmentObject private var model: Model
        
        var body: some View {
            Button(action: { presentingRewards = true }) {
                Label("Rewards", systemImage: "seal")
            }
            .controlSize(.large)
            .buttonStyle(.capsule)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .sheet(isPresented: $presentingRewards) {
            }
        }
    }
}

struct AppSidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        AppSidebarNavigation()
            .environmentObject(Model())
    }
}

struct AppSidebarNavigationPocket_Previews: PreviewProvider {
    static var previews: some View {
        AppSidebarNavigation.Pocket()
            .environmentObject(Model())
            .frame(width: 300)
    }
}
