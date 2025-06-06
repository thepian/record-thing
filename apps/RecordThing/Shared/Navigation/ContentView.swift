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
    @StateObject public var cameraViewModel: CameraViewModel
    @StateObject private var evidenceViewModel: EvidenceViewModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    var designSystem: DesignSystemSetup
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.assetsViewModel) private var assetsViewModel

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @State private var path = NavigationPath()
    
    // MARK: - Initialization
    
    init(captureService: CaptureService, designSystem: DesignSystemSetup = .light) {
        self.designSystem = designSystem

        _captureService = StateObject(wrappedValue: captureService)
        _cameraViewModel = StateObject(wrappedValue: CameraViewModel(designSystem: designSystem))
        
        // TODO pass the designSystem when using EvidenceViewModel()
        _evidenceViewModel = StateObject(wrappedValue: EvidenceViewModel.createDefault())
    }
    
    // MARK: - App Lifecycle
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active, ensure camera is running
            cameraViewModel.onAppear()
        case .inactive:
            // App is about to become inactive, prepare for background
            cameraViewModel.onDisappear()
        case .background:
            // App is in background, stop all capture
            cameraViewModel.onBackground()
        @unknown default:
            break
        }
    }
    
    // MARK: - Navigation Handlers
    
    private func switchTab(_ tab: LifecycleView) {
        model.lifecycleView = tab
        // Clear or preserve path based on tab
        // path.removeLast(path.count)
    }
    
    // MARK: - View Components
        
    var recordView: some View {
        CameraDrivenView(captureService: captureService) {
            ZStack {
                VStack(alignment: .center, spacing: 0) {
                    Spacer() // Push everything to the bottom
                    EvidenceReview(viewModel: evidenceViewModel)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 32))
                        .offset(x: 16)
                    
                    FloatingToolbar(
                        backgroundColor: .black,
                        opacity: 0.3,
                        cornerRadius: designSystem.cornerRadius,
                        useFullRounding: false
                    ) {
                        HStack(spacing: designSystem.standardSpacing) {
                            StackButton(action: {
                                model.lifecycleView = .assets
                            })
                            CameraButton {
                                print("Camera Tapped")
                            }
                            AccountButton(action: {
                                model.lifecycleView = .actions
                            })
                            // Left side - Stack NavigationLink
                            /*
                            NavigationLink {
                                assetsBrowsingView
                            } label: {
                                StackButton(action: {})
                            }
                            
                            // Center - Camera button
                            CameraButton {
                                print("Camera Tapped")
                            }
                            
                            // Right side - Account NavigationLink
                            NavigationLink {
                                accountView
                            } label: {
                                AccountButton(action: {})
                            }
                             */
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(height: 100)

                    ClarifyEvidenceControl(viewModel: evidenceViewModel)
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
    
    var withSidebarView: some View {
        AppSplitView(
            columnVisibility: $columnVisibility,
            lifecycleView: $model.lifecycleView,
            path: $path,
            evidenceViewModel: evidenceViewModel,
            cameraViewModel: cameraViewModel,
            captureService: captureService,
            designSystem: designSystem
        ) {
            ZStack {
                switch model.lifecycleView {
                case .development:
                    EmptyView()

                case .record:
                    NavigationStack(path: $path) {
                        recordView
                    }

                case .assets:
                    assetsBrowsingView

                case .actions:
                    accountView
                    
                case .loading:
                    mountainBike
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.yellow))
                        .frame(width: 50, height: 50, alignment: .center)
                        .scaleEffect(3)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Supporting Views
    
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
    

    // Assets browsing view
    var assetsBrowsingView: some View {
        Group {
            if let assetsViewModel = assetsViewModel {
                ThingsGridView(viewModel: assetsViewModel, evidenceViewModel: evidenceViewModel, columns: 2) { thing in
                    print("Selected thing: \(thing.title ?? "Untitled")")
                }
            } else {
                Text("Missing Assets")
            }
        }
        .toolbar {
            #if os(macOS)
            ToolbarItem {
                RecordButtonToolbarItem(
                    showToolbar: true,
                    onRecordTapped: {
                        model.lifecycleView = .record
                    }
                )
            }
            #else
            ToolbarItem(placement: .navigationBarTrailing) {
                RecordButtonToolbarItem(
                    showToolbar: true,
                    onRecordTapped: {
                        model.lifecycleView = .record
                    }
                )
            }
            #endif
        }
    }
    
    var accountView: some View {
        EmptyView()
    }

    var withoutSidebarView: some View {
        ZStack {
            switch model.lifecycleView {
            case .development:
                EmptyView()

            case .record:
            NavigationStack(path: $path) {
                recordView
            }

            case .assets:
                assetsBrowsingView

            case .actions:
                accountView
                
            case .loading:
                mountainBike
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.yellow))
                    .frame(width: 50, height: 50, alignment: .center)
                    .scaleEffect(3)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        #if os(iOS)
            if horizontalSizeClass == .compact {
                withoutSidebarView
            } else {
                withSidebarView
            }
        #else
            withSidebarView
        #endif
    }
}


import AVFoundation

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        @Previewable @StateObject var assetsViewModel = AssetsViewModel(db: AppDatasource.shared.db)
        
        Group {
            // Regular view preview with video stream
            if let (_, mockService) = VideoPreviewHelper.createVideoPreview() {
                ContentView(captureService: mockService)
                    .environmentObject(Model(loadedLangConst: "en"))
                    .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                    .environment(\.assetsViewModel, assetsViewModel)
                    .previewDisplayName("Loaded & Authorized (Video Stream)")
            }
            
            // Regular view preview with camera (working on macOS)
            ContentView(captureService: CaptureService()) // MockedCaptureService(.authorized))
                .environmentObject(Model(loadedLangConst: "en"))
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .environment(\.assetsViewModel, assetsViewModel)
                .previewDisplayName("Loaded & Authorized (Camera)")
            
            // Permission not determined
            ContentView(captureService: MockedCaptureService(.notDetermined))
                .environmentObject(Model(loadedLangConst: "en"))
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .environment(\.assetsViewModel, assetsViewModel)
                .previewDisplayName("Not Determined")

            // Redacted view preview
            ContentView(captureService: MockedCaptureService(.notDetermined))
                .environmentObject(Model(loadedLangConst: "en"))
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .environment(\.assetsViewModel, assetsViewModel)
                .redacted(reason: .placeholder)
                .previewDisplayName("Redacted")

            // Loading view preview
            ContentView(captureService: MockedCaptureService(.notDetermined))
                .environmentObject(Model())
                .environment(\.blackbirdDatabase, AppDatasource.shared.db)
                .environment(\.assetsViewModel, assetsViewModel)
                .onAppear {
                    AppDatasource.shared.forceLocalizeReload()
                }
                .previewDisplayName("Loading")
        }
    }
}

