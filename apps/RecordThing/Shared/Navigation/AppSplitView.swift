import SwiftUI
import RecordLib
import SwiftUIIntrospect

struct EvidenceListItem: View {
    let evidence: EvidencePiece
    
    var body: some View {
        HStack {
//                evidence.type.icon
//                    .foregroundColor(.accentColor)
            
            VStack(alignment: .leading) {
                Text(evidence.title)
                    .font(.headline)
                Text(evidence.metadata["type"] ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AppSplitView<DetailContent : View>: View {
    @State private var preferredColumn = NavigationSplitViewColumn.detail
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var path: NavigationPath
    @Binding var lifecycleView: LifecycleView
    @ObservedObject var evidenceViewModel: EvidenceViewModel
    @ObservedObject var captureService: CaptureService
    @ObservedObject var cameraViewModel: CameraViewModel
    @Environment(\.assetsViewModel) var assetsViewModel
    let designSystem: DesignSystemSetup
    let detailContent: DetailContent
    
    init(
        columnVisibility: Binding<NavigationSplitViewVisibility>,
        lifecycleView: Binding<LifecycleView>,
        path: Binding<NavigationPath>,
        evidenceViewModel: EvidenceViewModel,
        cameraViewModel: CameraViewModel,
        captureService: CaptureService,
        designSystem: DesignSystemSetup,
        @ViewBuilder detailContent: () -> DetailContent
    ) {
        self._columnVisibility = columnVisibility
        self._path = path
        self._lifecycleView = lifecycleView
        self.evidenceViewModel = evidenceViewModel
        self.cameraViewModel = cameraViewModel
        self.captureService = captureService
        self.designSystem = designSystem
        self.detailContent = detailContent()
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility, preferredCompactColumn: $preferredColumn) {
            // Sidebar
            ZStack {
                // Gradient background
                //                LinearGradient(
                //                    gradient: Gradient(colors: [
                //                        Color.white.opacity(0.7),
                //                        Color.white.opacity(0.4)
                //                    ]),
                //                    startPoint: .topLeading,
                //                    endPoint: .bottomTrailing
                //                )
                //                .overlay(
                //                    // Subtle texture
                //                    Image(systemName: "circle.grid.3x3.fill")
                //                        .foregroundColor(.white.opacity(0.1))
                //                        .scaleEffect(2)
                //                )
                
                // Blur effect
                //                VisualEffectView()
                List {
                    
                    // This updates content
                    NavigationLink {
                        if let assetsViewModel = assetsViewModel {
                            ThingsGridView(viewModel: assetsViewModel, evidenceViewModel: evidenceViewModel, columns: 2) { thing in
                                print("Selected thing: \(thing.title ?? "Untitled")")
                            }
                        } else {
                            Text("Missing Assets")
                        }
                    } label: {
                        Label("Assets", systemImage: "square.3.layers.3d")
                    }

                    NavigationLink {
                        Text("iuoptyuptyoiu")
                    } label: {
                        Label("Actions", systemImage: "signature")
                    }

                    NavigationLink {
                        Text("sdfsdfsafd (detail)")
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    NavigationLink {
                        ThingsMenu()
                    } label: {
                        Label("Things", systemImage: "square.3.layers.3d")
                    }
                    
                    NavigationLink {
                        EvidenceTypeMenu()
                    } label: {
                        Label("Evidence Type", systemImage: "square.3.layers.3d")
                    }



//                    Section("Recent Evidence") {
//                        ForEach(evidenceViewModel.pieces) { evidence in
//                            EvidenceListItem(evidence: evidence)
//                        }
//                    }
                    
                    Section("Actions") {
                        Button(action: {
                            evidenceViewModel.reviewing.toggle()
                        }) {
                            Label("Review Evidence", systemImage: "photo.stack")
                        }
                    }
                    
                    Section("Develop") {
                        CameraSwitcher(captureService: captureService, designSystem: designSystem)
                        
                        CameraSubduedSwitcher(captureService: captureService, designSystem: designSystem)
                        
                        CaptureServiceInfo(captureService: captureService)
                    }
                }
                .listStyle(.sidebar)
            }
            .navigationTitle("Record Thing")
            .toolbar {
                ToolbarItem {
                    NavigationLink {
                        detailContent.onAppear {
                            lifecycleView = .record
                        }
                    } label: {
                        Label("Record", systemImage: "camera")
                    }
                }
#if os(macOS)
                ToolbarItem {
                    DeveloperToolbar(
                        captureService: captureService,
                        cameraViewModel: cameraViewModel,
                        isCompact: true
                    )
                }
#else
                ToolbarItem(placement: .navigationBarTrailing) {
                    DeveloperToolbar(
                        captureService: captureService,
                        cameraViewModel: cameraViewModel,
                        isCompact: true
                    )
                }
#endif
            }
//        } content: {
//            // blank content
//            Button("Detail Only") {
//                columnVisibility = .detailOnly
//            }
//            Button("Double Column") {
//                columnVisibility = .doubleColumn
//            }
//            NavigationLink {
//                Text("sdfsdfsafd (detail)")
//            } label: {
//                Label("123 (D)", systemImage: "gear")
//            }
//
        }
        detail: {
            NavigationStack {
                VStack {
//                    NavigationLink {
//                        Text("sdfsdfsafd (detail)")
//                    } label: {
//                        Label("123 (D)", systemImage: "gear")
//                    }
                    detailContent
                }
                .navigationDestination(for: NavigationDestination.self) { dest in
                    AppSplitDetailView(destination: dest)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        #if os(macOS)
        .toolbar(.visible, for: .windowToolbar)
        #else
        .toolbar(.visible, for: .navigationBar, .tabBar)
        #endif
        #if os(iOS)
        // https://github.com/davdroman/NavigationSplitViewRemoveBackgrounds/blob/main/NavigationSplitViewRemoveBackgrounds.swiftpm/MyApp.swift
        .introspect(.navigationSplitView, on: .iOS(.v16, .v17, .v18)) { split in
            let removeBackgrounds = {
                split.viewControllers.forEach { controller in
                    controller.parent?.view.backgroundColor = .clear
                    controller.view.clearBackgrounds()
                }
            }
            /* We need to restrain the bits being made transparent
             
            removeBackgrounds() // run now...
            DispatchQueue.main.async(execute: removeBackgrounds) // ... and on the next run loop pass
             */
        }
        #endif
    }
}

struct AppSplitDetailView: View {
    let destination: NavigationDestination
    
    var body: some View {
        Group {
            switch destination {
            case .record(let evidenceId):
                EmptyView()
            case .assets:
                ZStack {
                    Text("Assets")
                }
            case .assetsGroup(groupId: let groupId):
                EmptyView()
            case .assetsDetail(assetId: let assetId):
                EmptyView()
            case .assetsThingDetail(thingId: let thingId):
                EmptyView()
            case .assetsEvidenceList(thingId: let thingId):
                EmptyView()
            case .assetsThingDetail(thingId: let thingId):
                EmptyView()
            case .assetsEvidenceDetail(thingId: let thingId, evidenceId: let evidenceId):
                EmptyView()

            // Actions Tab Paths
            case .actions:
                ZStack {
                    Text("Actions")
                }
            case .actionsAccount:
                EmptyView()
            case .actionsSettings:
                EmptyView()
            case .actionsHelp:
                EmptyView()
            }

            /*
            switch destination {
            case .thingDetail(let id):
                if let thing = sampleThings.first(where: { $0.id == id }) {
                    ThingDetailView(thing: thing)
                }
            case .categoryDetail(let id):
                CategoryDetailView(categoryId: id)
            case .productTypeDetail(let id):
                if let productType = sampleTypes.first(where: { $0.id == id }) {
                    ProductTypeDetailView(productType: productType)
                }
            case .feedItem(let id):
                VStack {
                    Text("Feed Item \(id)")
                        .font(.title)
                }
            case .favoriteItem(let id):
                VStack {
                    Text("Favorite Item \(id)")
                        .font(.title)
                }
            default:
                VStack {
                    Text("Tab: \(destination.tab.title)")
                        .font(.headline)
                    Text("Destination: \(destination.id)")
                        .font(.subheadline)
                }
            }
            */
        }
    }
}


#if os(iOS)
extension UIView {
    fileprivate func clearBackgrounds() {
        backgroundColor = .clear
        for subview in subviews {
            subview.clearBackgrounds()
        }
    }
}
#endif


// VisualEffectView for macOS
#if os(macOS)
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // No updates needed
    }
}
#else
struct VisualEffectView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // No updates needed
    }
}
#endif

#if DEBUG
struct AppSplitView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var assetsViewModel = AssetsViewModel()
        AppSplitView(
            columnVisibility: .constant(.detailOnly),
            lifecycleView: .constant(.record),
            path: .constant(NavigationPath()),
            evidenceViewModel: .createDefault(),
            cameraViewModel: CameraViewModel(),
            captureService: CaptureService(),
            designSystem: .light
        ) {
            Text("Detail Content")
        }
        .environment(\.assetsViewModel, assetsViewModel)
        .previewDisplayName("Detail Only")
    }
}
#endif 
