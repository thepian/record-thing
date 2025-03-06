/*
See LICENSE folder for this sample's licensing information.

Abstract:
The primary entry point for the app's user interface. Can change between tab-based and sidebar-based navigation.
*/

import SwiftUI
import SwiftUIIntrospect
import Blackbird
import RecordLib

struct ContentView: View {
    @EnvironmentObject private var model: Model

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @State private var path = NavigationPath()
    @State private var selectedTab: BrowseNavigationTab = .record
    
    // Sample asset groups for demonstration
    private let sampleAssetGroups: [AssetGroup] = [
        AssetGroup(
            monthYear: "March 2025",
            month: 3,
            year: 2025,
            assets: [
                Asset(
                    id: "1",
                    name: "Rolex Daytona",
                    category: .watches,
                    createdAt: Date(),
                    tags: ["luxury", "watch", "gold"]
                ),
                Asset(
                    id: "2",
                    name: "LV Neverfull",
                    category: .bags,
                    createdAt: Date(),
                    tags: ["luxury", "bag", "leather"]
                ),
                Asset(
                    id: "3",
                    name: "Louboutin Pumps",
                    category: .shoes,
                    createdAt: Date(),
                    tags: ["luxury", "shoes", "red"]
                )
            ]
        ),
        AssetGroup(
            monthYear: "February 2025",
            month: 2,
            year: 2025,
            assets: [
                Asset(
                    id: "4",
                    name: "Gucci Sunglasses",
                    category: .accessories,
                    createdAt: Date().addingTimeInterval(-2592000), // 30 days ago
                    tags: ["luxury", "sunglasses", "summer"]
                ),
                Asset(
                    id: "5",
                    name: "Hermès Wallet",
                    category: .accessories,
                    createdAt: Date().addingTimeInterval(-2592000), // 30 days ago
                    tags: ["luxury", "wallet", "leather"]
                ),
                Asset(
                    id: "6",
                    name: "Cartier Love",
                    category: .jewelry,
                    createdAt: Date().addingTimeInterval(-2592000), // 30 days ago
                    tags: ["luxury", "bracelet", "gold"]
                )
            ]
        )
    ]
    
    var sampleNavBars: some View {
        VStack {
            // The floating toolbar
            StandardFloatingToolbar(
                useFullRounding: false,
                onDataBrowseTapped: {
                    selectedTab = .things
                    path.append(DataBrowsingNav(title: "Title", path: ""))
                },
                onStackTapped: {
                    selectedTab = .assets
                    path.append(FeedNav(path: "1")) },
                onCameraTapped: { print("Camera tapped") },
                onAccountTapped: {
                    selectedTab = .actions
                    path.append(AccountNav(path: "A")) }
            )
            .padding()
            
            SimpleConfirmDenyStatement(
                objectName: "Electric Mountain Bike",
                onConfirm: { print("Confirmed electric mountain bike") },
                onDeny: { print("Denied electric mountain bike") }
            )
            .padding()
        }
    }
    
    var mountainBike: some View {
        // Background content (would be the camera in the real app)
        GeometryReader { geometry in
            Image("thepia_a_high-end_electric_mountain_bike_1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped() // This prevents the image from overflowing
        }
        .ignoresSafeArea()
    }
    
    var browseTab: some View {
        // TODO pass the path to keep it persisted
        BrowseNavigationView(
            selectedTab: $selectedTab,
            navigationPath: $path,
            useSlideTransition: true,
            onRecordTapped: {
                selectedTab = .record
            },
            thingsContent: {
                ThingsMenu()
            },
            typesContent: {
                EvidenceTypeMenu()
//                TypesView()
            },
            feedContent: {
//                FeedView()
            },
            favoritesContent: {
//                FavoritesView()
            }
        )
        
        /*
#if os(iOS)
        NavigationStack(path: $path) {
            sampleNavBars
            //                .navigationDestination(item: DataBrowsingNav(title: "Things", path: "things"), destination: {
            //                    Text("Thigs table")
            //                }),
            .navigationDestination(for: DataBrowsingNav.self, destination: { nav in
                if nav.path == "" {
                    NavigationSplitView {
                        NavigationLink(value: DataBrowsingNav(title: "Things", path: "things"), label: {
                            Label(LocalizedStringKey(stringLiteral: "nav.things"), systemImage: "list.bullet")
                        })
                        NavigationLink(value: DataBrowsingNav(title: "Evidence", path: "evidence"), label: {
                            Label("Types", systemImage: "list.bullet")
                        })

                    } detail: {
                        
                    }
                }
            })
            .navigationDestination(for: FeedNav.self, destination: {
                nav in
            })
            .navigationDestination(for: AccountNav.self, destination: { nav in
                
            })
        }
        // This clears the stack background as it isn't otherwise supported
        .introspect(.navigationStack, on: .iOS(.v16, .v17, .v18)) {
            $0.viewControllers.forEach { controller in
                controller.view.backgroundColor = .clear
            }
        }
#else
        AppSidebarNavigation()
#endif
         */
    }
    
    // Assets browsing view
    var assetsBrowsingView: some View {
        AssetsBrowsingView(
            assetGroups: sampleAssetGroups,
            onAssetSelected: { asset in
                print("Selected asset: \(asset.name)")
            },
            onRecordTapped: {
                selectedTab = .record
            }
        )
    }
        
    var body: some View {
        ZStack {
            mountainBike
            if model.loadedLang == nil {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.yellow))
                    .frame(width: 50, height: 50, alignment: .center)
                    .scaleEffect(3)
            } else {
                switch selectedTab {
                case .record: sampleNavBars
                case .assets: assetsBrowsingView
                case .actions: sampleNavBars
                default: browseTab
                }
            }
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
