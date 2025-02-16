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
                NavigationLink(destination: {
                    ThingsMenu()
                }, label: {
                    Label(LocalizedStringKey(stringLiteral: "nav.things"), systemImage: "list.bullet")
                })
                NavigationLink(destination: {
                    EvidenceTypeMenu()
                }, label: {
                    Label("Types", systemImage: "list.bullet")
                })
//                NavigationLink(destination: { DocumentTypeList()
//                }, label: { Label("Documents", systemImage: "doc") })
                NavigationLink(destination: {
                    RequestsMenu()
                }, label: {
                    Label(LocalizedStringKey(stringLiteral: "nav.recent"), systemImage: "clock")
                })
                NavigationLink(destination: {
                    RequestsMenu()
                }, label: {
                    Label(LocalizedStringKey(stringLiteral: "nav.requests"), systemImage: "flag")
                })
                NavigationLink(destination: {
                    RequestsMenu()
                }, label: {
                    Label(LocalizedStringKey(stringLiteral: "nav.favorites"), systemImage: "heart")
                })
                NavigationLink(destination: {
                    RequestsMenu()
                }, label: {
                    Label("ML Models", systemImage: "book.closed")
                })

            }
            .navigationTitle(LocalizedStringKey(stringLiteral: "nav.appname"))
            #if EXTENDED_ALL
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Pocket()
            }
            #endif
            
            Text("ui.select.category".localized)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background()
                .ignoresSafeArea()
            
            Text("ui.select.product".localized)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background()
                .ignoresSafeArea()
                .toolbar {
//                    ProductFavoriteButton()
//                        .environmentObject(model)
//                        .disabled(true)
                    
//                    Button(action: {
//                        model.refresh()
//                    }) {
//                        Text("refresh")
//                    }
                }
        }
    }
    
    struct Pocket: View {
        @State private var presentingRewards: Bool = false
        @EnvironmentObject private var model: Model
        
        var body: some View {
            Button(action: { presentingRewards = true }) {
                Label("nav.rewards".localized, systemImage: "seal")
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
        @Previewable @StateObject var datasource = AppDatasource.shared
        @Previewable @StateObject var model = Model(loadedLangConst: "en")

        AppSidebarNavigation()
            .environment(\.blackbirdDatabase, datasource.db)
            .environmentObject(model)
    }
}

struct AppSidebarNavigationPocket_Previews: PreviewProvider {
    static var previews: some View {
        AppSidebarNavigation.Pocket()
            .environmentObject(Model(loadedLangConst: "en"))
            .frame(width: 300)
    }
}
