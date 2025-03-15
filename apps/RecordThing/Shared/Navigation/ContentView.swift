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
    @StateObject private var recordedThingViewModel: RecordedThingViewModel

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @State private var path = NavigationPath()
    @State private var selectedTab: BrowseNavigationTab = .record
        
    init(captureService: CaptureService = CaptureService()) {
        _captureService = StateObject(wrappedValue: captureService)
        // Initialize the RecordedThingViewModel with the model's checkbox items and card images
        _recordedThingViewModel = StateObject(wrappedValue: RecordedThingViewModel(
            checkboxItems: [
                CheckboxItem(text: "Take product photo"),
                CheckboxItem(text: "Scan barcode", isChecked: true),
                CheckboxItem(text: "Capture Sales Receipt")
            ],
            cardImages: [
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.main)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.main)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.main)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.main)),
                .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.main))
//                .system("photo"),
//                .system("camera"),
//                .system("doc")
            ],
            direction: .horizontal,
            maxCheckboxItems: 1,
            designSystem: .cameraOverlay,
            evidenceOptions: [
                "Electric Mountain Bike",
                "Mountain Bike",
                "E-Bike"
            ],
            onCardStackTapped: {
                print("Card stack tapped")
            }
        ))
    }
    
    var sampleNavBars: some View {
        GeometryReader { geometry in
            ZStack {
                // Controls positioned at the bottom
                VStack(alignment: .center, spacing: 0) {
                    Spacer() // Push everything to the bottom
                    RecordedStackAndRequirementsView(viewModel: recordedThingViewModel)
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
                    
                    ClarifyEvidenceControl(
                        viewModel: recordedThingViewModel,
                        onOptionConfirmed: { option in
                            recordedThingViewModel.evidenceTitle = option
                        }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
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
            assetGroups: model.assetGroups,
            onAssetSelected: { asset in
                model.selectedAsset = asset
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
                        model.isCameraActive = true
                        cameraViewModel.onAppear()
                    }
                    .onDisappear() {
                        model.isCameraActive = false
//                        cameraViewModel.onDisappear()
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
