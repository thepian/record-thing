/*
See LICENSE folder for this sample's licensing information.

Abstract:
The primary entry point for the app's user interface. Can change between tab-based and sidebar-based navigation.
*/

import SwiftUI
import SwiftUIIntrospect
import Blackbird
import RecordLib

struct AppTabsView: View {
    @EnvironmentObject private var model: Model

    private func switchTab(_ tab: LifecycleView) {
        model.lifecycleView = tab
        // Clear or preserve path based on tab
        // path.removeLast(path.count)
    }

    var body: some View {
        // The floating toolbar
        StandardFloatingToolbar(
            useFullRounding: false,
            onDataBrowseTapped: {
                switchTab(.development)
            },
            onStackTapped: {
                switchTab(.assets)
            },
            onCameraTapped: {
                switchTab(.record)
            },
            onAccountTapped: {
                switchTab(.actions)
            }
        )
        .frame(height: 100)
//        #if DEBUG
//        .background(Color.red.opacity(0.3))
//        #endif
    }
}

struct ContentView: View {
    @EnvironmentObject private var model: Model
    @StateObject public var captureService: CaptureService
    @StateObject public var cameraViewModel = CameraViewModel()
    @StateObject private var recordedThingViewModel: RecordedThingViewModel = MockedRecordedThingViewModel.createDefault()

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @State private var path = NavigationPath()
    
    // MARK: - Initialization
    
    init(captureService: CaptureService = CaptureService()) {
        _captureService = StateObject(wrappedValue: captureService)
    }
    
    // MARK: - Navigation Handlers
    
    private func switchTab(_ tab: LifecycleView) {
        model.lifecycleView = tab
        // Clear or preserve path based on tab
        // path.removeLast(path.count)
    }
    
    // MARK: - View Components
    
    var recordView2: some View {
//        NavigationStack(path: $path) {
            ZStack {
                VStack(alignment: .center, spacing: 0) {
                    Spacer() // Push everything to the bottom
                    AppTabsView()
                }
                #if DEBUG
                .background(Color.blue.opacity(0.1))
                #endif
            }
//            .background(Color.yellow.opacity(0.1))
//            #if os(iOS)
//            .introspect(.navigationStack, on: .iOS(.v16, .v17, .v18)) {
//                $0.viewControllers.forEach { controller in
//                    controller.view.backgroundColor = .clear
//                }
//            }
//            #else
//            .introspect(.navigationStack, on: .macOS(.v13, .v14)) {
//                $0.view.window?.backgroundColor = .clear
//            }
//            #endif
//        }
    }
    
    var recordView: some View {
        NavigationStack(path: $path) {
            CameraDrivenView(captureService: captureService) {
                ZStack {
                    VStack(alignment: .center, spacing: 0) {
                        Spacer() // Push everything to the bottom
                        RecordedStackAndRequirementsView(viewModel: recordedThingViewModel)
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 32))
                        
                        AppTabsView()
                        
                        ClarifyEvidenceControl(viewModel: recordedThingViewModel)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .onAppear() {
                cameraViewModel.onAppear()
            }
            .onDisappear() {
                cameraViewModel.onDisappear()
            }
            .environment(\.cameraViewModel, cameraViewModel)
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
    
    var developerTab: some View {
        // TODO pass the path to keep it persisted
        BrowseNavigationView(
            navigationPath: $path,
            useSlideTransition: true,
            onRecordTapped: {
                model.lifecycleView = .record
                path.removeLast(path.count)
                // path.append(NavigationDestination.record)
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
            assetGroups: model.assetGroups,
            onAssetSelected: { asset in
                model.selectedAsset = asset
                print("Selected asset: \(asset.name)")
            },
            onRecordTapped: {
                switchTab(.record)
            }
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            switch model.lifecycleView {

            case .development:
                developerTab

            case .record:
                recordView

            case .assets:
                assetsBrowsingView

            case .actions:
                EmptyView()
                
            case .loading:
                mountainBike
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.yellow))
                    .frame(width: 50, height: 50, alignment: .center)
                    .scaleEffect(3)
            }
        }
    }
}


import AVFoundation

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Regular view preview with video stream
            if let (_, mockService) = VideoPreviewHelper.createVideoPreview() {
                ContentView(captureService: mockService)
                    .environmentObject(Model(loadedLangConst: "en"))
                    .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                    .previewDisplayName("Loaded & Authorized (Video Stream)")
            }
            
            // Regular view preview with camera (working on macOS)
            ContentView(captureService: CaptureService()) // MockedCaptureService(.authorized))
                .environmentObject(Model(loadedLangConst: "en"))
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .previewDisplayName("Loaded & Authorized (Camera)")
            
            // Permission not determined
            ContentView(captureService: MockedCaptureService(.notDetermined))
                .environmentObject(Model(loadedLangConst: "en"))
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .previewDisplayName("Not Determined")

            // Redacted view preview
            ContentView(captureService: MockedCaptureService(.notDetermined))
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

