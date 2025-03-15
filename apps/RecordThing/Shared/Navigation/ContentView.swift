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
    @StateObject public var captureService: CaptureService
    @StateObject public var cameraViewModel = CameraViewModel()

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
    
    init(captureService: CaptureService = CaptureService()) {
        _captureService = StateObject(wrappedValue: captureService)
    }
    
    var sampleNavBars: some View {
        GeometryReader { geometry in
            ZStack {
                // Controls positioned at the bottom
                VStack(alignment: .center, spacing: 0) {
                    Spacer() // Push everything to the bottom
                    RecordedStackAndRequirementsView(
                        checkboxItems: model.checkboxItems,
                        cardImages: [
                            .system("photo"),
                            .system("camera"),
                            .system("doc")
                        ],
                        direction: .horizontal,
                        checkboxTextColor: Color.white,
                        checkboxColor: Color.white,
                        onItemToggled: { item in
                            model.toggleCheckboxItem(item)
                            print("Item toggled: \(item.text), isChecked: \(item.isChecked)")
                        },
                        onCardStackTapped: {
                            print("Card stack tapped")
                        }
                    )
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 32))
                    
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
                    .frame(height: 100) // FIXME not sure why it expands to fille space otherwise
                    
                    SimpleConfirmDenyStatement(
                        objectName: "Electric Mountain Bike",
                        onConfirm: { print("Confirmed electric mountain bike") },
                        onDeny: { print("Denied electric mountain bike") }
                    )
                    .padding(EdgeInsets(top: 0, leading: 12, bottom: 32, trailing: 12))
//                    .background(Color.purple.opacity(0.2)) // Debug color
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
//                .background(Color.green.opacity(0.1)) // Debug color for bottom controls container
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
//            .background(Color.red.opacity(0.1)) // Debug color for entire container
            .onAppear {
                print("sampleNavBars size: \(geometry.size)")
            }
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
                CameraDrivenView(captureService: captureService)  {
                    switch selectedTab {
                    case .record: sampleNavBars
                    case .assets: assetsBrowsingView
                    case .actions: sampleNavBars
                    default: browseTab
                    }
                }
                    .onAppear() {
                        cameraViewModel.onAppear()
                    }
                    .environmentObject(model)
                    .environment(\.cameraViewModel, cameraViewModel)
    //                .accentColor(UIColor(named: "AccentColor").cgColor())

            }
        }
    }
}

import AVFoundation

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Regular view preview
            ContentView(captureService: MockedCaptureService(.authorized))
                .environmentObject(Model(loadedLangConst: "en"))
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .previewDisplayName("Loaded & Authorized")
            
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

/*
struct ContentView_Previews: PreviewProvider {
    // Create a MockedCaptureService class that extends CaptureService
    class MockedCaptureService: CaptureService {
        var status: AVAuthorizationStatus
        
        init(status: AVAuthorizationStatus) {
            self.status = status
            super.init()
            // Set permissionGranted based on status
            self.permissionGranted = (status == .authorized)
        }
        
        override func checkPermission() -> AVAuthorizationStatus {
            return status
        }
        
        // Override any other methods that depend on authorization status
        override func startSessionIfAuthorized(completion: @escaping (Error?) -> ()) {
            if status == .authorized {
                permissionGranted = true
                completion(nil)
            } else {
                permissionGranted = false
                completion(CaptureError.notAuthorized(comment: "Not authorized in preview"))
            }
        }
    }
    
    // Create a custom ContentView initializer for previews
    struct PreviewContentView: View {
        @StateObject var captureService: CaptureService
        @StateObject var cameraViewModel: CameraViewModel
        
        init(captureStatus: AVAuthorizationStatus) {
            // Create the mocked capture service with the specified status
            let mockedService = MockedCaptureService(status: captureStatus)
            // Create a camera view model with the same status
            let viewModel = CameraViewModel(captureStatus)
            
            // Initialize the StateObjects
            _captureService = StateObject(wrappedValue: mockedService)
            _cameraViewModel = StateObject(wrappedValue: viewModel)
        }
        
        var body: some View {
            ContentView(captureService: captureService, cameraViewModel: cameraViewModel)
        }
    }
    
    static var previews: some View {
        Group {
            // Authorized preview
            PreviewContentView(captureStatus: .authorized)
                .environmentObject(Model(loadedLangConst: "en"))
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .previewDisplayName("Camera Authorized")
            
            // Not determined preview
            PreviewContentView(captureStatus: .notDetermined)
                .environmentObject(Model(loadedLangConst: "en"))
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .previewDisplayName("Camera Permission Not Determined")
            
            // Denied preview
            PreviewContentView(captureStatus: .denied)
                .environmentObject(Model(loadedLangConst: "en"))
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .previewDisplayName("Camera Permission Denied")
        }
    }
}
*/
