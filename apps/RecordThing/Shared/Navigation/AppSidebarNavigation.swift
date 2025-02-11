/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's navigation with a configuration that offers a sidebar, content list, and detail pane.
*/

import SwiftUI
import Blackbird

struct AppSidebarNavigation: View {

    enum NavigationItem {
        case things
        case productType
        case documentType
        case recent
        case favorites
        case recipes
    }

    @EnvironmentObject private var model: Model
    @State private var presentingRewards: Bool = false
    @State private var selection: NavigationItem? = .productType
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(tag: NavigationItem.things, selection: $selection) {
                    ThingsMenu()
                } label: {
                    Label("Things", systemImage: "list.bullet")
                }
                
                NavigationLink(tag: NavigationItem.productType, selection: $selection) {
                    ProductTypeMenu()
                } label: {
                    Label("Products", systemImage: "list.bullet")
                }
                
                NavigationLink(tag: NavigationItem.documentType, selection: $selection) {
                    DocumentTypeList()
                } label: {
                    Label("Documents", systemImage: "doc")
                }
                
                NavigationLink(tag: NavigationItem.recent, selection: $selection) {
                    RequestsMenu()
                } label: {
                    Label("Recent", systemImage: "clock")
                }
                
                NavigationLink(tag: NavigationItem.favorites, selection: $selection) {
                    RequestsMenu()
                } label: {
                    Label("Requests", systemImage: "flag")
                }
            
                NavigationLink(tag: NavigationItem.favorites, selection: $selection) {
                    RequestsMenu()
                } label: {
                    Label("Favorites", systemImage: "heart")
                }

                NavigationLink(tag: NavigationItem.recipes, selection: $selection) {
                    RequestsMenu()
                } label: {
                    Label("ML Models", systemImage: "book.closed")
                }

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
//                    ProductFavoriteButton()
//                        .environmentObject(model)
//                        .disabled(true)
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
        @Previewable @StateObject var database = try! Blackbird.Database(path: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite")
        @Previewable @StateObject var model = Model()

        AppSidebarNavigation()
            .environment(\.blackbirdDatabase, database)
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
